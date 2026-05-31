"""Tests for push notifications sent from lesson lifecycle events."""

from datetime import date

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


@pytest.mark.asyncio
async def test_create_lesson_notifies_student(
    db_session: AsyncSession,
    create_test_user,
):
    """Creating a lesson sends a lessonBooked notification to the student's user account."""
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.services.lesson_service import LessonService
    from app.schemas.lesson import LessonCreate

    # Arrange: teacher user + teacher profile
    teacher_user = await create_test_user(user_id="t-notif-1", role="teacher", name="Teacher")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "t-notif-1"))

    # Student user + student record linked to teacher
    student_user = await create_test_user(
        user_id="s-notif-1", role="student", name="Student", email="s@test.com"
    )
    student = Student(
        id="student-notif-1",
        teacher_id=teacher.id,
        user_id=student_user.id,
        name="Student",
    )
    db_session.add(student)
    await db_session.flush()

    # Act: create a lesson
    service = LessonService(db_session)
    lesson_data = LessonCreate(
        student_id="student-notif-1",
        date="2026-06-01",
        start_time="10:00",
        duration=60,
    )
    lesson = await service.create(lesson_data, teacher_user)

    # Assert: notification record created for student
    notif = await db_session.scalar(
        select(Notification).where(
            Notification.user_id == student_user.id,
            Notification.type == "lessonBooked",
        )
    )
    assert notif is not None, "lessonBooked notification should be created for the student"
    assert "2026-06-01" in notif.body
    assert notif.action_url == f"/lessons/{lesson.id}"


@pytest.mark.asyncio
async def test_create_lesson_no_notification_when_student_has_no_user(
    db_session: AsyncSession,
    create_test_user,
):
    """Creating a lesson for a student without a linked user account does not raise an error."""
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.services.lesson_service import LessonService
    from app.schemas.lesson import LessonCreate

    teacher_user = await create_test_user(user_id="t-notif-2", role="teacher", name="Teacher2")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "t-notif-2"))

    # Student without user_id (offline student)
    student = Student(
        id="student-notif-2",
        teacher_id=teacher.id,
        user_id=None,
        name="Offline Student",
    )
    db_session.add(student)
    await db_session.flush()

    service = LessonService(db_session)
    lesson_data = LessonCreate(
        student_id="student-notif-2",
        date="2026-06-02",
        start_time="11:00",
        duration=60,
    )
    # Should not raise
    lesson = await service.create(lesson_data, teacher_user)
    assert lesson is not None

    # No notification created
    count = await db_session.scalar(
        select(Notification).where(Notification.user_id.is_(None))
    )
    assert count is None


@pytest.mark.asyncio
async def test_update_feedback_notifies_student(
    db_session: AsyncSession,
    create_test_user,
):
    """Writing feedback on a lesson sends a lessonNoteShared notification to the student."""
    from app.models.lesson import Lesson
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.services.lesson_service import LessonService
    from app.schemas.lesson import LessonFeedbackUpdate

    teacher_user = await create_test_user(user_id="t-notif-3", role="teacher", name="Teacher3")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "t-notif-3"))

    student_user = await create_test_user(
        user_id="s-notif-3", role="student", name="Student3", email="s3@test.com"
    )
    student = Student(
        id="student-notif-3",
        teacher_id=teacher.id,
        user_id=student_user.id,
        name="Student3",
    )
    db_session.add(student)
    await db_session.flush()

    lesson = Lesson(
        id="lesson-notif-3",
        teacher_id=teacher.id,
        student_id=student.id,
        student_name="Student3",
        instrument="piano",
        date=date(2026, 6, 3),
        start_time="10:00",
        duration=60,
    )
    db_session.add(lesson)
    await db_session.flush()

    # Act: update feedback
    service = LessonService(db_session)
    feedback_data = LessonFeedbackUpdate(feedback="Good job!", practice_tips="Practice scales.")
    await service.update_feedback("lesson-notif-3", feedback_data, teacher_user)

    # Assert
    notif = await db_session.scalar(
        select(Notification).where(
            Notification.user_id == student_user.id,
            Notification.type == "lessonNoteShared",
        )
    )
    assert notif is not None, "lessonNoteShared notification should be created for the student"
    assert "2026-06-03" in notif.body
    assert notif.action_url == "/lessons/lesson-notif-3"
