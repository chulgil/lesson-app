"""Teacher referral API routes."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.common import SuccessResponse
from app.schemas.referral import (
    ApplyReferralRequest,
    ReferralCodeResponse,
    ReferralHistoryResponse,
    ReferralStatsResponse,
)
from app.services.referral_service import ReferralService

router = APIRouter()


@router.get(
    "/my-code",
    response_model=ReferralCodeResponse,
    status_code=status.HTTP_200_OK,
    summary="Get or create my referral code",
)
async def get_my_referral_code(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralCodeResponse:
    """Get the current teacher's referral code, creating one if it doesn't exist."""
    service = ReferralService(db)
    code = await service.get_or_create_referral_code(current_user.id)
    return ReferralCodeResponse(code=code)


@router.get(
    "/stats",
    response_model=ReferralStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my referral statistics",
)
async def get_referral_stats(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralStatsResponse:
    """Get referral statistics for the current teacher."""
    service = ReferralService(db)
    stats = await service.get_referral_stats(current_user.id)
    return ReferralStatsResponse(**stats)


@router.post(
    "/apply",
    response_model=SuccessResponse,
    status_code=status.HTTP_200_OK,
    summary="Apply a referral code to my account",
)
async def apply_referral_code(
    request: ApplyReferralRequest,
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SuccessResponse:
    """Apply a referral code during teacher registration or later.

    Request body:
    {
        "code": "ABCD1234"
    }
    """
    code = request.code
    if not code:
        return SuccessResponse(message="Invalid referral code format", success=False)

    service = ReferralService(db)
    await service.apply_referral_code_and_reward(current_user.id, code)

    return SuccessResponse(message="Referral code applied successfully")


@router.get(
    "/history",
    response_model=ReferralHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my referral history",
)
async def get_referral_history(
    current_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReferralHistoryResponse:
    """Get the referral history for the current teacher.

    Returns both outbound referrals (codes I generated) and rewards earned.
    """
    service = ReferralService(db)
    return ReferralHistoryResponse(**await service.get_referral_history(current_user.id))
