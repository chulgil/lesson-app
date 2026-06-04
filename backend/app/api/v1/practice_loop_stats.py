"""Practice Loop Stats endpoints — #512.

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4/§5.

Two router objects exported:
- ``student_router`` — student-side sync POST.
- ``teacher_router`` — teacher-side reads (per-student + dashboard summary).

The student sync is intentionally idempotent (see service) so the FE can
flush an offline queue without coordination.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_student, get_current_teacher, get_db
from app.models.student import Student
from app.models.user import User
from app.schemas.practice_loop_stats import (
    PracticeLoopStatsListResponse,
    PracticeLoopStatsSummaryResponse,
    PracticeLoopStatsSyncRequest,
    PracticeLoopStatsSyncResult,
    StatsWindow,
)
from app.services.practice_loop_stats_service import PracticeLoopStatsService
from app.services.student_id_resolver import resolve_student_id
from app.services.teacher_id_resolver import resolve_teacher_id

student_router = APIRouter()
teacher_router = APIRouter()


# ---------------------------------------------------------------------------
# Student sync — POST /api/v1/students/me/practice-loop-stats/sync
# ---------------------------------------------------------------------------


@student_router.post(
    "/sync",
    response_model=PracticeLoopStatsSyncResult,
    status_code=status.HTTP_200_OK,
    summary="Upload aggregated repeat counts for the signed-in student",
)
async def sync_my_loop_stats(
    body: PracticeLoopStatsSyncRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> PracticeLoopStatsSyncResult:
    """Spec §5 — idempotent sync. Empty payload returns zeros (no-op)."""
    student_id = await resolve_student_id(db, current_user.id)
    student_row = await db.scalar(select(Student).where(Student.id == student_id))
    if student_row is None or not student_row.teacher_id:
        # No linked teacher yet — drop the sync silently (no-op for parent /
        # un-paired flows). Idempotent contract preserved.
        return PracticeLoopStatsSyncResult()

    service = PracticeLoopStatsService(db)
    return await service.sync(
        student_id=student_id,
        teacher_id=student_row.teacher_id,
        entries=body.entries,
    )


# ---------------------------------------------------------------------------
# Teacher reads — /api/v1/teachers/me/practice-loop-stats/...
# ---------------------------------------------------------------------------


@teacher_router.get(
    "/summary",
    response_model=PracticeLoopStatsSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Per-teacher per-student roll-up for the dashboard entry card",
)
async def get_loop_stats_summary(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    window: Annotated[StatsWindow, Query(description="Time window")] = StatsWindow.weekly,
) -> PracticeLoopStatsSummaryResponse:
    """Spec §4.4 — dashboard summary across all linked students."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = PracticeLoopStatsService(db)
    return await service.summary_for_teacher(teacher_id=teacher_id, window=window)


@teacher_router.get(
    "/students/{student_id}",
    response_model=PracticeLoopStatsListResponse,
    status_code=status.HTTP_200_OK,
    summary="Per-section repeat counts for one student",
)
async def get_loop_stats_for_student(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    window: Annotated[StatsWindow, Query(description="Time window")] = StatsWindow.weekly,
) -> PracticeLoopStatsListResponse:
    """Spec §4 — per-student per-section drill-down.

    Authorisation: the teacher must own the student record (``Student.teacher_id``).
    """
    teacher_id = await resolve_teacher_id(db, current_user.id)

    student = await db.scalar(select(Student).where(Student.id == student_id))
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )
    if student.teacher_id != teacher_id:
        # Spec §5 privacy — a teacher may only see their own students' stats.
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorised for this student",
        )

    service = PracticeLoopStatsService(db)
    return await service.list_for_student(
        teacher_id=teacher_id,
        student_id=student_id,
        window=window,
    )
