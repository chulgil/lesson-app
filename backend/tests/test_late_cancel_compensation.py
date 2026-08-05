"""Tests for late student-cancel compensation notifications (#1167).

When a lesson transitions to ``cancelledByStudentLate`` the student receives a
``compensationApplied`` notification (spec notification_system.md §4). The
compensation policy is resolved from the lesson's academy subscription when the
subscription is academy-owned, else from the teacher-default values that match
the ``CancellationDefaults`` FE entity defaults (enabled). On-time cancellations
and disabled policies produce nothing. Academy owners are notified only when the
academy subscription enables ``notify_owner_on_late_cancel``.
"""

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification

_DEFAULT_COMPENSATION_MESSAGE = "지각 취소로 다음 레슨에 보너스 연습시간을 제공해 드립니다."


async def _make_teacher_student_lesson(db_session, create_test_user, *, suffix, subscription_id=None):
    """Create a teacher user + profile, a linked student user + record, and a lesson."""
    from app.models.lesson import Lesson
    from app.models.student import Student
    from app.models.teacher import Teacher

    teacher_user = await create_test_user(user_id=f"t-lc-{suffix}", role="teacher", name=f"Teacher {suffix}")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == f"t-lc-{suffix}"))

    student_user = await create_test_user(
        user_id=f"s-lc-{suffix}", role="student", name=f"Student {suffix}", email=f"s-lc-{suffix}@test.com"
    )
    student = Student(
        id=f"student-lc-{suffix}",
        teacher_id=teacher.id,
        user_id=student_user.id,
        name=f"Student {suffix}",
    )
    db_session.add(student)
    await db_session.flush()

    lesson = Lesson(
        id=f"lesson-lc-{suffix}",
        teacher_id=teacher.id,
        student_id=student.id,
        student_name=f"Student {suffix}",
        instrument="piano",
        date=date(2026, 6, 10),
        start_time="10:00",
        duration=60,
        subscription_id=subscription_id,
    )
    db_session.add(lesson)
    await db_session.flush()
    return teacher_user, teacher, student_user, lesson


async def _make_academy_subscription(
    db_session,
    create_test_user,
    *,
    suffix,
    subscription_id,
    enabled=True,
    include_text=True,
    message=None,
    notify_owner=False,
):
    """Create an academy + owner user + academy_subscription policy row.

    FK enforcement is off in the SQLite test DB, so the RESTRICT columns that are
    irrelevant to policy resolution use placeholder ids.
    """
    from app.models.academy import Academy
    from app.models.academy_billing import AcademySubscription

    owner_user = await create_test_user(
        user_id=f"owner-lc-{suffix}", role="teacher", name=f"Owner {suffix}", email=f"owner-lc-{suffix}@test.com"
    )
    academy = Academy(
        id=f"acad-lc-{suffix}", slug=f"acad-lc-{suffix}", name=f"Academy {suffix}", owner_user_id=owner_user.id
    )
    db_session.add(academy)
    await db_session.flush()

    academy_sub = AcademySubscription(
        id=f"acadsub-lc-{suffix}",
        academy_id=academy.id,
        subscription_id=subscription_id,
        academy_student_id=f"acadstu-lc-{suffix}",
        teacher_member_id=f"acadmem-lc-{suffix}",
        student_compensation_extra_minutes_enabled=enabled,
        include_extra_minutes_text_on_late_cancel=include_text,
        student_compensation_extra_minutes_message=message,
        notify_owner_on_late_cancel=notify_owner,
        created_at=datetime.now(UTC),
    )
    db_session.add(academy_sub)
    await db_session.flush()
    return owner_user, academy


async def _compensation_notifs(db_session, user_id):
    return (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.type == "compensationApplied",
            )
        )
    ).all()


@pytest.mark.asyncio
async def test_late_student_cancel_sends_compensation_to_student(db_session: AsyncSession, create_test_user):
    """Late student cancel (non-academy) sends 1 compensationApplied with the default message."""
    from app.services.lesson_service import LessonService

    teacher_user, _, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="basic"
    )

    service = LessonService(db_session)
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher_user)

    notifs = await _compensation_notifs(db_session, student_user.id)
    assert len(notifs) == 1, "student should receive exactly one compensationApplied notification"
    assert notifs[0].body == _DEFAULT_COMPENSATION_MESSAGE
    assert notifs[0].action_url == f"/lessons/{lesson.id}"


@pytest.mark.asyncio
async def test_on_time_student_cancel_sends_no_compensation(db_session: AsyncSession, create_test_user):
    """On-time student cancel (cancelledByStudentAdvance) sends 0 compensation notifications."""
    from app.models.user import User
    from app.services.lesson_service import LessonService

    _, _, student_user, lesson = await _make_teacher_student_lesson(db_session, create_test_user, suffix="ontime")

    service = LessonService(db_session)
    teacher_actor = await db_session.get(User, "t-lc-ontime")
    await service.update_status(lesson.id, "cancelledByStudentAdvance", teacher_actor)

    notifs = await _compensation_notifs(db_session, student_user.id)
    assert len(notifs) == 0, "on-time cancel must not produce a compensation notification"


@pytest.mark.asyncio
async def test_academy_notify_owner_on_late_cancel(db_session: AsyncSession, create_test_user):
    """Academy subscription with notify_owner=True notifies the owner exactly once."""
    from app.models.user import User
    from app.services.lesson_service import LessonService

    _, _, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="ownon", subscription_id="sub-ownon"
    )
    owner_user, _ = await _make_academy_subscription(
        db_session, create_test_user, suffix="ownon", subscription_id="sub-ownon", notify_owner=True
    )

    service = LessonService(db_session)
    teacher_actor = await db_session.get(User, "t-lc-ownon")
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher_actor)

    owner_notifs = (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == owner_user.id,
                Notification.type == "lessonCancelled",
            )
        )
    ).all()
    assert len(owner_notifs) == 1, "academy owner should receive exactly one late-cancel notification"

    # Student still receives compensation.
    assert len(await _compensation_notifs(db_session, student_user.id)) == 1


@pytest.mark.asyncio
async def test_non_academy_late_cancel_does_not_notify_owner(db_session: AsyncSession, create_test_user):
    """Non-academy late cancel sends no owner notification (notify_owner default False)."""
    from app.models.user import User
    from app.services.lesson_service import LessonService

    # A bystander user who must never receive an owner notification.
    bystander = await create_test_user(user_id="bystander-lc", role="teacher", name="Bystander", email="by-lc@test.com")

    _, _, _, lesson = await _make_teacher_student_lesson(db_session, create_test_user, suffix="noacad")

    service = LessonService(db_session)
    teacher_actor = await db_session.get(User, "t-lc-noacad")
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher_actor)

    bystander_notifs = (
        await db_session.scalars(select(Notification).where(Notification.user_id == bystander.id))
    ).all()
    assert len(bystander_notifs) == 0, "no owner notification without an academy subscription"


@pytest.mark.asyncio
async def test_academy_compensation_disabled_sends_nothing(db_session: AsyncSession, create_test_user):
    """Academy subscription with compensation disabled produces 0 compensation notifications."""
    from app.models.user import User
    from app.services.lesson_service import LessonService

    _, _, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="off", subscription_id="sub-off"
    )
    await _make_academy_subscription(
        db_session, create_test_user, suffix="off", subscription_id="sub-off", enabled=False
    )

    service = LessonService(db_session)
    teacher_actor = await db_session.get(User, "t-lc-off")
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher_actor)

    assert len(await _compensation_notifs(db_session, student_user.id)) == 0


@pytest.mark.asyncio
async def test_academy_custom_message_used(db_session: AsyncSession, create_test_user):
    """Academy custom compensation message is used as the notification body."""
    from app.models.user import User
    from app.services.lesson_service import LessonService

    custom = "10분 보너스 연습시간을 제공해 드립니다."
    _, _, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="msg", subscription_id="sub-msg"
    )
    await _make_academy_subscription(
        db_session, create_test_user, suffix="msg", subscription_id="sub-msg", message=custom
    )

    service = LessonService(db_session)
    teacher_actor = await db_session.get(User, "t-lc-msg")
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher_actor)

    notifs = await _compensation_notifs(db_session, student_user.id)
    assert len(notifs) == 1
    assert notifs[0].body == custom
