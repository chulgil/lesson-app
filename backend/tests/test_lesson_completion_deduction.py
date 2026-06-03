"""Unified completion deduction (product-approved 2026-06-04).

A lesson transitioning to ``completed`` via the manual path
(``LessonService.update_status`` / ``update``) deducts exactly one
subscription session, mirroring the 24h auto-complete path (#469).
휴강/취소 statuses do NOT deduct. Deduction is idempotent on the
``SubscriptionUsage`` row, so re-completing or a later auto-complete
never double-deducts.
"""

from datetime import date

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import LessonStatus


async def _make_active_subscription(db_session: AsyncSession, *, total: int = 8) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    lesson_class = LessonClass(teacher_id="test-user-id", name="완료 차감 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lesson_class.id, student_id="student-001", instrument="piano", status="active"
    )
    db_session.add(membership)
    await db_session.flush()

    sub = Subscription(
        student_id="student-001",
        membership_id=membership.id,
        type=SubscriptionType.package,
        status=SubscriptionStatus.active,
        total_lessons=total,
        used_lessons=0,
    )
    db_session.add(sub)
    await db_session.flush()
    return sub.id


async def _make_lesson(db_session: AsyncSession, *, subscription_id: str | None):
    from app.models.lesson import Lesson

    lesson = Lesson(
        student_id="student-001",
        # Lessons store the Teacher profile id; the create_test_user fixture
        # makes it "<user_id>-prof". resolve_teacher_id maps user -> profile.
        teacher_id="test-user-id-prof",
        student_name="Student",
        instrument="piano",
        date=date(2026, 5, 8),
        start_time="10:00",
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=subscription_id,
    )
    db_session.add(lesson)
    await db_session.flush()
    return lesson


async def _used(db_session: AsyncSession, sub_id: str) -> int:
    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    return sub.used_lessons


@pytest.fixture
async def teacher_user(create_test_user):
    return await create_test_user(user_id="test-user-id", role="teacher")


@pytest.mark.asyncio
async def test_manual_complete_deducts_one_session(db_session, teacher_user):
    from app.services.lesson_service import LessonService

    sub_id = await _make_active_subscription(db_session)
    lesson = await _make_lesson(db_session, subscription_id=sub_id)

    svc = LessonService(db_session)
    await svc.update_status(lesson.id, LessonStatus.completed.value, teacher_user)

    await db_session.refresh(lesson)
    assert lesson.status == LessonStatus.completed
    assert await _used(db_session, sub_id) == 1


@pytest.mark.asyncio
async def test_manual_complete_is_idempotent_on_recomplete(db_session, teacher_user):
    from app.services.lesson_service import LessonService

    sub_id = await _make_active_subscription(db_session)
    lesson = await _make_lesson(db_session, subscription_id=sub_id)

    svc = LessonService(db_session)
    await svc.update_status(lesson.id, LessonStatus.completed.value, teacher_user)
    # Re-saving an already-completed lesson must not double-deduct.
    await svc.update_status(lesson.id, LessonStatus.completed.value, teacher_user)

    assert await _used(db_session, sub_id) == 1


@pytest.mark.asyncio
async def test_manual_then_auto_complete_no_double_deduct(db_session, teacher_user):
    from app.services.lesson_service import LessonService
    from app.services.subscription_service import SubscriptionService

    sub_id = await _make_active_subscription(db_session)
    lesson = await _make_lesson(db_session, subscription_id=sub_id)

    await LessonService(db_session).update_status(
        lesson.id, LessonStatus.completed.value, teacher_user
    )
    assert await _used(db_session, sub_id) == 1

    # The auto-complete path reuses the same idempotent method.
    again = await SubscriptionService(db_session).deduct_for_completed_lesson(lesson.id, sub_id)
    assert again is False
    assert await _used(db_session, sub_id) == 1


@pytest.mark.asyncio
async def test_cancelled_by_teacher_does_not_deduct(db_session, teacher_user):
    from app.services.lesson_service import LessonService

    sub_id = await _make_active_subscription(db_session)
    lesson = await _make_lesson(db_session, subscription_id=sub_id)

    await LessonService(db_session).update_status(
        lesson.id, LessonStatus.cancelledByTeacher.value, teacher_user
    )

    await db_session.refresh(lesson)
    assert lesson.status == LessonStatus.cancelledByTeacher
    assert await _used(db_session, sub_id) == 0


@pytest.mark.asyncio
async def test_complete_without_subscription_no_error_no_deduction(db_session, teacher_user):
    from app.services.lesson_service import LessonService

    lesson = await _make_lesson(db_session, subscription_id=None)

    await LessonService(db_session).update_status(
        lesson.id, LessonStatus.completed.value, teacher_user
    )

    await db_session.refresh(lesson)
    assert lesson.status == LessonStatus.completed
