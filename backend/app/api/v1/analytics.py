"""Analytics endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.analytics import StudentProgressResponse, TeacherMonthlyStatsResponse
from app.services.analytics_service import AnalyticsService
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


@router.get(
    "/monthly-stats",
    response_model=TeacherMonthlyStatsResponse,
    status_code=status.HTTP_200_OK,
)
async def get_monthly_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    month: str,
) -> TeacherMonthlyStatsResponse:
    service = AnalyticsService(db)
    return await service.get_monthly_stats(current_user, month)


@router.get(
    "/students/{student_id}/progress",
    response_model=StudentProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student attendance and practice progress",
)
async def get_student_progress(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    period_days: int = 30,
) -> StudentProgressResponse:
    """Return attendance rate, practice stats, and calendar for a student.

    Only the student's teacher can access this endpoint.
    """
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = AnalyticsService(db)
    return await service.get_student_progress(
        teacher_id=teacher_id,
        student_id=student_id,
        period_days=period_days,
    )
