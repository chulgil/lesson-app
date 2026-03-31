"""Payment Gateway service — vendor-agnostic PG integration.

Supports Toss Payments as primary provider.
Designed for easy extension to other PGs (Iamport, NicePay, etc.).

Environment variables:
  PG_PROVIDER: "toss" (default)
  TOSS_SECRET_KEY: Toss Payments secret key
  TOSS_CLIENT_KEY: Toss Payments client key (for frontend)
"""

from __future__ import annotations

import base64
import logging
from datetime import datetime, timezone
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.payment import Payment, PaymentStatus

logger = logging.getLogger(__name__)

# Toss Payments API endpoints
_TOSS_BASE_URL = "https://api.tosspayments.com/v1"
_TOSS_CONFIRM_URL = f"{_TOSS_BASE_URL}/payments/confirm"
_TOSS_CANCEL_URL = f"{_TOSS_BASE_URL}/payments"


class PaymentGatewayService:
    """Vendor-agnostic payment gateway integration."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_payment_request(
        self,
        *,
        payment_id: str,
        amount: int,
        order_name: str,
        customer_name: str,
    ) -> dict[str, Any]:
        """Create a payment request for the frontend to process.

        Returns data needed by the frontend PG SDK to initiate payment.
        """
        payment = await self.db.get(Payment, payment_id)
        if payment is None:
            raise ValueError(f"Payment {payment_id} not found")

        # Generate idempotent order ID
        order_id = f"lessonaza_{payment_id}"

        # Store order ID for webhook matching
        payment.pg_provider = getattr(settings, "PG_PROVIDER", "toss")
        payment.pg_order_id = order_id
        await self.db.flush()

        return {
            "orderId": order_id,
            "amount": amount,
            "orderName": order_name,
            "customerName": customer_name,
            "paymentId": payment_id,
            "clientKey": getattr(settings, "TOSS_CLIENT_KEY", ""),
        }

    async def confirm_payment(
        self,
        *,
        payment_key: str,
        order_id: str,
        amount: int,
    ) -> dict[str, Any]:
        """Confirm payment with PG after frontend approval.

        Called after the user completes payment on the PG widget.
        Verifies the payment with the PG server and updates the record.
        """
        # Find payment by order_id
        payment = await self.db.scalar(
            select(Payment).where(Payment.pg_order_id == order_id)
        )
        if payment is None:
            raise ValueError(f"Payment with order_id {order_id} not found")

        # Verify amount matches
        if payment.amount != amount:
            raise ValueError(
                f"Amount mismatch: expected {payment.amount}, got {amount}"
            )

        # Call PG confirmation API
        secret_key = getattr(settings, "TOSS_SECRET_KEY", "")
        if not secret_key:
            # Development mode: skip PG confirmation
            logger.warning("TOSS_SECRET_KEY not set, skipping PG confirmation")
            payment.pg_payment_key = payment_key
            payment.status = PaymentStatus.paid
            payment.paid_at = datetime.now(timezone.utc)
            await self.db.flush()
            return {"status": "paid", "paymentId": payment.id}

        # Toss Payments confirmation
        auth_header = base64.b64encode(
            f"{secret_key}:".encode()
        ).decode()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                _TOSS_CONFIRM_URL,
                json={
                    "paymentKey": payment_key,
                    "orderId": order_id,
                    "amount": amount,
                },
                headers={
                    "Authorization": f"Basic {auth_header}",
                    "Content-Type": "application/json",
                },
                timeout=30.0,
            )

        if response.status_code == 200:
            pg_data = response.json()
            payment.pg_payment_key = payment_key
            payment.pg_transaction_id = pg_data.get("transactionKey")
            payment.pg_response = pg_data
            payment.status = PaymentStatus.paid
            payment.paid_at = datetime.now(timezone.utc)
            await self.db.flush()

            logger.info("Payment confirmed: %s (order: %s)", payment.id, order_id)
            return {"status": "paid", "paymentId": payment.id}
        else:
            error_data = response.json()
            payment.pg_failure_reason = error_data.get("message", "Unknown error")
            payment.pg_response = error_data
            await self.db.flush()

            logger.error(
                "Payment confirmation failed: %s - %s",
                order_id,
                error_data.get("message"),
            )
            raise ValueError(
                f"PG confirmation failed: {error_data.get('message', 'Unknown error')}"
            )

    async def cancel_payment(
        self,
        *,
        payment_id: str,
        cancel_reason: str,
    ) -> dict[str, Any]:
        """Cancel/refund a completed payment.

        Returns cancellation result.
        """
        payment = await self.db.get(Payment, payment_id)
        if payment is None:
            raise ValueError(f"Payment {payment_id} not found")

        if payment.status not in (PaymentStatus.paid, PaymentStatus.confirmed):
            raise ValueError(f"Cannot cancel payment with status: {payment.status}")

        secret_key = getattr(settings, "TOSS_SECRET_KEY", "")

        if not secret_key or not payment.pg_payment_key:
            # Development mode or non-PG payment: direct status update
            payment.status = PaymentStatus.refunded
            await self.db.flush()
            return {"status": "refunded", "paymentId": payment.id}

        # Toss Payments cancellation
        auth_header = base64.b64encode(
            f"{secret_key}:".encode()
        ).decode()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{_TOSS_CANCEL_URL}/{payment.pg_payment_key}/cancel",
                json={"cancelReason": cancel_reason},
                headers={
                    "Authorization": f"Basic {auth_header}",
                    "Content-Type": "application/json",
                },
                timeout=30.0,
            )

        if response.status_code == 200:
            pg_data = response.json()
            payment.status = PaymentStatus.refunded
            payment.pg_response = pg_data
            await self.db.flush()

            logger.info("Payment cancelled: %s", payment.id)
            return {"status": "refunded", "paymentId": payment.id}
        else:
            error_data = response.json()
            logger.error("Payment cancellation failed: %s", error_data)
            raise ValueError(
                f"PG cancellation failed: {error_data.get('message', 'Unknown error')}"
            )
