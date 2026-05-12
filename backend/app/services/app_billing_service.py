"""App billing domain service."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_billing import AppBillingPlan, AppBillingReceipt
from app.schemas.app_billing import (
    BillingStatusResponse,
    ProductInfo,
    TrialStartResponse,
    VerifyPurchaseRequest,
    VerifyPurchaseResponse,
)

PLAN_FEATURES: dict[str, dict[str, bool]] = {
    "free": {
        "ai_notes": False,
        "recording": False,
        "parent_portal": False,
        "practice_stats": False,
        "multi_teacher": False,
        "custom_branding": False,
        "analytics_report": False,
    },
    "trial_pro": {
        "ai_notes": True,
        "recording": True,
        "parent_portal": True,
        "practice_stats": True,
        "multi_teacher": False,
        "custom_branding": False,
        "analytics_report": False,
    },
    "pro": {
        "ai_notes": True,
        "recording": True,
        "parent_portal": True,
        "practice_stats": True,
        "multi_teacher": False,
        "custom_branding": False,
        "analytics_report": False,
    },
    "studio": {
        "ai_notes": True,
        "recording": True,
        "parent_portal": True,
        "practice_stats": True,
        "multi_teacher": True,
        "custom_branding": True,
        "analytics_report": True,
    },
    "lifetime": {
        "ai_notes": True,
        "recording": True,
        "parent_portal": True,
        "practice_stats": True,
        "multi_teacher": False,
        "custom_branding": False,
        "analytics_report": False,
    },
}

STUDENT_LIMITS: dict[str, int | None] = {
    "free": 5,
    "trial_pro": None,
    "pro": None,
    "studio": None,
    "lifetime": None,
}

PRODUCT_TO_PLAN: dict[str, str] = {
    "pro_monthly": "pro",
    "pro_yearly": "pro",
    "studio_monthly": "studio",
    "lifetime": "lifetime",
}

PRODUCT_DURATIONS: dict[str, timedelta] = {
    "pro_monthly": timedelta(days=30),
    "pro_yearly": timedelta(days=365),
    "studio_monthly": timedelta(days=30),
}


class AppBillingService:
    """Handle app billing plan, trial, and receipt state."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_status(self, teacher_id: str) -> BillingStatusResponse:
        """Return current billing plan status and create free plan if missing."""
        plan = await self._get_or_create_plan(teacher_id)
        await self.db.commit()
        return self._build_status(plan)

    async def start_trial(self, teacher_id: str) -> TrialStartResponse:
        """Start a 14-day Pro trial. Only once per teacher."""
        plan = await self._get_or_create_plan(teacher_id)

        if plan.plan != "free":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trial is only available for free plan users",
            )

        existing_trial = await self.db.execute(
            select(AppBillingPlan).where(
                AppBillingPlan.teacher_id == teacher_id,
                AppBillingPlan.plan == "trial_pro",
            )
        )
        if existing_trial.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trial has already been used",
            )

        trial_ends = datetime.now(UTC) + timedelta(days=14)
        plan.plan = "trial_pro"
        plan.trial_ends_at = trial_ends
        await self.db.commit()
        return TrialStartResponse(plan="trial_pro", trial_ends_at=trial_ends)

    async def verify_purchase(
        self,
        teacher_id: str,
        body: VerifyPurchaseRequest,
    ) -> VerifyPurchaseResponse:
        """Verify store receipt and activate the corresponding plan."""
        target_plan = PRODUCT_TO_PLAN.get(body.product_id)
        if target_plan is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unknown product: {body.product_id}",
            )

        plan = await self._get_or_create_plan(teacher_id)
        receipt = AppBillingReceipt(
            id=str(uuid4()),
            billing_plan_id=plan.id,
            store_platform=body.store_platform,
            transaction_id=body.transaction_id,
            product_id=body.product_id,
            receipt_data=body.receipt_data,
            verification_status="pending",
        )
        self.db.add(receipt)

        receipt.verified_at = datetime.now(UTC)
        receipt.verification_status = "verified"

        expires_at = None
        duration = PRODUCT_DURATIONS.get(body.product_id)
        if duration is not None:
            expires_at = datetime.now(UTC) + duration

        plan.plan = target_plan
        plan.store_platform = body.store_platform
        plan.original_transaction_id = body.transaction_id
        plan.expires_at = expires_at
        plan.trial_ends_at = None
        plan.is_active = True
        plan.cancelled_at = None

        await self.db.commit()
        return VerifyPurchaseResponse(
            plan=target_plan,
            is_active=True,
            expires_at=expires_at,
        )

    async def restore_purchase(self, teacher_id: str) -> BillingStatusResponse:
        """Return current status until store-side restore is implemented."""
        plan = await self._get_or_create_plan(teacher_id)
        return self._build_status(plan)

    @staticmethod
    def list_products() -> list[ProductInfo]:
        """Return available IAP product IDs. Prices come from the store."""
        return [
            ProductInfo(
                product_id="pro_monthly",
                plan="pro",
                description="Pro 월간 구독",
            ),
            ProductInfo(
                product_id="pro_yearly",
                plan="pro",
                description="Pro 연간 구독",
            ),
            ProductInfo(
                product_id="studio_monthly",
                plan="studio",
                description="Studio 월간 구독",
            ),
            ProductInfo(
                product_id="lifetime",
                plan="lifetime",
                description="Lifetime (영구)",
            ),
        ]

    async def _get_or_create_plan(self, teacher_id: str) -> AppBillingPlan:
        result = await self.db.execute(
            select(AppBillingPlan)
            .where(
                AppBillingPlan.teacher_id == teacher_id,
                AppBillingPlan.is_active.is_(True),
            )
            .order_by(AppBillingPlan.created_at.desc())
            .limit(1)
        )
        plan = result.scalar_one_or_none()
        if plan is not None:
            return plan

        plan = AppBillingPlan(
            id=str(uuid4()),
            teacher_id=teacher_id,
            plan="free",
            is_active=True,
        )
        self.db.add(plan)
        await self.db.flush()
        return plan

    def _build_status(self, plan: AppBillingPlan) -> BillingStatusResponse:
        return BillingStatusResponse(
            plan=plan.plan,
            is_active=plan.is_active,
            student_limit=STUDENT_LIMITS.get(plan.plan, 5),
            expires_at=plan.expires_at,
            trial_ends_at=plan.trial_ends_at,
            days_remaining=self._days_remaining(plan),
            features=PLAN_FEATURES.get(plan.plan, PLAN_FEATURES["free"]),
        )

    @staticmethod
    def _days_remaining(plan: AppBillingPlan) -> int | None:
        if plan.plan in {"free", "lifetime"}:
            return None

        ref_date = plan.trial_ends_at if plan.plan == "trial_pro" else plan.expires_at
        if ref_date is None:
            return None

        aware_ref = ref_date if ref_date.tzinfo else ref_date.replace(tzinfo=UTC)
        delta = aware_ref - datetime.now(UTC)
        return max(0, delta.days)
