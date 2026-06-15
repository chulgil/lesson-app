"""#742 — deduct_for_completed_lesson idempotency tests.

The race fix locks the Subscription row (WITH FOR UPDATE) before re-checking
``SubscriptionUsage.lesson_id`` so a concurrent auto-complete caller observes
the first caller's usage row. True concurrency is not reproducible on SQLite,
so these tests guard the observable idempotency contract:

  - test_same_lesson_idempotent: two sequential calls for the same lesson_id →
    first True, second False, used_lessons incremented exactly once, one row.
  - test_different_lessons_each_deduct_once: two distinct lesson_ids each deduct
    once, used_lessons == 2.

Note: ``lesson_id`` is intentionally NOT globally unique — manual deduct and
reschedule paths legitimately record multiple usage rows per lesson, so the fix
relies on the row lock rather than a schema-wide unique constraint.
"""

from __future__ import annotations

from datetime import date

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# ---------------------------------------------------------------------------
# Shared setup helpers (mirrors test_attendance_deduction.py style)
# ---------------------------------------------------------------------------


async def _make_active_subscription(db_session: AsyncSession, *, total: int = 8) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    lesson_class = LessonClass(teacher_id="test-user-id", name="742 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id="student-742",
        instrument="violin",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()

    sub = Subscription(
        student_id="student-742",
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


def _make_lesson(*, subscription_id: str, suffix: str = ""):
    from app.models.lesson import Lesson, LessonStatus

    return Lesson(
        student_id="student-742",
        teacher_id="test-user-id",
        student_name="Student 742",
        instrument="violin",
        date=date(2026, 6, 15),
        start_time=f"10:0{suffix or '0'}",
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=subscription_id,
    )


# ---------------------------------------------------------------------------
# same lesson_id → first True, second False, used_lessons == 1
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_same_lesson_idempotent(db_session: AsyncSession, create_test_user):
    """GREEN: deduct_for_completed_lesson called twice for the same lesson_id.

    Expected:
    - first call  → True  (deduction recorded)
    - second call → False (idempotent: existing usage re-checked under row lock)
    - used_lessons incremented exactly once
    """
    from app.models.subscription import Subscription
    from app.services.subscription_service import SubscriptionService

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    lesson = _make_lesson(subscription_id=sub_id)
    db_session.add(lesson)
    await db_session.flush()

    svc = SubscriptionService(db_session)

    # First call: should succeed and return True.
    result1 = await svc.deduct_for_completed_lesson(lesson.id, sub_id)
    assert result1 is True, f"Expected True on first call, got {result1}"

    # Second call for the SAME lesson_id: must be idempotent → False.
    result2 = await svc.deduct_for_completed_lesson(lesson.id, sub_id)
    assert result2 is False, f"Expected False on second call (idempotent), got {result2}"

    # used_lessons must be exactly 1 despite two calls.
    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 1, (
        f"GREEN: used_lessons should be 1 after two calls for same lesson, got {sub.used_lessons}"
    )

    # Verify only one SubscriptionUsage row exists for this lesson_id.
    from app.models.subscription import SubscriptionUsage

    rows = (await db_session.scalars(select(SubscriptionUsage).where(SubscriptionUsage.lesson_id == lesson.id))).all()
    assert len(rows) == 1, f"Expected 1 usage row, found {len(rows)}"


# ---------------------------------------------------------------------------
# EXTRA: two different lesson_ids → each deducts once, used_lessons == 2
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_different_lessons_each_deduct_once(db_session: AsyncSession, create_test_user):
    """Two distinct lesson_ids each produce exactly one deduction (used_lessons == 2)."""
    from app.models.subscription import Subscription
    from app.services.subscription_service import SubscriptionService

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session, total=8)

    lesson_a = _make_lesson(subscription_id=sub_id, suffix="0")
    lesson_b = _make_lesson(subscription_id=sub_id, suffix="1")
    db_session.add(lesson_a)
    db_session.add(lesson_b)
    await db_session.flush()

    svc = SubscriptionService(db_session)

    r1 = await svc.deduct_for_completed_lesson(lesson_a.id, sub_id)
    assert r1 is True, "Expected True for lesson_a first deduction"

    r2 = await svc.deduct_for_completed_lesson(lesson_b.id, sub_id)
    assert r2 is True, "Expected True for lesson_b first deduction"

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 2, f"Expected used_lessons == 2 for two distinct lessons, got {sub.used_lessons}"
