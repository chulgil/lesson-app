"""Analytics endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.analytics import TeacherMonthlyStatsResponse
from app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.get("/monthly-stats", response_model=TeacherMonthlyStatsResponse)
async def get_monthly_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    month: str,
) -> TeacherMonthlyStatsResponse:
    service = AnalyticsService(db)
    return await service.get_monthly_stats(current_user, month)
