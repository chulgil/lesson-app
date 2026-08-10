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
from app.services.notification_service import NotificationService


def _utcnow() -> datetime:
    return datetime.now(UTC)


class AcademyPaymentMatchingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # 학부모 알림 (§6.3 step4, §7.6)
    # ------------------------------------------------------------------

    async def _notify_parent_payment(
        self,
        invoice: AcademyInvoice,
        *,
        notification_type: str,
        title: str,
        body: str,
    ) -> None:
        """매칭 확정/취소 시 연결된 학부모에게 알림.

        학원만 등록한 학생(parent_user_id NULL)은 알림 대상이 없으므로 skip.
        """
        student = await self.db.get(AcademyStudent, invoice.academy_student_id)
        if student is None or student.parent_user_id is None:
            return
        await NotificationService(self.db).create_and_send(
            user_id=student.parent_user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            data={"academy_id": invoice.academy_id, "invoice_id": invoice.id},
        )

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

    async def get_transaction(self, tx_id: str, *, for_update: bool = False) -> AcademyBankTransaction:
        """Fetch a bank transaction.

        ``for_update`` row-locks the row so the state check → mutate sequences
        (confirm/split/ignore/unmatch/suggest) cannot race a concurrent
        double-tap into duplicate AcademyPayment rows. No-op on SQLite (tests),
        same pattern as subscription_service.
        """
        if for_update:
            tx = await self.db.scalar(
                select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id).with_for_update()
            )
        else:
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
        tx = await self.get_transaction(tx_id, for_update=True)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state in {AcademyBankTransactionState.matched, AcademyBankTransactionState.ignored}:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"tx already {tx.state.value}",
            )
        if paid_amount > tx.amount:
            # 통장 입금액보다 큰 금액을 매칭하면 정산이 왜곡된다 (§7.3 초과는 별도 흐름).
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="paid_amount exceeds transaction amount",
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

        # 5. 학부모 알림 (§6.3 step4) — 연결된 학부모에게 납부 확인.
        await self._notify_parent_payment(
            invoice,
            notification_type="academyPaymentMatched",
            title="납부 확인 완료",
            body=f"{invoice.period_year}년 {invoice.period_month}월 수강료 납부가 확인되었습니다.",
        )

        return tx, payment

    # ------------------------------------------------------------------
    # 무시 (§6.2) / 매칭 취소 (§7.6)
    # ------------------------------------------------------------------

    async def ignore_transaction(self, *, academy_id: str, tx_id: str) -> AcademyBankTransaction:
        """학원장이 '이번 회기는 무시' → state='ignored', 다음 마감에서 자동 제외."""
        tx = await self.get_transaction(tx_id, for_update=True)
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

        분할 매칭(§7.1)도 동일 경로 — bank_tx_ref=tx.id 인 모든 payment 의 distinct
        invoice 들을 회수해 각각 paid→sent/draft 재계산.

        Note: §7.6 의 "7일 이내" 시간 제약은 추후 라운드에서 추가 (현재는 항상 허용).
        """
        tx = await self.get_transaction(tx_id, for_update=True)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state != AcademyBankTransactionState.matched:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="only matched tx can be reverted",
            )

        # 1. 영향 받는 invoice 수집 (분할 매칭 대응 — payments 의 distinct invoice_id).
        affected_invoice_ids = list(
            (
                await self.db.scalars(
                    select(AcademyPayment.invoice_id).where(AcademyPayment.bank_tx_ref == tx.id).distinct()
                )
            ).all()
        )

        # 2. AcademyPayment 삭제 (bank_tx_ref=tx.id 인 행만).
        await self.db.execute(delete(AcademyPayment).where(AcademyPayment.bank_tx_ref == tx.id))
        await self.db.flush()

        # 3. 각 invoice 상태 회귀 — 잔여 수금 합산으로 재계산.
        for invoice_id in affected_invoice_ids:
            invoice = await self.db.get(AcademyInvoice, invoice_id)
            if invoice is None or invoice.status != InvoiceStatus.paid:
                continue
            total_paid = await self.db.scalar(
                select(func.coalesce(func.sum(AcademyPayment.paid_amount), 0)).where(
                    AcademyPayment.invoice_id == invoice_id
                )
            )
            if int(total_paid or 0) < invoice.total_amount:
                # 발송 이력이 있으면 sent 로, 없으면 draft 로 회귀.
                invoice.status = InvoiceStatus.sent if invoice.sent_at is not None else InvoiceStatus.draft

        # 4. tx 회귀.
        tx.state = AcademyBankTransactionState.unmatched
        tx.matched_invoice_id = None
        tx.matched_by_user_id = None
        tx.matched_at = None

        # 5. suggestion 결정 reset — revert 는 "매칭 없던 상태로" 회귀이므로 이전
        #    accepted/rejected 결정을 pending 으로 되돌린다. 이렇게 해야 이후
        #    re-suggest 의 재계산이 decided 된 (tx, invoice) pair 를 재INSERT 하지
        #    않아 uq_acad_match_sugg_per_pair UNIQUE 위반(IntegrityError)을 피한다.
        decided_suggestions = await self.db.scalars(
            select(AcademyPaymentMatchSuggestion).where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx.id)
        )
        for sugg in decided_suggestions.all():
            sugg.user_decision = AcademyPaymentMatchSuggestionDecision.pending
            sugg.decided_at = None

        await self.db.flush()

        # 6. 학부모 정정 알림 (§7.6) — 매칭이 취소된 각 invoice 학생의 학부모에게.
        for invoice_id in affected_invoice_ids:
            invoice = await self.db.get(AcademyInvoice, invoice_id)
            if invoice is not None:
                await self._notify_parent_payment(
                    invoice,
                    notification_type="academyPaymentReverted",
                    title="납부 정정",
                    body=f"{invoice.period_year}년 {invoice.period_month}월 수강료 납부 확인이 취소되었습니다.",
                )

        return tx

    # ------------------------------------------------------------------
    # §7.1 형제 합산 분할 매칭
    # ------------------------------------------------------------------

    async def split_match(
        self,
        *,
        academy_id: str,
        tx_id: str,
        splits: list[tuple[str, int]],
        by_user_id: str,
    ) -> tuple[AcademyBankTransaction, list[AcademyPayment]]:
        """§7.1 형제 합산 분할 매칭 — 한 통장 입금을 N개 invoice 에 분할.

        처리:
        1. 각 invoice 별 AcademyPayment 행 생성 (모두 bank_tx_ref=tx.id, depositor_raw 보존)
        2. 각 invoice status 갱신 — 누적 paid >= total 이면 paid
        3. tx.state='matched', matched_invoice_id = NULL (분할 — 단일 FK 의미 없음)
        4. tx 의 pending suggestion 처리: splits 에 포함된 invoice → accepted,
           나머지 → rejected (분쟁 audit)

        에러:
        - tx 가 다른 학원 → 400
        - tx 가 이미 matched/ignored → 409
        - 같은 invoice_id 중복 → 400
        - invoice 가 다른 학원 → 400
        - invoice 취소됨 → 409
        """
        if not splits:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="splits must contain at least one item",
            )
        invoice_ids_in_request = [inv_id for inv_id, _ in splits]
        if len(set(invoice_ids_in_request)) != len(invoice_ids_in_request):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="duplicate invoice_id in splits",
            )

        tx = await self.get_transaction(tx_id, for_update=True)
        if tx.academy_id != academy_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="tx not in this academy")
        if tx.state in {AcademyBankTransactionState.matched, AcademyBankTransactionState.ignored}:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"tx already {tx.state.value}",
            )
        if sum(paid_amount for _, paid_amount in splits) > tx.amount:
            # 분할 합이 통장 입금액을 초과하면 정산이 왜곡된다.
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="split amounts exceed transaction amount",
            )

        # 1. invoice 전체 검증 (모두 같은 학원 + 취소 아님).
        invoices_by_id: dict[str, AcademyInvoice] = {}
        for invoice_id in invoice_ids_in_request:
            invoice = await self.db.get(AcademyInvoice, invoice_id)
            if invoice is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"invoice not found: {invoice_id}",
                )
            if invoice.academy_id != academy_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"invoice not in this academy: {invoice_id}",
                )
            if invoice.status == InvoiceStatus.cancelled:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Cannot match cancelled invoice: {invoice_id}",
                )
            invoices_by_id[invoice_id] = invoice

        # 2. 각 invoice 별 AcademyPayment 생성 + 상태 갱신.
        payments: list[AcademyPayment] = []
        for invoice_id, paid_amount in splits:
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
            payments.append(payment)
        await self.db.flush()

        for invoice_id, invoice in invoices_by_id.items():
            total_paid = await self.db.scalar(
                select(func.coalesce(func.sum(AcademyPayment.paid_amount), 0)).where(
                    AcademyPayment.invoice_id == invoice_id
                )
            )
            if int(total_paid or 0) >= invoice.total_amount:
                invoice.status = InvoiceStatus.paid

        # 3. tx 상태 갱신 — 분할이므로 matched_invoice_id 는 NULL 유지.
        now = _utcnow()
        tx.state = AcademyBankTransactionState.matched
        tx.matched_invoice_id = None
        tx.matched_by_user_id = by_user_id
        tx.matched_at = now

        # 4. suggestion audit — splits 에 포함된 invoice 는 accepted, 나머지 rejected.
        pending_suggestions = await self.db.scalars(
            select(AcademyPaymentMatchSuggestion)
            .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx.id)
            .where(AcademyPaymentMatchSuggestion.user_decision == AcademyPaymentMatchSuggestionDecision.pending)
        )
        accepted_set = set(invoice_ids_in_request)
        for sugg in pending_suggestions.all():
            sugg.user_decision = (
                AcademyPaymentMatchSuggestionDecision.accepted
                if sugg.invoice_id in accepted_set
                else AcademyPaymentMatchSuggestionDecision.rejected
            )
            sugg.decided_at = now

        await self.db.flush()

        # 5. 학부모 알림 (§6.3 step4) — 각 invoice 학생의 학부모에게 납부 확인.
        for invoice in invoices_by_id.values():
            await self._notify_parent_payment(
                invoice,
                notification_type="academyPaymentMatched",
                title="납부 확인 완료",
                body=f"{invoice.period_year}년 {invoice.period_month}월 수강료 납부가 확인되었습니다.",
            )

        return tx, payments

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
        tx = await self.get_transaction(tx_id, for_update=True)
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
                parent_name=student.parent_name,
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

    # ------------------------------------------------------------------
    # §6.2 일괄 매칭 화면 (inbox)
    # ------------------------------------------------------------------

    async def list_matching_inbox(
        self, *, academy_id: str
    ) -> tuple[
        list[
            tuple[
                AcademyBankTransaction,
                AcademyPaymentMatchSuggestion | None,
                AcademyInvoice | None,
                AcademyStudent | None,
            ]
        ],
        int,
        int,
    ]:
        """학원장 일괄 매칭 화면용 묶음 조회.

        반환: (rows, suggested_count, unmatched_count) — rows 는 N+1 회피용으로 각
        tx 의 top-1 suggestion + invoice + 학생을 미리 join 한 결과.

        - 대상: state=suggested 또는 state=unmatched (처리 대기 행만)
        - matched/ignored 행은 제외 (§6.2 "각 행을 빠르게 처리")
        """
        # 1. 처리 대기 tx 행 조회.
        txs = list(
            (
                await self.db.scalars(
                    select(AcademyBankTransaction)
                    .where(AcademyBankTransaction.academy_id == academy_id)
                    .where(
                        AcademyBankTransaction.state.in_(
                            [
                                AcademyBankTransactionState.unmatched,
                                AcademyBankTransactionState.suggested,
                            ]
                        )
                    )
                    .order_by(AcademyBankTransaction.tx_at.desc())
                )
            ).all()
        )
        if not txs:
            return [], 0, 0

        tx_ids = [tx.id for tx in txs]

        # 2. 각 tx 의 top-1 (pending) suggestion 1회 조회.
        sugg_rows = (
            (
                await self.db.execute(
                    select(AcademyPaymentMatchSuggestion)
                    .where(AcademyPaymentMatchSuggestion.bank_transaction_id.in_(tx_ids))
                    .where(AcademyPaymentMatchSuggestion.user_decision == AcademyPaymentMatchSuggestionDecision.pending)
                    .order_by(AcademyPaymentMatchSuggestion.score.desc())
                )
            )
            .scalars()
            .all()
        )
        top_by_tx: dict[str, AcademyPaymentMatchSuggestion] = {}
        for sugg in sugg_rows:
            # 점수 desc 순회 — 첫 등장이 top-1.
            top_by_tx.setdefault(sugg.bank_transaction_id, sugg)

        # 3. top suggestion 의 invoice + 학생 1회 join.
        invoice_ids = [s.invoice_id for s in top_by_tx.values()]
        inv_student_map: dict[str, tuple[AcademyInvoice, AcademyStudent]] = {}
        if invoice_ids:
            inv_rows = (
                await self.db.execute(
                    select(AcademyInvoice, AcademyStudent)
                    .join(AcademyStudent, AcademyInvoice.academy_student_id == AcademyStudent.id)
                    .where(AcademyInvoice.id.in_(invoice_ids))
                )
            ).all()
            for inv, st in inv_rows:
                inv_student_map[inv.id] = (inv, st)

        # 4. 묶음 조립 + 집계.
        suggested_count = 0
        unmatched_count = 0
        rows: list[
            tuple[
                AcademyBankTransaction,
                AcademyPaymentMatchSuggestion | None,
                AcademyInvoice | None,
                AcademyStudent | None,
            ]
        ] = []
        for tx in txs:
            if tx.state == AcademyBankTransactionState.suggested:
                suggested_count += 1
            else:
                unmatched_count += 1
            top = top_by_tx.get(tx.id)
            inv, st = inv_student_map.get(top.invoice_id, (None, None)) if top else (None, None)
            rows.append((tx, top, inv, st))
        return rows, suggested_count, unmatched_count

    # ------------------------------------------------------------------
    # §5.1 CSV 일괄 임포트
    # ------------------------------------------------------------------

    async def import_csv(
        self,
        *,
        academy_id: str,
        csv_content: str,
        auto_suggest: bool = True,
    ) -> tuple[int, int, int, list[dict]]:
        """학원장 통장 CSV 일괄 업로드.

        흐름:
        1. ``parse_csv`` 로 정상 행/에러 행 분리
        2. 정상 행 → ``AcademyBankTransaction`` 일괄 INSERT (source=csv)
        3. 각 신규 tx 에 fuzzy 자동 실행 → state 갱신
        4. 집계 반환

        Returns:
            (created_count, suggested_count, unmatched_count, error_rows)

        헤더 누락 등 전체 파싱 실패 (row_number=0) 는 HTTPException(422) 로 변환.
        행 단위 실패는 graceful — 정상 행은 처리하고 error_rows 로 보고.
        """
        from app.services.academy_payment_matching_csv import parse_csv

        valid_rows, error_rows = parse_csv(csv_content)

        # 헤더 자체가 잘못된 경우 — row_number=0 인 에러만 있고 정상 0건.
        if not valid_rows and any(e["row_number"] == 0 for e in error_rows):
            reason = next(e["reason"] for e in error_rows if e["row_number"] == 0)
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=reason)

        created_txs: list[AcademyBankTransaction] = []
        for row in valid_rows:
            tx = AcademyBankTransaction(
                academy_id=academy_id,
                source=AcademyBankTransactionSource.csv,
                source_ref=row.get("source_ref"),
                bank_name=row.get("bank_name"),
                tx_at=row["tx_at"],
                amount=row["amount"],
                depositor_raw=row["depositor_raw"],
                memo_raw=row.get("memo_raw"),
                state=AcademyBankTransactionState.unmatched,
            )
            self.db.add(tx)
            created_txs.append(tx)
        await self.db.flush()

        suggested_count = 0
        unmatched_count = 0
        if auto_suggest:
            for tx in created_txs:
                suggestions = await self.suggest_matches(academy_id=academy_id, tx_id=tx.id)
                if suggestions:
                    suggested_count += 1
                else:
                    unmatched_count += 1
        else:
            unmatched_count = len(created_txs)

        return len(created_txs), suggested_count, unmatched_count, list(error_rows)


__all__ = ["AcademyPaymentMatchingService"]
