"""Academy billing service — AC-M1 그룹 C.

Spec: docs/specs/web/academy/billing_settlement_spec.md.

책임:
- AcademyBillingRule (학원 단위 정책)
- AcademySubscription (학원 귀속 수강권 정책 행)
- AcademyInvoice (월간 청구서)
- AcademyPayment (수금 1건)
- AcademySettlement (강사 배분 명세)

UX 1탭 흐름:
- POST /billing/invoices/generate → 학원장이 "이번 달 청구서 자동 생성" 1탭
- POST /billing/invoices/bulk-send → "전체 발송" 1탭
- POST /billing/payments → 수금 1탭 마킹
- POST /billing/settlements/calculate → 강사 배분 자동 산출 1탭
- POST /billing/settlements/{id}/transfer → 송금 완료 1탭

자동 산출 로직 (계산 알고리즘 상세 — billing_settlement §6.2):
- attendance: 출석 완료 레슨 시간 × hourly_rate / 학생 청구액 × share_pct / 학생 단가 합계
- 본 layer 에서는 단순화. cron 또는 학원장 트리거로 호출.
"""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy_billing import (
    AcademyBillingRule,
    AcademyInvoice,
    AcademyPayment,
    AcademySettlement,
    AcademySubscription,
    InvoiceStatus,
    SettlementStatus,
    TeacherDistributionType,
)
from app.schemas.academy_billing import (
    AcademyBillingRuleCreate,
    AcademyBillingRuleUpdate,
    AcademyInvoiceCreate,
    AcademyInvoiceUpdate,
    AcademyPaymentCreate,
    AcademySubscriptionCreate,
    BillingProgressResponse,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


class AcademyBillingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # BillingRule
    # ------------------------------------------------------------------

    async def create_or_update_rule(self, *, academy_id: str, body: AcademyBillingRuleCreate) -> AcademyBillingRule:
        """학원 단위 정책 — 학원당 1행. upsert."""
        existing = await self.db.scalar(select(AcademyBillingRule).where(AcademyBillingRule.academy_id == academy_id))
        if existing is not None:
            for field, value in body.model_dump(exclude_unset=True).items():
                setattr(existing, field, value)
            await self.db.flush()
            return existing
        rule = AcademyBillingRule(academy_id=academy_id, **body.model_dump())
        self.db.add(rule)
        await self.db.flush()
        return rule

    async def get_rule(self, academy_id: str) -> AcademyBillingRule:
        rule = await self.db.scalar(select(AcademyBillingRule).where(AcademyBillingRule.academy_id == academy_id))
        if rule is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Billing rule not configured")
        return rule

    async def update_rule(self, *, academy_id: str, body: AcademyBillingRuleUpdate) -> AcademyBillingRule:
        rule = await self.get_rule(academy_id)
        for field, value in body.model_dump(exclude_unset=True).items():
            setattr(rule, field, value)
        await self.db.flush()
        return rule

    # ------------------------------------------------------------------
    # AcademySubscription — 학원 귀속 수강권 정책 (FE 호환)
    # ------------------------------------------------------------------

    async def create_subscription_policy(
        self, *, academy_id: str, by_user_id: str, body: AcademySubscriptionCreate
    ) -> AcademySubscription:
        """기존 subscriptions 본체와 1:1. 정책은 작성 시점 스냅샷."""
        existing = await self.db.scalar(
            select(AcademySubscription.id).where(AcademySubscription.subscription_id == body.subscription_id)
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Academy subscription policy already exists for this subscription_id",
            )
        policy = AcademySubscription(
            academy_id=academy_id,
            subscription_id=body.subscription_id,
            academy_student_id=body.academy_student_id,
            teacher_member_id=body.teacher_member_id,
            ownership=body.ownership,
            cancellation_deadline_hours=body.cancellation_deadline_hours,
            student_compensation_extra_minutes_enabled=body.student_compensation_extra_minutes_enabled,
            include_extra_minutes_text_on_late_cancel=body.include_extra_minutes_text_on_late_cancel,
            student_compensation_extra_minutes_message=body.student_compensation_extra_minutes_message,
            notify_owner_on_late_cancel=body.notify_owner_on_late_cancel,
            created_at=_utcnow(),
            created_by_user_id=by_user_id,
        )
        self.db.add(policy)
        await self.db.flush()
        return policy

    async def list_subscription_policies(
        self,
        *,
        academy_id: str,
        teacher_member_id: str | None = None,
        academy_student_id: str | None = None,
    ) -> tuple[list[AcademySubscription], int]:
        stmt = select(AcademySubscription).where(AcademySubscription.academy_id == academy_id)
        if teacher_member_id is not None:
            stmt = stmt.where(AcademySubscription.teacher_member_id == teacher_member_id)
        if academy_student_id is not None:
            stmt = stmt.where(AcademySubscription.academy_student_id == academy_student_id)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademySubscription.created_at.desc()))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # Invoice
    # ------------------------------------------------------------------

    async def create_invoice(self, *, academy_id: str, body: AcademyInvoiceCreate) -> AcademyInvoice:
        total = body.base_amount + body.extra_amount - body.discount_amount
        if total < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="total_amount cannot be negative",
            )
        # 동일 학생/기간 중복 차단.
        existing = await self.db.scalar(
            select(AcademyInvoice.id)
            .where(AcademyInvoice.academy_id == academy_id)
            .where(AcademyInvoice.academy_student_id == body.academy_student_id)
            .where(AcademyInvoice.period_year == body.period_year)
            .where(AcademyInvoice.period_month == body.period_month)
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Invoice already exists for this student/period",
            )
        invoice = AcademyInvoice(
            academy_id=academy_id,
            academy_student_id=body.academy_student_id,
            period_year=body.period_year,
            period_month=body.period_month,
            base_amount=body.base_amount,
            extra_amount=body.extra_amount,
            discount_amount=body.discount_amount,
            total_amount=total,
            line_items=[item.model_dump(mode="json") for item in body.line_items],
            due_date=body.due_date,
            status=InvoiceStatus.draft,
        )
        self.db.add(invoice)
        await self.db.flush()
        return invoice

    async def get_invoice(self, invoice_id: str) -> AcademyInvoice:
        invoice = await self.db.get(AcademyInvoice, invoice_id)
        if invoice is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")
        return invoice

    async def update_invoice(self, *, invoice_id: str, body: AcademyInvoiceUpdate) -> AcademyInvoice:
        invoice = await self.get_invoice(invoice_id)
        if invoice.status != InvoiceStatus.draft:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Only draft invoices can be updated",
            )
        updates = body.model_dump(exclude_unset=True)
        if "line_items" in updates and updates["line_items"] is not None:
            updates["line_items"] = [
                item if isinstance(item, dict) else item.model_dump(mode="json") for item in updates["line_items"]
            ]
        for field, value in updates.items():
            setattr(invoice, field, value)
        invoice.total_amount = invoice.base_amount + invoice.extra_amount - invoice.discount_amount
        await self.db.flush()
        return invoice

    async def list_invoices(
        self,
        *,
        academy_id: str,
        status_filter: InvoiceStatus | None = None,
        period_year: int | None = None,
        period_month: int | None = None,
    ) -> tuple[list[AcademyInvoice], int]:
        stmt = select(AcademyInvoice).where(AcademyInvoice.academy_id == academy_id)
        if status_filter is not None:
            stmt = stmt.where(AcademyInvoice.status == status_filter)
        if period_year is not None:
            stmt = stmt.where(AcademyInvoice.period_year == period_year)
        if period_month is not None:
            stmt = stmt.where(AcademyInvoice.period_month == period_month)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyInvoice.created_at.desc()))
        return list(result.all()), total

    async def bulk_send_invoices(self, *, academy_id: str, invoice_ids: list[str]) -> int:
        """UX 1탭: 학원장이 청구서 일괄 발송 확정. draft → sent."""
        invoices = (
            await self.db.scalars(
                select(AcademyInvoice)
                .where(AcademyInvoice.academy_id == academy_id)
                .where(AcademyInvoice.id.in_(invoice_ids))
                .where(AcademyInvoice.status == InvoiceStatus.draft)
            )
        ).all()
        now = _utcnow()
        for invoice in invoices:
            invoice.status = InvoiceStatus.sent
            if invoice.issued_at is None:
                invoice.issued_at = now
            invoice.sent_at = now
        await self.db.flush()
        return len(invoices)

    # ------------------------------------------------------------------
    # Payment
    # ------------------------------------------------------------------

    async def record_payment(self, *, academy_id: str, by_user_id: str, body: AcademyPaymentCreate) -> AcademyPayment:
        """수금 1탭 마킹. 부분 수금 지원."""
        invoice = await self.get_invoice(body.invoice_id)
        if invoice.academy_id != academy_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="invoice not in this academy",
            )
        if invoice.status == InvoiceStatus.cancelled:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot record payment on cancelled invoice",
            )
        payment = AcademyPayment(
            academy_id=academy_id,
            invoice_id=body.invoice_id,
            paid_amount=body.paid_amount,
            paid_at=body.paid_at,
            method=body.method,
            confirmed_by_user_id=by_user_id,
            source=body.source,
            bank_tx_ref=body.bank_tx_ref,
            depositor_raw=body.depositor_raw,
            note=body.note,
        )
        self.db.add(payment)
        await self.db.flush()

        # invoice status 갱신 — 누적 수금이 total 이상이면 paid.
        total_paid = await self.db.scalar(
            select(func.coalesce(func.sum(AcademyPayment.paid_amount), 0)).where(
                AcademyPayment.invoice_id == body.invoice_id
            )
        )
        if int(total_paid or 0) >= invoice.total_amount:
            invoice.status = InvoiceStatus.paid
        await self.db.flush()
        return payment

    async def list_payments(
        self, *, academy_id: str, invoice_id: str | None = None
    ) -> tuple[list[AcademyPayment], int]:
        stmt = select(AcademyPayment).where(AcademyPayment.academy_id == academy_id)
        if invoice_id is not None:
            stmt = stmt.where(AcademyPayment.invoice_id == invoice_id)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyPayment.paid_at.desc()))
        return list(result.all()), total

    # ------------------------------------------------------------------
    # Settlement
    # ------------------------------------------------------------------

    async def calculate_settlements_for_period(self, *, academy_id: str, period_year: int, period_month: int) -> int:
        """학원장 1탭: 강사 배분 자동 산출 (수금 80% 시점 권장).

        간이 알고리즘: 해당 월 강사별 paid invoice 의 share_pct 적용.
        상세 산출 (시간당/학생별 단가/엣지케이스) 은 billing_settlement §6.2/§6.6.
        본 구현은 revenue_share 기본 모드 단순 계산. 향후 보강.
        """
        rule = await self.get_rule(academy_id)
        # 학생별 paid invoice + 매핑된 강사 조회.
        # (실제 algorithm: 학생→teacher_member_id 매핑 + 수강료 × share_pct)
        # 본 layer 에서는 stub — 다음 라운드에서 상세 구현.
        # 이미 계산된 settlement 가 있으면 갱신, 없으면 신규.
        from app.models.academy import AcademyStudent

        # 학원 paid invoice 들 (해당 월).
        paid_invoices = (
            await self.db.scalars(
                select(AcademyInvoice)
                .where(AcademyInvoice.academy_id == academy_id)
                .where(AcademyInvoice.period_year == period_year)
                .where(AcademyInvoice.period_month == period_month)
                .where(AcademyInvoice.status == InvoiceStatus.paid)
            )
        ).all()
        # 강사별 합산.
        teacher_totals: dict[str, dict] = {}
        for invoice in paid_invoices:
            student = await self.db.get(AcademyStudent, invoice.academy_student_id)
            if student is None or student.teacher_member_id is None:
                continue
            entry = teacher_totals.setdefault(
                student.teacher_member_id,
                {"student_revenue": 0, "breakdown": []},
            )
            entry["student_revenue"] += invoice.total_amount
            entry["breakdown"].append(
                {
                    "academy_student_id": invoice.academy_student_id,
                    "student_name": student.name,
                    "lesson_count": 0,  # 향후 attendance 연동
                    "amount": invoice.total_amount,
                }
            )
        # 강사별 배분 계산 + AcademySettlement upsert.
        default_share = float(
            rule.teacher_distribution_config.get("default_share_pct", 0.6)
            if rule.teacher_distribution_type == TeacherDistributionType.revenue_share
            else 0.0
        )
        count = 0
        for teacher_member_id, totals in teacher_totals.items():
            calculated = int(totals["student_revenue"] * default_share)
            existing = await self.db.scalar(
                select(AcademySettlement)
                .where(AcademySettlement.academy_id == academy_id)
                .where(AcademySettlement.teacher_member_id == teacher_member_id)
                .where(AcademySettlement.period_year == period_year)
                .where(AcademySettlement.period_month == period_month)
            )
            if existing is not None and existing.status != SettlementStatus.draft:
                continue  # 확정된 행은 갱신 안 함
            if existing is None:
                settlement = AcademySettlement(
                    academy_id=academy_id,
                    teacher_member_id=teacher_member_id,
                    period_year=period_year,
                    period_month=period_month,
                    calculated_amount=calculated,
                    final_amount=calculated,
                    status=SettlementStatus.draft,
                    breakdown=totals["breakdown"],
                )
                self.db.add(settlement)
            else:
                existing.calculated_amount = calculated
                existing.final_amount = calculated
                existing.breakdown = totals["breakdown"]
            count += 1
        await self.db.flush()
        return count

    async def get_settlement(self, settlement_id: str) -> AcademySettlement:
        s = await self.db.get(AcademySettlement, settlement_id)
        if s is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Settlement not found")
        return s

    async def adjust_settlement(
        self,
        *,
        settlement_id: str,
        by_user_id: str,
        final_amount: int,
        reason: str | None,
    ) -> AcademySettlement:
        """학원장이 강사 정산 금액 수정. audit trail (adjustment_log) 보존."""
        s = await self.get_settlement(settlement_id)
        if s.status == SettlementStatus.transferred:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot adjust transferred settlement",
            )
        log_entry = {
            "at": _utcnow().isoformat(),
            "by_user_id": by_user_id,
            "from_amount": s.final_amount,
            "to_amount": final_amount,
            "reason": reason or "",
        }
        s.adjustment_log = list(s.adjustment_log or []) + [log_entry]
        s.adjusted_amount = final_amount
        s.final_amount = final_amount
        await self.db.flush()
        return s

    async def confirm_settlement(self, *, settlement_id: str, by_user_id: str) -> AcademySettlement:
        """학원장 1탭 확정 → 강사 명세서 발송 (강사 lesson-app 인박스)."""
        s = await self.get_settlement(settlement_id)
        if s.status != SettlementStatus.draft:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Settlement is {s.status.value}, cannot confirm",
            )
        s.status = SettlementStatus.confirmed
        s.confirmed_at = _utcnow()
        await self.db.flush()
        return s

    async def mark_transferred(self, *, settlement_id: str, by_user_id: str, note: str | None) -> AcademySettlement:
        """학원장이 외부 송금 후 1탭 마킹."""
        s = await self.get_settlement(settlement_id)
        if s.status != SettlementStatus.confirmed:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Only confirmed settlements can be marked transferred",
            )
        s.status = SettlementStatus.transferred
        s.transferred_at = _utcnow()
        if note:
            s.note = note
        await self.db.flush()
        return s

    async def teacher_acknowledge(
        self,
        *,
        settlement_id: str,
        by_user_id: str,
        dispute_note: str | None = None,
    ) -> AcademySettlement:
        """강사가 명세서 확인 또는 이의 제기."""
        s = await self.get_settlement(settlement_id)
        s.teacher_acknowledged_at = _utcnow()
        if dispute_note:
            s.teacher_dispute_note = dispute_note
        await self.db.flush()
        return s

    async def list_settlements(
        self,
        *,
        academy_id: str,
        period_year: int | None = None,
        period_month: int | None = None,
        teacher_member_id: str | None = None,
    ) -> tuple[list[AcademySettlement], int]:
        stmt = select(AcademySettlement).where(AcademySettlement.academy_id == academy_id)
        if period_year is not None:
            stmt = stmt.where(AcademySettlement.period_year == period_year)
        if period_month is not None:
            stmt = stmt.where(AcademySettlement.period_month == period_month)
        if teacher_member_id is not None:
            stmt = stmt.where(AcademySettlement.teacher_member_id == teacher_member_id)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(
            stmt.order_by(AcademySettlement.period_year.desc(), AcademySettlement.period_month.desc())
        )
        return list(result.all()), total

    # ------------------------------------------------------------------
    # BillingProgress (대시보드 위젯)
    # ------------------------------------------------------------------

    async def get_progress(self, *, academy_id: str, period_year: int, period_month: int) -> BillingProgressResponse:
        invoices = (
            await self.db.scalars(
                select(AcademyInvoice)
                .where(AcademyInvoice.academy_id == academy_id)
                .where(AcademyInvoice.period_year == period_year)
                .where(AcademyInvoice.period_month == period_month)
            )
        ).all()
        sent = sum(1 for i in invoices if i.status != InvoiceStatus.draft)
        paid = sum(1 for i in invoices if i.status == InvoiceStatus.paid)
        overdue = sum(1 for i in invoices if i.status == InvoiceStatus.overdue)
        # settlement 진행률.
        settlements = (
            await self.db.scalars(
                select(AcademySettlement)
                .where(AcademySettlement.academy_id == academy_id)
                .where(AcademySettlement.period_year == period_year)
                .where(AcademySettlement.period_month == period_month)
            )
        ).all()
        if not settlements:
            settlement_status = "not_started"
        elif all(s.status == SettlementStatus.transferred for s in settlements):
            settlement_status = "completed"
        else:
            settlement_status = "partial"
        collected_pct = (paid / sent * 100.0) if sent > 0 else 0.0
        return BillingProgressResponse(
            period_year=period_year,
            period_month=period_month,
            invoice_total=len(invoices),
            invoice_sent=sent,
            invoice_paid=paid,
            invoice_overdue=overdue,
            payment_collected_pct=collected_pct,
            settlement_status=settlement_status,
        )


__all__ = ["AcademyBillingService"]
