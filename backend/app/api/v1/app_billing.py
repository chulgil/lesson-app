"""App billing and IAP endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.app_billing import (
    BillingCancelResponse,
    BillingPlanResponse,
    IapReceiptResponse,
    IapValidateRequest,
    IapValidateResponse,
    TrialStartResponse,
)
from app.services.app_billing_service import AppBillingService

router = APIRouter()


@router.get(
    "/plan",
    response_model=BillingPlanResponse,
    summary="Get current user billing plan",
    status_code=status.HTTP_200_OK,
)
async def get_billing_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BillingPlanResponse:
    """Retrieve the current user's app subscription tier and status."""
    service = AppBillingService(db)
    plan = await service.get_active_plan(current_user.id)

    return BillingPlanResponse.model_validate(plan)


@router.get(
    "/me",
    response_model=BillingPlanResponse,
    summary="Get current user billing plan",
    status_code=status.HTTP_200_OK,
)
async def get_billing_plan_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BillingPlanResponse:
    """Paywall spec alias for retrieving the current billing plan."""
    return await get_billing_plan(current_user=current_user, db=db)


@router.post(
    "/trial/start",
    response_model=TrialStartResponse,
    summary="Start Pro trial",
    status_code=status.HTTP_200_OK,
)
async def start_trial(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrialStartResponse:
    """Activate 14-day Pro trial subscription.

    Returns 409 if trial already used by this account.
    """
    service = AppBillingService(db)

    try:
        plan = await service.activate_trial(current_user.id)
        await db.commit()

        return TrialStartResponse(
            success=True,
            message="Pro trial activated for 14 days",
            plan_id=plan.id,
            expires_at=plan.expires_at,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e),
        )


@router.post(
    "/iap/validate",
    response_model=IapValidateResponse,
    summary="Validate IAP receipt",
    status_code=status.HTTP_200_OK,
)
async def validate_iap_receipt(
    request: IapValidateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> IapValidateResponse:
    """Validate in-app purchase receipt and activate subscription.

    Accepts receipts from both Apple App Store and Google Play Store.
    Stores receipt for audit trail and updates billing plan on success.
    """
    service = AppBillingService(db)

    try:
        granted, plan = await service.apply_iap_receipt(
            user_id=current_user.id,
            platform=request.platform,
            raw_receipt=request.receipt,
            # transaction_id 는 실제 receipt parser 가 추출하기 전까지 None — service 에서
            # raw_receipt + user_id hash 로 합성. product_id 를 transaction_id 로 쓰던
            # 기존 placeholder 는 (platform, transaction_id) UNIQUE 위반으로 같은 SKU 의
            # 두 번째 사용자 결제부터 모두 차단되던 P0.
            transaction_id=None,
            product_id=request.product_id,
        )
        # Always commit so the audit-trail receipt is persisted, even when the
        # plan was not upgraded (#405 default-deny).
        await db.commit()

        if granted:
            return IapValidateResponse(
                success=True,
                message="Receipt validated and plan activated",
                plan_id=plan.id,
                tier=plan.tier,
                expires_at=plan.expires_at,
            )

        return IapValidateResponse(
            success=False,
            message="Receipt stored for review — IAP validation not yet enabled",
            plan_id=None,
            tier=None,
            expires_at=None,
        )
    except Exception:
        # 외부 라이브러리 traceback / DB 에러 메시지가 응답에 노출되는 것을 막는다.
        # 상세는 서버 로그에만 남기고, 클라이언트에는 generic 한 메시지만 반환.
        import logging

        logging.getLogger(__name__).exception("IAP receipt validation failed for user=%s", current_user.id)
        await db.rollback()

        return IapValidateResponse(
            success=False,
            message="Receipt validation failed",
            plan_id=None,
            tier=None,
            expires_at=None,
        )


@router.post(
    "/verify-purchase",
    response_model=IapValidateResponse,
    summary="Validate IAP receipt",
    status_code=status.HTTP_200_OK,
)
async def verify_purchase(
    request: IapValidateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> IapValidateResponse:
    """Paywall spec alias for IAP receipt validation."""
    return await validate_iap_receipt(request=request, current_user=current_user, db=db)


@router.post(
    "/cancel",
    response_model=BillingCancelResponse,
    summary="Cancel current app billing plan",
    status_code=status.HTTP_200_OK,
)
async def cancel_billing_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BillingCancelResponse:
    """Cancel future app billing renewals for the current user."""
    service = AppBillingService(db)
    await service.cancel_plan(current_user.id)
    await db.commit()
    return BillingCancelResponse(success=True, message="Billing plan cancelled")


@router.get(
    "/receipts",
    response_model=list[IapReceiptResponse],
    summary="List IAP receipts",
    status_code=status.HTTP_200_OK,
)
async def list_iap_receipts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[IapReceiptResponse]:
    """Return the current user's IAP receipt audit history."""
    service = AppBillingService(db)
    return await service.list_receipts(current_user.id)
