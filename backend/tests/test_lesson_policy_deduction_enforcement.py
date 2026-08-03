"""Regression test: LessonPolicy.no_show_deducts_lesson / late_cancel_deducts_lesson
must actually gate a subscription deduction when a lesson is marked noShow or
cancelledByStudentLate.

Bug: LessonPolicy was fully CRUD-able but never read by the actual lesson
status-update flow — a teacher could configure "deduct a lesson on no-show"
and it would silently have no effect. update_status() only ever deducted on
``completed``.

Decision (user, 2026-07-27): the cancellation/no-show request itself is never
blocked by deadline checks — it is always allowed to proceed. Only the
configured deduction consequence (no_show_deducts_lesson /
late_cancel_deducts_lesson) is enforced. Teachers with no LessonPolicy row at
all see no behavior change (deduction is skipped, not defaulted to True).
"""

from __future__ import annotations

from datetime import date

import pytest
from sqlalchemy.ext.asyncio import AsyncSession


async def _make_active_subscription(db_session: AsyncSession, *, total: int = 8) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    lesson_class = LessonClass(teacher_id="test-user-id-prof", name="정책집행 테스트", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id="student-policy-enforce",
        instrument="violin",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()

    sub = Subscription(
        student_id="student-policy-enforce",
        membership_id=membership.id,
        type=SubscriptionType.package,
        status=SubscriptionStatus.active,
        total_lessons=total,
        used_lessons=0,
        payment_confirmed=True,
    )
    db_session.add(sub)
    await db_session.flush()
    return sub.id


def _make_lesson(*, subscription_id: str, start_time: str = "10:00"):
    from app.models.lesson import Lesson, LessonStatus

    return Lesson(
        student_id="student-policy-enforce",
        teacher_id="test-user-id-prof",
        student_name="Student",
        instrument="violin",
        date=date(2026, 6, 15),
        start_time=start_time,
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=subscription_id,
    )


@pytest.mark.asyncio
async def test_no_show_deducts_lesson_when_policy_enabled(db_session: AsyncSession, create_test_user) -> None:
    from app.models.policy import LessonPolicy
    from app.models.subscription import Subscription
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)
    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    db_session.add(LessonPolicy(teacher_id="test-user-id-prof", no_show_deducts_lesson=True))
    await db_session.flush()

    service = LessonService(db_session)
    await service.update_status(lesson.id, "noShow", teacher)

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 1


@pytest.mark.asyncio
async def test_no_show_does_not_deduct_when_policy_disabled(db_session: AsyncSession, create_test_user) -> None:
    from app.models.policy import LessonPolicy
    from app.models.subscription import Subscription
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)
    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    db_session.add(LessonPolicy(teacher_id="test-user-id-prof", no_show_deducts_lesson=False))
    await db_session.flush()

    service = LessonService(db_session)
    await service.update_status(lesson.id, "noShow", teacher)

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 0


@pytest.mark.asyncio
async def test_no_show_allowed_and_no_deduction_without_any_policy(db_session: AsyncSession, create_test_user) -> None:
    """No LessonPolicy row at all: status change still succeeds, no deduction (safe default)."""
    from app.models.subscription import Subscription
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)
    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    await db_session.flush()

    service = LessonService(db_session)
    result = await service.update_status(lesson.id, "noShow", teacher)
    assert result.status == "noShow"

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 0


@pytest.mark.asyncio
async def test_late_cancel_deducts_lesson_when_policy_enabled(db_session: AsyncSession, create_test_user) -> None:
    from app.models.policy import LessonPolicy
    from app.models.subscription import Subscription
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)
    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    db_session.add(LessonPolicy(teacher_id="test-user-id-prof", late_cancel_deducts_lesson=True))
    await db_session.flush()

    service = LessonService(db_session)
    await service.update_status(lesson.id, "cancelledByStudentLate", teacher)

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 1


@pytest.mark.asyncio
async def test_advance_cancel_never_deducts_regardless_of_policy(db_session: AsyncSession, create_test_user) -> None:
    """cancelledByStudentAdvance is not a penalty status — must never deduct."""
    from app.models.policy import LessonPolicy
    from app.models.subscription import Subscription
    from app.services.lesson_service import LessonService

    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)
    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    db_session.add(
        LessonPolicy(
            teacher_id="test-user-id-prof",
            no_show_deducts_lesson=True,
            late_cancel_deducts_lesson=True,
        )
    )
    await db_session.flush()

    service = LessonService(db_session)
    await service.update_status(lesson.id, "cancelledByStudentAdvance", teacher)

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 0
