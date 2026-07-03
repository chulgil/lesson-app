"""Tests for counterparty notifications on lesson cancel / reschedule (#1131).

Covers the event-driven portion of the '레슨 알림 4종' shell audit: when a
teacher cancels or reschedules a lesson, the counterparty (the student) receives
a notification, while the actor does not. No-op edits send nothing.
"""

from datetime import date

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


async def _make_teacher_student_lesson(db_session, create_test_user, *, suffix):
    """Create a teacher user + profile, a linked student user + record, and a lesson."""
    from app.models.lesson import Lesson
    from app.models.student import Student
    from app.models.teacher import Teacher

    teacher_user = await create_test_user(user_id=f"t-cr-{suffix}", role="teacher", name=f"Teacher {suffix}")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == f"t-cr-{suffix}"))

    student_user = await create_test_user(
        user_id=f"s-cr-{suffix}", role="student", name=f"Student {suffix}", email=f"s-cr-{suffix}@test.com"
    )
    student = Student(
        id=f"student-cr-{suffix}",
        teacher_id=teacher.id,
        user_id=student_user.id,
        name=f"Student {suffix}",
    )
    db_session.add(student)
    await db_session.flush()

    lesson = Lesson(
        id=f"lesson-cr-{suffix}",
        teacher_id=teacher.id,
        student_id=student.id,
        student_name=f"Student {suffix}",
        instrument="piano",
        date=date(2026, 6, 10),
        start_time="10:00",
        duration=60,
    )
    db_session.add(lesson)
    await db_session.flush()
    return teacher_user, teacher, student_user, lesson


@pytest.mark.asyncio
async def test_teacher_cancel_notifies_student_only(
    db_session: AsyncSession,
    create_test_user,
):
    """Teacher cancelling a lesson sends 1 lessonCancelled notif to the student, 0 to the teacher."""
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="cancel"
    )

    service = LessonService(db_session)
    await service.update_status(lesson.id, "cancelledByTeacher", teacher_user)

    student_notifs = (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == student_user.id,
                Notification.type == "lessonCancelled",
            )
        )
    ).all()
    assert len(student_notifs) == 1, "student should receive exactly one lessonCancelled notification"
    assert student_notifs[0].action_url == f"/lessons/{lesson.id}"

    teacher_notifs = (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == teacher_user.id,
                Notification.type == "lessonCancelled",
            )
        )
    ).all()
    assert len(teacher_notifs) == 0, "actor (teacher) should not receive a cancellation notification"


@pytest.mark.asyncio
async def test_reschedule_notifies_counterparty(
    db_session: AsyncSession,
    create_test_user,
):
    """Changing lesson date/time sends 1 lessonRescheduled notif to the counterparty (student)."""
    from app.schemas.lesson import LessonUpdate
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="resched"
    )

    service = LessonService(db_session)
    await service.update(
        lesson.id,
        LessonUpdate(date=date(2026, 6, 12), start_time="14:00"),
        teacher_user,
    )

    notifs = (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == student_user.id,
                Notification.type == "lessonRescheduled",
            )
        )
    ).all()
    assert len(notifs) == 1, "student should receive exactly one lessonRescheduled notification"
    assert notifs[0].action_url == f"/lessons/{lesson.id}"


@pytest.mark.asyncio
async def test_update_without_datetime_change_sends_nothing(
    db_session: AsyncSession,
    create_test_user,
):
    """Updating a lesson with no date/time change sends 0 notifications."""
    from app.schemas.lesson import LessonUpdate
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="noop"
    )

    service = LessonService(db_session)
    # Same date/time as the existing lesson; only a benign field changes.
    await service.update(
        lesson.id,
        LessonUpdate(date=date(2026, 6, 10), start_time="10:00", instrument="violin"),
        teacher_user,
    )

    notifs = (await db_session.scalars(select(Notification).where(Notification.type == "lessonRescheduled"))).all()
    assert len(notifs) == 0, "no-op date/time edit must not send a reschedule notification"
