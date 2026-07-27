"""Regression test: award_points must not double-award on an accidental
double-submission (double-tap / retry), mirroring award_badge's idempotent
lookup-before-insert pattern.

Points are not naturally unique the way badges are (the same type/amount is a
legitimate repeat event over time), so the guard is a short recency window
rather than a permanent unique key: an identical (student_id, points, type,
description) submitted again within a few seconds is treated as a duplicate
of the same click, not a new award.
"""

from __future__ import annotations

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def _make_student(db_session: AsyncSession, *, teacher_id: str) -> str:
    from app.models.student import Student

    student = Student(id="student-gami-idem", teacher_id=teacher_id, name="Test Student", instrument="violin")
    db_session.add(student)
    await db_session.flush()
    return student.id


@pytest.mark.asyncio
async def test_duplicate_award_points_call_does_not_double_award(db_session: AsyncSession, create_test_user) -> None:
    from app.models.gamification import GamificationPoint
    from app.services.gamification_service import GamificationService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = f"{teacher.id}-prof"
    student_id = await _make_student(db_session, teacher_id=teacher_id)

    service = GamificationService(db_session)
    first = await service.award_points(
        student_id=student_id,
        points=5,
        point_type="practiceComplete",
        description="연습 보너스",
        current_user=teacher,
    )
    second = await service.award_points(
        student_id=student_id,
        points=5,
        point_type="practiceComplete",
        description="연습 보너스",
        current_user=teacher,
    )

    assert second.id == first.id

    rows = (await db_session.scalars(select(GamificationPoint).where(GamificationPoint.student_id == student_id))).all()
    assert len(rows) == 1


@pytest.mark.asyncio
async def test_different_award_points_calls_both_recorded(db_session: AsyncSession, create_test_user) -> None:
    from app.models.gamification import GamificationPoint
    from app.services.gamification_service import GamificationService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    teacher_id = f"{teacher.id}-prof"
    student_id = await _make_student(db_session, teacher_id=teacher_id)

    service = GamificationService(db_session)
    await service.award_points(
        student_id=student_id,
        points=5,
        point_type="practiceComplete",
        description="연습 보너스 1",
        current_user=teacher,
    )
    await service.award_points(
        student_id=student_id,
        points=10,
        point_type="streakBonus",
        description="연습 보너스 2",
        current_user=teacher,
    )

    rows = (await db_session.scalars(select(GamificationPoint).where(GamificationPoint.student_id == student_id))).all()
    assert len(rows) == 2
