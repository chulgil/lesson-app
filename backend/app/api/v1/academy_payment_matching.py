"""Academy payment matching endpoints — AC-M3 §4 수기 입력 + 1탭 확정.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.2 (수기 입력), §6.3 (1탭 확정), §7.6 (취소).

UX 1탭 흐름:
- POST bank-transactions  → 학원장이 통장 1건 수기 입력
- GET  bank-transactions  → 미매칭/제안 리스트 (§6.2 일괄 매칭 화면)
- POST bank-transactions/{tx_id}/match  → 학원장 1탭 확정 (§6.3)
- POST bank-transactions/{tx_id}/ignore → '이번 회기 무시'
- POST bank-transactions/{tx_id}/revert → 매칭 취소 (§7.6)
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_owner_context
from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.academy_billing import AcademyPaymentResponse
from app.schemas.academy_payment_matching import (
    AcademyBankTransactionCreate,
    AcademyBankTransactionListResponse,
    AcademyBankTransactionResponse,
    AcademyMatchConfirmRequest,
    AcademyMatchConfirmResponse,
    AcademyPaymentMatchSuggestionListResponse,
    AcademyPaymentMatchSuggestionResponse,
    BankTransactionState,
)
from app.services.academy_payment_matching_service import AcademyPaymentMatchingService
from app.services.academy_service import AcademyService

# 학원장 owner 전용. teacher 모드 JWT → 403 (context_deps).
router = APIRouter(dependencies=[Depends(require_owner_context)])


@router.post(
    "/{academy_id}/billing/bank-transactions",
    response_model=AcademyBankTransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="수기 입력 — 통장 입금 1건 (owner only)",
)
async def create_bank_transaction(
    academy_id: str,
    body: AcademyBankTransactionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBankTransactionResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    tx = await AcademyPaymentMatchingService(db).create_manual_transaction(academy_id=academy_id, body=body)
    return AcademyBankTransactionResponse.model_validate(tx)


@router.get(
    "/{academy_id}/billing/bank-transactions",
    response_model=AcademyBankTransactionListResponse,
    status_code=status.HTTP_200_OK,
    summary="미매칭/제안/매칭/무시 리스트 (owner only)",
)
async def list_bank_transactions(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    state: Annotated[BankTransactionState | None, Query()] = None,
) -> AcademyBankTransactionListResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    txs, total = await AcademyPaymentMatchingService(db).list_transactions(academy_id=academy_id, state=state)
    return AcademyBankTransactionListResponse(
        transactions=[AcademyBankTransactionResponse.model_validate(t) for t in txs],
        total_count=total,
    )


@router.post(
    "/{academy_id}/billing/bank-transactions/{tx_id}/match",
    response_model=AcademyMatchConfirmResponse,
    status_code=status.HTTP_200_OK,
    summary="1탭 매칭 확정 — AcademyPayment 생성 + invoice 상태 갱신 (owner only)",
)
async def match_bank_transaction(
    academy_id: str,
    tx_id: str,
    body: AcademyMatchConfirmRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyMatchConfirmResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    tx, payment = await AcademyPaymentMatchingService(db).confirm_match(
        academy_id=academy_id,
        tx_id=tx_id,
        invoice_id=body.invoice_id,
        paid_amount=body.paid_amount,
        by_user_id=current_user.id,
    )
    return AcademyMatchConfirmResponse(
        bank_transaction=AcademyBankTransactionResponse.model_validate(tx),
        payment=AcademyPaymentResponse.model_validate(payment),
    )


@router.post(
    "/{academy_id}/billing/bank-transactions/{tx_id}/ignore",
    response_model=AcademyBankTransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="입금 무시 — 다음 마감에서 자동 제외 (owner only)",
)
async def ignore_bank_transaction(
    academy_id: str,
    tx_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBankTransactionResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    tx = await AcademyPaymentMatchingService(db).ignore_transaction(academy_id=academy_id, tx_id=tx_id)
    return AcademyBankTransactionResponse.model_validate(tx)


@router.post(
    "/{academy_id}/billing/bank-transactions/{tx_id}/revert",
    response_model=AcademyBankTransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="매칭 취소 — AcademyPayment 삭제 + 상태 회귀 (owner only)",
)
async def revert_bank_transaction(
    academy_id: str,
    tx_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBankTransactionResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    tx = await AcademyPaymentMatchingService(db).revert_match(academy_id=academy_id, tx_id=tx_id)
    return AcademyBankTransactionResponse.model_validate(tx)


@router.post(
    "/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
    response_model=AcademyPaymentMatchSuggestionListResponse,
    status_code=status.HTTP_200_OK,
    summary="§3 fuzzy 매칭 알고리즘 실행 — 후보 0~N건 제시 (owner only)",
)
async def suggest_matches(
    academy_id: str,
    tx_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyPaymentMatchSuggestionListResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    suggestions = await AcademyPaymentMatchingService(db).suggest_matches(academy_id=academy_id, tx_id=tx_id)
    return AcademyPaymentMatchSuggestionListResponse(
        suggestions=[AcademyPaymentMatchSuggestionResponse.model_validate(s) for s in suggestions],
        total_count=len(suggestions),
    )


@router.get(
    "/{academy_id}/billing/bank-transactions/{tx_id}/suggestions",
    response_model=AcademyPaymentMatchSuggestionListResponse,
    status_code=status.HTTP_200_OK,
    summary="저장된 매칭 후보 조회 (재계산 없음, owner only)",
)
async def list_suggestions(
    academy_id: str,
    tx_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyPaymentMatchSuggestionListResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    suggestions = await AcademyPaymentMatchingService(db).list_suggestions(academy_id=academy_id, tx_id=tx_id)
    return AcademyPaymentMatchSuggestionListResponse(
        suggestions=[AcademyPaymentMatchSuggestionResponse.model_validate(s) for s in suggestions],
        total_count=len(suggestions),
    )


__all__ = ["router"]
