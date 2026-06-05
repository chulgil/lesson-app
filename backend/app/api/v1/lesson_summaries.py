"""Lesson summary sharing endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_teacher_context
from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.share import LessonSummaryShareRequest, LessonSummaryShareResponse
from app.services.share_token_service import ShareTokenService

# AC-M2 권한 매트릭스: 학원장 모드 JWT → 403 (레슨 요약 공유는 강사 권한).
router = APIRouter(dependencies=[Depends(require_teacher_context)])


@router.post(
    "/{lesson_id}/share",
    response_model=LessonSummaryShareResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create lesson summary share token",
)
async def create_lesson_summary_share(
    lesson_id: str,
    body: LessonSummaryShareRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> LessonSummaryShareResponse:
    """Issue a public share token for a teacher-owned lesson summary."""
    service = ShareTokenService(db)
    return await service.issue_lesson_summary_share(
        lesson_id=lesson_id,
        expires_in_hours=body.expires_in_hours,
        current_user=current_user,
    )
