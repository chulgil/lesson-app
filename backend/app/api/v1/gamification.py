"""Gamification endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db
from app.models.user import User
from app.schemas.gamification import (
    AwardPointsRequest,
    BadgeResponse,
    PointHistoryResponse,
    StudentGamificationResponse,
)
from app.services.gamification_service import GamificationService

router = APIRouter()


@router.get(
    "/{student_id}",
    response_model=StudentGamificationResponse,
    summary="Get student gamification",
)
async def get_student_gamification(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> StudentGamificationResponse:
    service = GamificationService(db)
    data = await service.get_student_gamification(student_id)
    return StudentGamificationResponse.model_validate(data)


@router.post(
    "/points",
    response_model=PointHistoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Award points (teacher only)",
)
async def award_points(
    body: AwardPointsRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> PointHistoryResponse:
    service = GamificationService(db)
    result: PointHistoryResponse = await service.award_points(
        student_id=body.student_id,
        points=body.points,
        point_type=body.type,
        description=body.description,
    )
    return result
