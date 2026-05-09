"""Teacher referral API routes."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.referral import TeacherReferral
from app.models.teacher import Teacher
from app.models.user import User
from app.schemas.common import SuccessResponse
from app.services.referral_service import ReferralService

router = APIRouter()


class ReferralCodeResponse:
    """Schema for referral code response."""

    code: str

    def __init__(self, code: str):
        self.code = code


class ReferralStatsResponse:
    """Schema for referral statistics response."""

    total_referrals: int
    completed_referrals: int
    rewarded_count: int

    def __init__(self, total: int, completed: int, rewarded: int):
        self.total_referrals = total
        self.completed_referrals = completed
        self.rewarded_count = rewarded


class ApplyReferralRequest:
    """Schema for applying a referral code."""

    code: str


class ReferralHistoryItem:
    """Schema for referral history item."""

    id: str
    code: str
    referred_teacher_id: str | None
    status: str
    reward_type: str | None
    rewarded_at: str | None
    created_at: str


@router.get(
    "/my-code",
    status_code=status.HTTP_200_OK,
    summary="Get or create my referral code",
)
async def get_my_referral_code(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Get the current teacher's referral code, creating one if it doesn't exist."""
    service = ReferralService(db)
    code = await service.get_or_create_referral_code(current_user.id)
    return {"code": code}


@router.get(
    "/stats",
    status_code=status.HTTP_200_OK,
    summary="Get my referral statistics",
)
async def get_referral_stats(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Get referral statistics for the current teacher."""
    service = ReferralService(db)
    stats = await service.get_referral_stats(current_user.id)
    return stats


@router.post(
    "/apply",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Apply a referral code to my account",
)
async def apply_referral_code(
    request: dict,
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SuccessResponse:
    """Apply a referral code during teacher registration or later.

    Request body:
    {
        "code": "ABCD1234"
    }
    """
    code = request.get("code")
    if not code or not isinstance(code, str):
        return SuccessResponse(message="Invalid referral code format", success=False)

    service = ReferralService(db)
    await service.apply_referral_code(current_user.id, code.strip().upper())

    # Check and apply reward to referrer
    referral = await db.scalar(
        select(TeacherReferral).where(TeacherReferral.referral_code == code.strip().upper())
    )
    if referral:
        reward = await service.check_and_reward(referral.referrer_id)

    return SuccessResponse(message="Referral code applied successfully")


@router.get(
    "/history",
    status_code=status.HTTP_200_OK,
    summary="Get my referral history",
)
async def get_referral_history(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Get the referral history for the current teacher.

    Returns both outbound referrals (codes I generated) and rewards earned.
    """
    referrals = await db.scalars(
        select(TeacherReferral)
        .where(TeacherReferral.referrer_id == current_user.id)
        .order_by(TeacherReferral.created_at.desc())
    )

    history = [
        {
            "id": r.id,
            "code": r.referral_code,
            "referred_teacher_id": r.referred_teacher_id,
            "status": r.status,
            "reward_type": r.reward_type,
            "rewarded_at": r.rewarded_at.isoformat() if r.rewarded_at else None,
            "created_at": r.created_at.isoformat(),
        }
        for r in referrals
    ]

    return {"history": history, "total": len(history)}
