"""App billing service for subscription and IAP management."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import PRODUCTION_LIKE_ENVIRONMENTS, settings
from app.models.app_billing import (
    AppBillingPlan,
    BillingPlanStatus,
    BillingTier,
    IapPlatform,
    IapReceipt,
    IapReceiptStatus,
)
from app.schemas.app_billing import IapReceiptResponse


class IapValidationPendingError(Exception):
    """Raised when an IAP receipt is accepted for audit but not yet validated.

    This is the default behavior — receipts are stored but plans are NOT
    upgraded until a real Apple/Google validator confirms the transaction.
    """


def _iap_dev_auto_grant_allowed() -> bool:
    """Allow auto-grant only outside production-like environments and only when explicitly opted in.

    Production/beta NEVER auto-grant. The dev flag is consulted only for local/test
    workflows where mocking an Apple/Google validator is convenient.
    """
    if settings.ENVIRONMENT in PRODUCTION_LIKE_ENVIRONMENTS:
        return False
    return settings.IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY


class AppBillingService:
    """Manage app usage tier subscriptions and in-app purchases."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_active_plan(self, user_id: str) -> AppBillingPlan:
        """Get user's current billing plan, or create free tier if not exists."""
        result = await self.db.scalar(
            select(AppBillingPlan).where(AppBillingPlan.user_id == user_id),
        )

        if result:
            return result

        # Create default free plan if not exists
        now = datetime.now(UTC)
        plan = AppBillingPlan(
            user_id=user_id,
            tier=BillingTier.free,
            status=BillingPlanStatus.active,
            started_at=now,
            expires_at=None,
            source="admin_grant",
            trial_used=False,
        )
        self.db.add(plan)
        await self.db.flush()

        return plan

    async def activate_trial(self, user_id: str, days: int = 14) -> AppBillingPlan:
        """Activate 14-day Pro trial if not already used.

        Args:
            user_id: User ID
            days: Trial duration in days (default 14)

        Returns:
            Updated AppBillingPlan

        Raises:
            ValueError: If trial already used
        """
        plan = await self.get_active_plan(user_id)

        if plan.trial_used:
            raise ValueError("Trial already used for this account")

        now = datetime.now(UTC)
        plan.tier = BillingTier.pro
        plan.status = BillingPlanStatus.trial
        plan.started_at = now
        plan.expires_at = now + timedelta(days=days)
        plan.trial_used = True
        plan.source = "trial_grant"

        self.db.add(plan)
        await self.db.flush()

        return plan

    async def apply_iap_receipt(
        self,
        user_id: str,
        platform: str,
        raw_receipt: str,
        transaction_id: str | None,
        product_id: str,
    ) -> tuple[bool, AppBillingPlan]:
        """Persist an IAP receipt and (by default) refuse to upgrade the plan.

        Security contract (#405): receipts are always stored for audit, but the
        billing plan is NOT upgraded unless a real Apple/Google validator has
        confirmed the transaction. Until that validator is wired up, callers get
        ``(False, current_plan)`` so a forged or replayed receipt cannot grant Pro.

        The ``IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY`` setting is consulted only in
        non-production environments to keep local mocking convenient; production
        and beta always default-deny.

        transaction_id 가 None / 빈 문자열 / 자명한 placeholder (product_id 값 그대로)
        이면 raw_receipt 의 sha256 으로 합성한다 — 실제 receipt parser 가 도입되기 전
        ``(platform, transaction_id)`` UNIQUE 제약을 우회하기 위해 router 가 ``product_id``
        를 그대로 ``transaction_id`` 로 넘기던 P0 (#405 후속) 를 차단한다. 같은 SKU 의
        두 번째 사용자 결제부터 모든 후속 호출이 IntegrityError 로 영구 차단되던 결함.

        idempotency: 같은 user 가 같은 raw_receipt 를 재제출하면 동일 hash → 동일
        transaction_id → ``IntegrityError`` 로 자연스럽게 중복 거부 (audit log 1건만 유지).

        Returns:
            Tuple of (granted, plan). ``granted`` is True only when the plan was
            upgraded as a result of this receipt; otherwise the user keeps their
            existing plan.
        """
        import hashlib

        canonical_transaction_id = transaction_id
        if not canonical_transaction_id or canonical_transaction_id == product_id:
            # raw_receipt 에 user 식별자 + SKU 가 포함되어 있어 user 별로 충돌하지 않는다.
            # raw_receipt 가 같은 값으로 재제출되면 같은 hash → idempotent.
            digest = hashlib.sha256(f"{user_id}:{platform}:{raw_receipt}".encode()).hexdigest()
            canonical_transaction_id = f"placeholder:{digest[:32]}"

        receipt = IapReceipt(
            user_id=user_id,
            platform=IapPlatform(platform),
            raw_receipt=raw_receipt,
            transaction_id=canonical_transaction_id,
            product_id=product_id,
            status=IapReceiptStatus.pending_verification,
        )
        self.db.add(receipt)
        await self.db.flush()

        plan = await self.get_active_plan(user_id)

        if not _iap_dev_auto_grant_allowed():
            # Default-deny: receipt stored for audit, plan unchanged.
            return (False, plan)

        # Dev/test convenience path only. Real Apple/Google validation must
        # replace this branch before any production-like deployment.
        now = datetime.now(UTC)
        plan.tier = BillingTier.pro
        plan.status = BillingPlanStatus.active
        plan.started_at = now
        plan.expires_at = now + timedelta(days=365)
        plan.original_transaction_id = transaction_id
        plan.source = platform

        self.db.add(plan)
        await self.db.flush()

        return (True, plan)

    async def can_add_student(
        self,
        user_id: str,
        current_student_count: int,
    ) -> tuple[bool, str]:
        """Check if user can add another student (BillingGuard logic).

        Free tier: max 5 students
        Pro/Studio: unlimited

        Returns:
            Tuple of (allowed: bool, action: str)
            action is "ok" or "start_trial" recommendation
        """
        plan = await self.get_active_plan(user_id)

        # Check tier
        if plan.tier in (BillingTier.pro, BillingTier.studio):
            return (True, "ok")

        # Free tier
        if current_student_count < 5:
            return (True, "ok")

        # At limit, suggest trial
        return (False, "start_trial")

    async def cancel_plan(self, user_id: str) -> None:
        """Mark the current app billing plan as cancelled."""
        plan = await self.get_active_plan(user_id)
        plan.status = BillingPlanStatus.cancelled
        self.db.add(plan)
        await self.db.flush()

    async def list_receipts(self, user_id: str) -> list[IapReceiptResponse]:
        """List IAP receipt audit rows for the user."""
        rows = (
            await self.db.scalars(
                select(IapReceipt)
                .where(IapReceipt.user_id == user_id)
                .order_by(IapReceipt.created_at.desc(), IapReceipt.id.desc())
            )
        ).all()
        return [IapReceiptResponse.model_validate(row) for row in rows]
