"""Analytics endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import (  # noqa: F401  ruff `from __future__ import annotations` 에서 Annotated[..., Query(...)] 사용 미감지.
    APIRouter,
    Depends,
    Query,
    status,
)
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
    # 0625 §20 N17 — 경계 검증: YYYY-MM(1900~2099, 01~12)만 허용 → malformed 입력은 422 (500 방지)
    # Pydantic v2(Rust regex)는 look-around 미지원 → 연도 범위로 0000 등 무효 datetime 차단
    month: Annotated[str, Query(pattern=r"^(19|20)\d{2}-(0[1-9]|1[0-2])$")],
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
    period_days: Annotated[int, Query(ge=1, le=365)] = 30,
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
