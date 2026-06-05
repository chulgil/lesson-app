"""Academy billing endpoints — AC-M1 그룹 C.

Spec: docs/specs/web/academy/billing_settlement_spec.md.

UX 1탭 흐름:
- generate (월간 자동 생성) / bulk-send (전체 발송) / payments (수금 1탭) /
  calculate (강사 배분 산출) / transfer (송금 완료 마킹)
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_owner_context
from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.academy_billing import (
    AcademyBillingRuleCreate,
    AcademyBillingRuleResponse,
    AcademyBillingRuleUpdate,
    AcademyInvoiceBulkSendRequest,
    AcademyInvoiceCreate,
    AcademyInvoiceListResponse,
    AcademyInvoiceResponse,
    AcademyInvoiceUpdate,
    AcademyPaymentCreate,
    AcademyPaymentListResponse,
    AcademyPaymentResponse,
    AcademySettlementAdjustRequest,
    AcademySettlementListResponse,
    AcademySettlementResponse,
    AcademySettlementTransferRequest,
    AcademySubscriptionCreate,
    AcademySubscriptionListResponse,
    AcademySubscriptionResponse,
    BillingProgressResponse,
    InvoiceStatus,
)
from app.services.academy_billing_service import AcademyBillingService
from app.services.academy_service import AcademyService

# AC-M2 권한 매트릭스: 콘솔 owner 전용. teacher 모드 JWT → 403.
router = APIRouter(dependencies=[Depends(require_owner_context)])


# ---------------------------------------------------------------------------
# BillingRule
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/billing/rule",
    response_model=AcademyBillingRuleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or update academy billing rule (owner only, upsert)",
)
async def create_or_update_rule(
    academy_id: str,
    body: AcademyBillingRuleCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBillingRuleResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    rule = await AcademyBillingService(db).create_or_update_rule(academy_id=academy_id, body=body)
    return AcademyBillingRuleResponse.model_validate(rule)


@router.get(
    "/{academy_id}/billing/rule",
    response_model=AcademyBillingRuleResponse,
    status_code=status.HTTP_200_OK,
    summary="Get academy billing rule (members)",
)
async def get_rule(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBillingRuleResponse:
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    rule = await AcademyBillingService(db).get_rule(academy_id)
    return AcademyBillingRuleResponse.model_validate(rule)


@router.patch(
    "/{academy_id}/billing/rule",
    response_model=AcademyBillingRuleResponse,
    status_code=status.HTTP_200_OK,
    summary="Update billing rule (owner only)",
)
async def update_rule(
    academy_id: str,
    body: AcademyBillingRuleUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyBillingRuleResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    rule = await AcademyBillingService(db).update_rule(academy_id=academy_id, body=body)
    return AcademyBillingRuleResponse.model_validate(rule)


# ---------------------------------------------------------------------------
# AcademySubscription (FE 호환 정책 행)
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/billing/subscriptions",
    response_model=AcademySubscriptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create academy subscription policy (owner only)",
)
async def create_subscription_policy(
    academy_id: str,
    body: AcademySubscriptionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademySubscriptionResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    policy = await AcademyBillingService(db).create_subscription_policy(
        academy_id=academy_id, by_user_id=current_user.id, body=body
    )
    return AcademySubscriptionResponse.model_validate(policy)


@router.get(
    "/{academy_id}/billing/subscriptions",
    response_model=AcademySubscriptionListResponse,
    status_code=status.HTTP_200_OK,
    summary="List academy subscription policies",
)
async def list_subscription_policies(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    teacher_member_id: Annotated[str | None, Query()] = None,
    academy_student_id: Annotated[str | None, Query()] = None,
) -> AcademySubscriptionListResponse:
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    policies, total = await AcademyBillingService(db).list_subscription_policies(
        academy_id=academy_id,
        teacher_member_id=teacher_member_id,
        academy_student_id=academy_student_id,
    )
    return AcademySubscriptionListResponse(
        subscriptions=[AcademySubscriptionResponse.model_validate(p) for p in policies],
        total_count=total,
    )


# ---------------------------------------------------------------------------
# Invoice
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/billing/invoices",
    response_model=AcademyInvoiceResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create invoice (owner only)",
)
async def create_invoice(
    academy_id: str,
    body: AcademyInvoiceCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyInvoiceResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    invoice = await AcademyBillingService(db).create_invoice(academy_id=academy_id, body=body)
    return AcademyInvoiceResponse.model_validate(invoice)


@router.get(
    "/{academy_id}/billing/invoices",
    response_model=AcademyInvoiceListResponse,
    status_code=status.HTTP_200_OK,
    summary="List invoices",
)
async def list_invoices(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    status_filter: Annotated[InvoiceStatus | None, Query(alias="status")] = None,
    period_year: Annotated[int | None, Query()] = None,
    period_month: Annotated[int | None, Query()] = None,
) -> AcademyInvoiceListResponse:
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    invoices, total = await AcademyBillingService(db).list_invoices(
        academy_id=academy_id,
        status_filter=status_filter,
        period_year=period_year,
        period_month=period_month,
    )
    return AcademyInvoiceListResponse(
        invoices=[AcademyInvoiceResponse.model_validate(i) for i in invoices],
        total_count=total,
    )


@router.patch(
    "/billing/invoices/{invoice_id}",
    response_model=AcademyInvoiceResponse,
    status_code=status.HTTP_200_OK,
    summary="Update draft invoice (owner only)",
)
async def update_invoice(
    invoice_id: str,
    body: AcademyInvoiceUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyInvoiceResponse:
    service = AcademyBillingService(db)
    invoice = await service.get_invoice(invoice_id)
    await AcademyService(db).assert_owner(invoice.academy_id, current_user.id)
    updated = await service.update_invoice(invoice_id=invoice_id, body=body)
    return AcademyInvoiceResponse.model_validate(updated)


@router.post(
    "/{academy_id}/billing/invoices/bulk-send",
    status_code=status.HTTP_200_OK,
    summary="Bulk send draft invoices (UX 1tap)",
)
async def bulk_send_invoices(
    academy_id: str,
    body: AcademyInvoiceBulkSendRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    sent_count = await AcademyBillingService(db).bulk_send_invoices(academy_id=academy_id, invoice_ids=body.invoice_ids)
    return {"sent_count": sent_count}


# ---------------------------------------------------------------------------
# Payment
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/billing/payments",
    response_model=AcademyPaymentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record payment 1-tap (owner only)",
)
async def record_payment(
    academy_id: str,
    body: AcademyPaymentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyPaymentResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    payment = await AcademyBillingService(db).record_payment(
        academy_id=academy_id, by_user_id=current_user.id, body=body
    )
    return AcademyPaymentResponse.model_validate(payment)


@router.get(
    "/{academy_id}/billing/payments",
    response_model=AcademyPaymentListResponse,
    status_code=status.HTTP_200_OK,
    summary="List payments (owner only)",
)
async def list_payments(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    invoice_id: Annotated[str | None, Query()] = None,
) -> AcademyPaymentListResponse:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    payments, total = await AcademyBillingService(db).list_payments(academy_id=academy_id, invoice_id=invoice_id)
    return AcademyPaymentListResponse(
        payments=[AcademyPaymentResponse.model_validate(p) for p in payments],
        total_count=total,
    )


# ---------------------------------------------------------------------------
# Settlement
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/billing/settlements/calculate",
    status_code=status.HTTP_200_OK,
    summary="Auto-calculate settlements for a period (UX 1tap, owner only)",
)
async def calculate_settlements(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    period_year: Annotated[int, Query(ge=2020, le=2100)],
    period_month: Annotated[int, Query(ge=1, le=12)],
) -> dict:
    await AcademyService(db).assert_owner(academy_id, current_user.id)
    count = await AcademyBillingService(db).calculate_settlements_for_period(
        academy_id=academy_id, period_year=period_year, period_month=period_month
    )
    return {"calculated_count": count}


@router.get(
    "/{academy_id}/billing/settlements",
    response_model=AcademySettlementListResponse,
    status_code=status.HTTP_200_OK,
    summary="List settlements",
)
async def list_settlements(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    period_year: Annotated[int | None, Query()] = None,
    period_month: Annotated[int | None, Query()] = None,
    teacher_member_id: Annotated[str | None, Query()] = None,
) -> AcademySettlementListResponse:
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    settlements, total = await AcademyBillingService(db).list_settlements(
        academy_id=academy_id,
        period_year=period_year,
        period_month=period_month,
        teacher_member_id=teacher_member_id,
    )
    return AcademySettlementListResponse(
        settlements=[AcademySettlementResponse.model_validate(s) for s in settlements],
        total_count=total,
    )


@router.post(
    "/billing/settlements/{settlement_id}/adjust",
    response_model=AcademySettlementResponse,
    status_code=status.HTTP_200_OK,
    summary="Adjust settlement amount (audit trail, owner only)",
)
async def adjust_settlement(
    settlement_id: str,
    body: AcademySettlementAdjustRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademySettlementResponse:
    service = AcademyBillingService(db)
    s = await service.get_settlement(settlement_id)
    await AcademyService(db).assert_owner(s.academy_id, current_user.id)
    adjusted = await service.adjust_settlement(
        settlement_id=settlement_id,
        by_user_id=current_user.id,
        final_amount=body.final_amount,
        reason=body.reason,
    )
    return AcademySettlementResponse.model_validate(adjusted)


@router.post(
    "/billing/settlements/{settlement_id}/confirm",
    response_model=AcademySettlementResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm settlement (owner only)",
)
async def confirm_settlement(
    settlement_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademySettlementResponse:
    service = AcademyBillingService(db)
    s = await service.get_settlement(settlement_id)
    await AcademyService(db).assert_owner(s.academy_id, current_user.id)
    confirmed = await service.confirm_settlement(settlement_id=settlement_id, by_user_id=current_user.id)
    return AcademySettlementResponse.model_validate(confirmed)


@router.post(
    "/billing/settlements/{settlement_id}/transfer",
    response_model=AcademySettlementResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark settlement as transferred 1-tap (owner only)",
)
async def mark_transferred(
    settlement_id: str,
    body: AcademySettlementTransferRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademySettlementResponse:
    service = AcademyBillingService(db)
    s = await service.get_settlement(settlement_id)
    await AcademyService(db).assert_owner(s.academy_id, current_user.id)
    updated = await service.mark_transferred(settlement_id=settlement_id, by_user_id=current_user.id, note=body.note)
    return AcademySettlementResponse.model_validate(updated)


@router.post(
    "/billing/settlements/{settlement_id}/acknowledge",
    response_model=AcademySettlementResponse,
    status_code=status.HTTP_200_OK,
    summary="Teacher acknowledges settlement (or disputes)",
)
async def acknowledge_settlement(
    settlement_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    dispute_note: Annotated[str | None, Query()] = None,
) -> AcademySettlementResponse:
    # 강사 본인 검증은 service 에서 — 현재는 member 이기만 하면 acknowledge 허용 (자세한 본인 검증 향후).
    service = AcademyBillingService(db)
    s = await service.get_settlement(settlement_id)
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == s.academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    updated = await service.teacher_acknowledge(
        settlement_id=settlement_id, by_user_id=current_user.id, dispute_note=dispute_note
    )
    return AcademySettlementResponse.model_validate(updated)


# ---------------------------------------------------------------------------
# Progress (대시보드 위젯)
# ---------------------------------------------------------------------------


@router.get(
    "/{academy_id}/billing/progress",
    response_model=BillingProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Billing progress summary for a period",
)
async def billing_progress(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    period_year: Annotated[int, Query(ge=2020, le=2100)],
    period_month: Annotated[int, Query(ge=1, le=12)],
) -> BillingProgressResponse:
    academy_service = AcademyService(db)
    my_academies = await academy_service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    return await AcademyBillingService(db).get_progress(
        academy_id=academy_id, period_year=period_year, period_month=period_month
    )


__all__ = ["router"]
