"""Regression test: deleting a Lesson must also remove its LessonPiece and
LessonRecording rows, since neither has a database-level foreign key on
lesson_id (so no ON DELETE CASCADE exists to do this automatically).

Without this, LessonService.delete() left orphaned rows pointing at a
lesson_id that no longer exists.
"""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_delete_lesson_removes_orphaned_pieces_and_recordings(db_session: AsyncSession, create_test_user) -> None:
    from app.models.lesson import Lesson, LessonPiece, LessonRecording
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")

    lesson = Lesson(
        teacher_id="test-user-id-prof",
        student_id="student-delete-cleanup",
        student_name="Student",
        instrument="violin",
        date=date(2026, 5, 1),
        start_time="10:00",
        duration=60,
    )
    db_session.add(lesson)
    await db_session.flush()

    piece = LessonPiece(lesson_id=lesson.id, name="바이올린 협주곡")
    recording = LessonRecording(lesson_id=lesson.id, file_path="/recordings/x.m4a", recorded_at=datetime.now(UTC))
    db_session.add_all([piece, recording])
    await db_session.flush()

    service = LessonService(db_session)
    await service.delete(lesson.id, teacher)

    remaining_pieces = (await db_session.scalars(select(LessonPiece).where(LessonPiece.lesson_id == lesson.id))).all()
    remaining_recordings = (
        await db_session.scalars(select(LessonRecording).where(LessonRecording.lesson_id == lesson.id))
    ).all()
    assert remaining_pieces == []
    assert remaining_recordings == []
