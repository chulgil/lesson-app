"""Lesson summary sharing endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.lesson_summary_share import LessonSummaryShareCreate, LessonSummaryShareResponse
from app.services.lesson_summary_share_service import LessonSummaryShareService

router = APIRouter()


@router.post(
    "/{lesson_id}/share",
    response_model=LessonSummaryShareResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="create_lesson_summary_share",
)
async def create_lesson_summary_share(
    lesson_id: str,
    body: LessonSummaryShareCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonSummaryShareResponse:
    service = LessonSummaryShareService(db)
    return await service.create_share_token(
        lesson_id=lesson_id,
        current_user=current_user,
        expires_in_hours=body.expires_in_hours,
    )
