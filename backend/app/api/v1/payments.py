"""Payment gateway endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.services.payment_gateway_service import PaymentGatewayService

router = APIRouter()


class PaymentRequestBody(BaseModel):
    """Request body for creating a payment request."""

    payment_id: str
    amount: int
    order_name: str
    customer_name: str


class PaymentConfirmBody(BaseModel):
    """Request body for confirming a PG payment."""

    payment_key: str
    order_id: str
    amount: int


class PaymentCancelBody(BaseModel):
    """Request body for cancelling a payment."""

    cancel_reason: str


@router.post(
    "/request",
    summary="Create payment request for PG",
)
async def request_payment(
    body: PaymentRequestBody,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Generate payment data for the frontend PG SDK."""
    service = PaymentGatewayService(db)
    try:
        return await service.create_payment_request(
            payment_id=body.payment_id,
            amount=body.amount,
            order_name=body.order_name,
            customer_name=body.customer_name,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/confirm",
    summary="Confirm PG payment",
)
async def confirm_payment(
    body: PaymentConfirmBody,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Confirm payment after user completes PG widget.

    Called by the frontend after the PG SDK returns a paymentKey.
    """
    service = PaymentGatewayService(db)
    try:
        return await service.confirm_payment(
            payment_key=body.payment_key,
            order_id=body.order_id,
            amount=body.amount,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/{payment_id}/cancel",
    summary="Cancel/refund payment",
)
async def cancel_payment(
    payment_id: str,
    body: PaymentCancelBody,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Cancel a completed payment and process refund."""
    service = PaymentGatewayService(db)
    try:
        return await service.cancel_payment(
            payment_id=payment_id,
            cancel_reason=body.cancel_reason,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
