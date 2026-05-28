"""Student summary public sharing endpoint (no authentication required)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.lesson import Lesson, LessonStatus
from app.models.share_token import ShareToken
from app.models.student import Student
from app.schemas.share import LessonSummaryItem, StudentSummaryResponse
from app.services.share_token_service import ShareTokenService

router = APIRouter()

RECENT_LESSONS_LIMIT = 10
NOTES_EXCERPT_LIMIT = 100
STUDENT_SUMMARY_SCOPE = "student_summary"


def _mask_student_name(name: str) -> str:
    """Mask student name to show only first and last character.

    Examples:
        "김철길" -> "김*길"
        "John"  -> "J**n"
    """
    if not name or len(name) < 2:
        return "***"
    if len(name) == 2:
        return name[0] + "*"
    return name[0] + "*" * (len(name) - 2) + name[-1]


def _build_notes_excerpt(lesson: Lesson) -> str:
    raw = lesson.feedback or lesson.student_note or ""
    if not raw:
        return "(No notes)"
    if len(raw) <= NOTES_EXCERPT_LIMIT:
        return raw
    return raw[:NOTES_EXCERPT_LIMIT].rstrip() + "..."


@router.get(
    "/student/{token}/summary",
    response_model=StudentSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student lesson summary by share token",
)
async def get_student_summary(
    token: Annotated[str, Path(..., description="Share token for accessing summary")],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> StudentSummaryResponse:
    """Get a student's lesson summary using a share token.

    The share token must be valid (not expired) and scoped to "student_summary".

    Raises:
        HTTPException: 404 if token invalid, 410 if expired, 403 if scope mismatch.
    """
    service = ShareTokenService(db)
    share_token = await service.resolve_token(token)

    if share_token is None:
        # resolve_token returned None: either the token does not exist or it
        # has expired. Distinguish the two so the client can render a clear
        # error (404 vs 410).
        existing = await db.scalar(
            select(ShareToken).where(ShareToken.token == token),
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_410_GONE,
                detail="Token has expired",
            )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found or invalid",
        )

    if share_token.scope != STUDENT_SUMMARY_SCOPE:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token scope does not permit this operation",
        )

    student = await db.scalar(
        select(Student).where(Student.id == share_token.target_id),
    )
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    recent_lessons_result = await db.scalars(
        select(Lesson)
        .where(
            Lesson.student_id == student.id,
            Lesson.status == LessonStatus.completed,
        )
        .order_by(Lesson.date.desc())
        .limit(RECENT_LESSONS_LIMIT),
    )
    lessons = list(recent_lessons_result)

    total_lesson_count = await db.scalar(
        select(func.count()).select_from(Lesson).where(Lesson.student_id == student.id),
    )

    recent_lessons = [
        LessonSummaryItem(
            date=lesson.date.strftime("%Y-%m-%d"),
            status=lesson.status.value,
            duration_minutes=lesson.duration or 0,
            notes_excerpt=_build_notes_excerpt(lesson),
        )
        for lesson in lessons
    ]

    return StudentSummaryResponse(
        student_name=_mask_student_name(student.name),
        instrument=student.instrument,
        level=student.level.value,
        lesson_count_total=int(total_lesson_count or 0),
        recent_lessons=recent_lessons,
        generated_at=datetime.now(UTC),
    )
