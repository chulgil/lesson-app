"""Academy payment matching service — AC-M3 §4 수기 입력 + 1탭 확정.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.2, §6.3, §7.6.

책임:
- AcademyBankTransaction CRUD (학원장이 입력한 입금 원문)
- 1탭 매칭 확정 — AcademyPayment 생성 + invoice status 갱신 + tx state='matched'
- 매칭 취소 (§7.6) — AcademyPayment 삭제 + 상태 회귀

원칙 (spec §1):
- 자동 매칭 금지 — 알고리즘은 별도 후속 작업, 본 서비스는 학원장 명시적 확정만 처리
- depositor_raw / memo_raw 원문 영구 보존 (분쟁 증거)
- 매칭 확정 시 audit (matched_by_user_id, matched_at) 기록
"""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy import AcademyStudent
from app.models.academy_billing import (
    AcademyInvoice,
    AcademyPayment,
    InvoiceStatus,
    PaymentMethod,
    PaymentSource,
)
from app.models.academy_payment_matching import (
    AcademyBankTransaction,
    AcademyBankTransactionSource,
    AcademyBankTransactionState,
    AcademyPaymentMatchSuggestion,
    AcademyPaymentMatchSuggestionDecision,
)
from app.schemas.academy_payment_matching import (
    AcademyBankTransactionCreate,
    BankTransactionState,
)
from app.services.academy_payment_matching_fuzzy import (
    WEAK_SUGGESTION_THRESHOLD,
    compute_match_score,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


class AcademyPaymentMatchingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # 수기 입력 (§5.2)
    # ------------------------------------------------------------------

    async def create_manual_transaction(
        self, *, academy_id: str, body: AcademyBankTransactionCreate
    ) -> AcademyBankTransaction:
        """학원장이 통장에서 본 입금 1건을 수기 입력. state='unmatched' 로 시작."""
        tx = AcademyBankTransaction(
            academy_id=academy_id,
            source=AcademyBankTransactionSource.manual,
            source_ref=body.source_ref,
            bank_name=body.bank_name,
            tx_at=body.tx_at,
            amount=body.amount,
            depositor_raw=body.depositor_raw,
            memo_raw=body.memo_raw,
            state=AcademyBankTransactionState.unmatched,
        )
        self.db.add(tx)
        await self.db.flush()
        return tx

    async def list_transactions(
        self,
        *,
        academy_id: str,
        state: BankTransactionState | None = None,
    ) -> tuple[list[AcademyBankTransaction], int]:
        """state 필터로 미매칭/제안/매칭/무시 조회. §6.2 일괄 매칭 화면용."""
        stmt = select(AcademyBankTransaction).where(AcademyBankTransaction.academy_id == academy_id)
        if state is not None:
            stmt = stmt.where(AcademyBankTransaction.state == AcademyBankTransactionState(state.value))
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = int((await self.db.scalar(count_stmt)) or 0)
        result = await self.db.scalars(stmt.order_by(AcademyBankTransaction.tx_at.desc()))
        return list(result.all()), total

    async def get_transaction(self, tx_id: str) -> AcademyBankTransaction:
        tx = await self.db.get(AcademyBankTransaction, tx_id)
        if tx is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="bank transaction not found")
        return tx

    # ------------------------------------------------------------------
    # 1탭 매칭 확정 (§6.3)
    # ------------------------------------------------------------------

    async def confirm_match(
        self,
        *,
        academy_id: str,
        tx_id: str,
        invoice_id: str,
        paid_amount: int,
        by_user_id: str,
    ) -> tuple[AcademyBankTransaction, AcademyPayment]:
        """학원장 1탭 확정.

        처리 (§6.3):
        1. AcademyPayment 행 생성 (source=manual, bank_tx_ref=tx.id, depositor_raw 보존)
        2. AcademyInvoice.status='paid' (누적 paid >= total) 또는 'sent' 유지 (부분)
        3. AcademyBankTransaction.state='matched', matched_invoice_id, matched_by_user_id, matched_at

        에러:
        - tx 가 다른 학원 → 400
        - invoice 가 다른 학원 → 400
        - invoice 취소됨 → 409
        - tx 가 이미 matched/ignored → 409
        """
        tx = await self.get_transaction(tx_id)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state in {AcademyBankTransactionState.matched, AcademyBankTransactionState.ignored}:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"tx already {tx.state.value}",
            )

        invoice = await self.db.get(AcademyInvoice, invoice_id)
        if invoice is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="invoice not found")
        if invoice.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invoice not in this academy")
        if invoice.status == InvoiceStatus.cancelled:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot match cancelled invoice",
            )

        # 1. AcademyPayment 생성 (audit: bank_tx_ref + depositor_raw 보존).
        payment = AcademyPayment(
            academy_id=academy_id,
            invoice_id=invoice_id,
            paid_amount=paid_amount,
            paid_at=tx.tx_at,
            method=PaymentMethod.transfer,
            confirmed_by_user_id=by_user_id,
            source=PaymentSource.manual,
            bank_tx_ref=tx.id,
            depositor_raw=tx.depositor_raw,
        )
        self.db.add(payment)
        await self.db.flush()

        # 2. invoice status 갱신 — 누적 수금이 total 이상이면 paid.
        total_paid = await self.db.scalar(
            select(func.coalesce(func.sum(AcademyPayment.paid_amount), 0)).where(
                AcademyPayment.invoice_id == invoice_id
            )
        )
        if int(total_paid or 0) >= invoice.total_amount:
            invoice.status = InvoiceStatus.paid

        # 3. tx 상태 갱신 + audit.
        now = _utcnow()
        tx.state = AcademyBankTransactionState.matched
        tx.matched_invoice_id = invoice_id
        tx.matched_by_user_id = by_user_id
        tx.matched_at = now

        # 4. §3 suggestion 결정 audit — 같은 tx 의 pending 후보 처리.
        #    선택한 invoice → accepted, 나머지 → rejected (분쟁 시 추적용).
        pending_suggestions = await self.db.scalars(
            select(AcademyPaymentMatchSuggestion)
            .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx.id)
            .where(AcademyPaymentMatchSuggestion.user_decision == AcademyPaymentMatchSuggestionDecision.pending)
        )
        for sugg in pending_suggestions.all():
            sugg.user_decision = (
                AcademyPaymentMatchSuggestionDecision.accepted
                if sugg.invoice_id == invoice_id
                else AcademyPaymentMatchSuggestionDecision.rejected
            )
            sugg.decided_at = now

        await self.db.flush()
        return tx, payment

    # ------------------------------------------------------------------
    # 무시 (§6.2) / 매칭 취소 (§7.6)
    # ------------------------------------------------------------------

    async def ignore_transaction(self, *, academy_id: str, tx_id: str) -> AcademyBankTransaction:
        """학원장이 '이번 회기는 무시' → state='ignored', 다음 마감에서 자동 제외."""
        tx = await self.get_transaction(tx_id)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state == AcademyBankTransactionState.matched:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="matched tx — revert first to ignore",
            )
        tx.state = AcademyBankTransactionState.ignored
        await self.db.flush()
        return tx

    async def revert_match(self, *, academy_id: str, tx_id: str) -> AcademyBankTransaction:
        """매칭 취소 (§7.6). AcademyPayment 삭제 + tx state='unmatched' + invoice 상태 회귀.

        Note: §7.6 의 "7일 이내" 시간 제약은 추후 라운드에서 추가 (현재는 항상 허용).
        """
        tx = await self.get_transaction(tx_id)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state != AcademyBankTransactionState.matched:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="only matched tx can be reverted",
            )

        invoice_id = tx.matched_invoice_id
        # AcademyPayment 삭제 (bank_tx_ref=tx.id 인 행만).
        await self.db.execute(delete(AcademyPayment).where(AcademyPayment.bank_tx_ref == tx.id))
        await self.db.flush()

        # invoice 상태 회귀 — 잔여 수금 합산으로 재계산.
        if invoice_id is not None:
            invoice = await self.db.get(AcademyInvoice, invoice_id)
            if invoice is not None and invoice.status == InvoiceStatus.paid:
                total_paid = await self.db.scalar(
                    select(func.coalesce(func.sum(AcademyPayment.paid_amount), 0)).where(
                        AcademyPayment.invoice_id == invoice_id
                    )
                )
                if int(total_paid or 0) < invoice.total_amount:
                    # 발송 이력이 있으면 sent 로, 없으면 draft 로 회귀.
                    invoice.status = InvoiceStatus.sent if invoice.sent_at is not None else InvoiceStatus.draft

        # tx 회귀.
        tx.state = AcademyBankTransactionState.unmatched
        tx.matched_invoice_id = None
        tx.matched_by_user_id = None
        tx.matched_at = None
        await self.db.flush()
        return tx

    # ------------------------------------------------------------------
    # §3 fuzzy 매칭 알고리즘
    # ------------------------------------------------------------------

    async def suggest_matches(self, *, academy_id: str, tx_id: str) -> list[AcademyPaymentMatchSuggestion]:
        """학원장 '매칭 제안' 1탭 — 알고리즘이 후보 0~N건 제시 (§3, §6.1).

        - 학원의 unpaid invoice (draft/sent/overdue) 와 학생명 join → 각각 점수 계산
        - 점수 ≥ 0.60 인 후보만 ``AcademyPaymentMatchSuggestion`` 행 저장
        - 최고 점수 → ``tx.match_score`` + ``tx.match_features`` 저장 (top-1 시각화용)
        - 후보 1+ 있으면 ``tx.state='suggested'``, 0건이면 ``unmatched`` 유지

        재호출 시 기존 pending suggestion 은 삭제 후 재계산 (decided 는 보존 — audit).
        """
        tx = await self.get_transaction(tx_id)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state in {
            AcademyBankTransactionState.matched,
            AcademyBankTransactionState.ignored,
        }:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"cannot suggest on {tx.state.value} tx",
            )

        # 1. 기존 pending suggestion 삭제 (재계산). decided 는 audit 로 보존.
        await self.db.execute(
            delete(AcademyPaymentMatchSuggestion)
            .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx.id)
            .where(AcademyPaymentMatchSuggestion.user_decision == AcademyPaymentMatchSuggestionDecision.pending)
        )
        await self.db.flush()

        # 2. 학원의 unpaid invoice + 학생 join.
        rows = (
            await self.db.execute(
                select(AcademyInvoice, AcademyStudent)
                .join(
                    AcademyStudent,
                    AcademyInvoice.academy_student_id == AcademyStudent.id,
                )
                .where(AcademyInvoice.academy_id == academy_id)
                .where(
                    AcademyInvoice.status.in_(
                        [
                            InvoiceStatus.draft,
                            InvoiceStatus.sent,
                            InvoiceStatus.overdue,
                        ]
                    )
                )
            )
        ).all()

        # 3. 점수 계산 → 0.60+ 후보 저장.
        now = _utcnow()
        suggestions: list[AcademyPaymentMatchSuggestion] = []
        for invoice, student in rows:
            score, features = compute_match_score(
                tx_amount=tx.amount,
                tx_at=tx.tx_at,
                depositor_raw=tx.depositor_raw,
                memo_raw=tx.memo_raw,
                invoice_total=invoice.total_amount,
                invoice_ref_at=invoice.sent_at or invoice.issued_at,
                student_name=student.name,
                deposit_code=student.deposit_code,
            )
            if score < WEAK_SUGGESTION_THRESHOLD:
                continue
            sugg = AcademyPaymentMatchSuggestion(
                bank_transaction_id=tx.id,
                invoice_id=invoice.id,
                score=score,
                features=features,
                suggested_at=now,
                user_decision=AcademyPaymentMatchSuggestionDecision.pending,
            )
            self.db.add(sugg)
            suggestions.append(sugg)

        # 4. tx 갱신 — 후보 있으면 suggested + top-1 점수/feature 저장.
        suggestions.sort(key=lambda s: s.score, reverse=True)
        if suggestions:
            tx.state = AcademyBankTransactionState.suggested
            tx.match_score = suggestions[0].score
            tx.match_features = suggestions[0].features
        # else: unmatched 유지 (학원장 수동 검색 흐름, §6.2)

        await self.db.flush()
        return suggestions

    async def list_suggestions(self, *, academy_id: str, tx_id: str) -> list[AcademyPaymentMatchSuggestion]:
        """저장된 후보 조회 (재계산 없음). §6.1 화면 재방문 시."""
        tx = await self.get_transaction(tx_id)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        result = await self.db.scalars(
            select(AcademyPaymentMatchSuggestion)
            .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx.id)
            .order_by(AcademyPaymentMatchSuggestion.score.desc())
        )
        return list(result.all())


__all__ = ["AcademyPaymentMatchingService"]
