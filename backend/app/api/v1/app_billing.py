"""App billing API — subscription status, trial, purchase verification (R4)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.app_billing import (
    BillingStatusResponse,
    ProductInfo,
    TrialStartResponse,
    VerifyPurchaseRequest,
    VerifyPurchaseResponse,
)
from app.services.app_billing_service import AppBillingService

router = APIRouter()


@router.get(
    "/status",
    response_model=BillingStatusResponse,
    status_code=status.HTTP_200_OK,
)
async def get_billing_status(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> BillingStatusResponse:
    """Return current billing plan status and feature access."""
    service = AppBillingService(db)
    return await service.get_status(current_user.id)


@router.post(
    "/trial/start",
    response_model=TrialStartResponse,
    status_code=status.HTTP_200_OK,
)
async def start_trial(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TrialStartResponse:
    """Start a 14-day Pro trial. Only once per teacher."""
    service = AppBillingService(db)
    return await service.start_trial(current_user.id)


@router.post(
    "/verify-purchase",
    response_model=VerifyPurchaseResponse,
    status_code=status.HTTP_200_OK,
)
async def verify_purchase(
    body: VerifyPurchaseRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> VerifyPurchaseResponse:
    """Verify store receipt and activate the corresponding plan."""
    service = AppBillingService(db)
    return await service.verify_purchase(current_user.id, body)


@router.post(
    "/restore",
    response_model=BillingStatusResponse,
    status_code=status.HTTP_200_OK,
)
async def restore_purchase(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> BillingStatusResponse:
    """Restore purchase from store (device change)."""
    service = AppBillingService(db)
    return await service.restore_purchase(current_user.id)


@router.get(
    "/products",
    response_model=list[ProductInfo],
    status_code=status.HTTP_200_OK,
)
async def list_products() -> list[ProductInfo]:
    """Return available IAP product IDs. Prices come from the store."""
    return AppBillingService.list_products()
