"""App billing API — subscription status, trial, purchase verification (R4)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.app_billing import AppBillingPlan, AppBillingReceipt
from app.models.user import User

router = APIRouter()

# ── Constants ────────────────────────────────────────────────────────────

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


# ── Schemas ──────────────────────────────────────────────────────────────

class BillingStatusResponse(BaseModel):
    plan: str
    is_active: bool
    student_limit: int | None
    expires_at: datetime | None
    trial_ends_at: datetime | None
    days_remaining: int | None
    features: dict[str, bool]


class TrialStartResponse(BaseModel):
    plan: str
    trial_ends_at: datetime


class VerifyPurchaseRequest(BaseModel):
    store_platform: str
    product_id: str
    transaction_id: str
    receipt_data: str


class VerifyPurchaseResponse(BaseModel):
    plan: str
    is_active: bool
    expires_at: datetime | None


class ProductInfo(BaseModel):
    product_id: str
    plan: str
    description: str


# ── Helpers ──────────────────────────────────────────────────────────────

async def _get_or_create_plan(
    db: AsyncSession, teacher_id: str
) -> AppBillingPlan:
    """Get active billing plan for teacher, or create a free plan."""
    result = await db.execute(
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

    new_plan = AppBillingPlan(
        id=str(uuid4()),
        teacher_id=teacher_id,
        plan="free",
        is_active=True,
    )
    db.add(new_plan)
    await db.flush()
    return new_plan


def _days_remaining(plan: AppBillingPlan) -> int | None:
    if plan.plan == "lifetime":
        return None
    if plan.plan == "free":
        return None

    ref_date = plan.trial_ends_at if plan.plan == "trial_pro" else plan.expires_at
    if ref_date is None:
        return None

    # Ensure timezone-aware comparison (SQLite stores naive datetimes)
    aware_ref = ref_date if ref_date.tzinfo else ref_date.replace(tzinfo=UTC)
    delta = aware_ref - datetime.now(UTC)
    return max(0, delta.days)


def _build_status(plan: AppBillingPlan) -> BillingStatusResponse:
    return BillingStatusResponse(
        plan=plan.plan,
        is_active=plan.is_active,
        student_limit=STUDENT_LIMITS.get(plan.plan, 5),
        expires_at=plan.expires_at,
        trial_ends_at=plan.trial_ends_at,
        days_remaining=_days_remaining(plan),
        features=PLAN_FEATURES.get(plan.plan, PLAN_FEATURES["free"]),
    )


# ── Endpoints ────────────────────────────────────────────────────────────

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
    plan = await _get_or_create_plan(db, current_user.id)
    await db.commit()
    return _build_status(plan)


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
    plan = await _get_or_create_plan(db, current_user.id)

    if plan.plan != "free":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Trial is only available for free plan users",
        )

    # Check if teacher already had a trial
    existing_trial = await db.execute(
        select(AppBillingPlan).where(
            AppBillingPlan.teacher_id == current_user.id,
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
    await db.commit()

    return TrialStartResponse(plan="trial_pro", trial_ends_at=trial_ends)


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
    target_plan = PRODUCT_TO_PLAN.get(body.product_id)
    if target_plan is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown product: {body.product_id}",
        )

    plan = await _get_or_create_plan(db, current_user.id)

    # Save receipt
    receipt = AppBillingReceipt(
        id=str(uuid4()),
        billing_plan_id=plan.id,
        store_platform=body.store_platform,
        transaction_id=body.transaction_id,
        product_id=body.product_id,
        receipt_data=body.receipt_data,
        verification_status="pending",
    )
    db.add(receipt)

    # TODO: Real receipt verification with Apple/Google servers
    # For now, trust the receipt (development phase)
    receipt.verified_at = datetime.now(UTC)
    receipt.verification_status = "verified"

    # Activate plan
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

    await db.commit()

    return VerifyPurchaseResponse(
        plan=target_plan,
        is_active=True,
        expires_at=expires_at,
    )


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
    plan = await _get_or_create_plan(db, current_user.id)
    # TODO: Query store for active subscriptions and restore
    # For now, return current status
    return _build_status(plan)


@router.get(
    "/products",
    response_model=list[ProductInfo],
    status_code=status.HTTP_200_OK,
)
async def list_products() -> list[ProductInfo]:
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
