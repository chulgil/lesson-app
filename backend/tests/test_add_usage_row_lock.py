"""Regression test: add_usage() must lock the Subscription row before bumping
used_lessons, matching every other deduction path in this service.

Bug: add_usage() read the subscription via plain ``db.get()`` (no row lock)
before calling ``_apply_deduction_counter``, while every sibling deduction
function (deduct_lesson, deduct_for_completed_lesson, etc.) locks the row via
``select(...).with_for_update()``. Two concurrent add_usage calls could both
read the same used_lessons value and both write the same +1 result, losing an
increment (a free lesson leak).

True concurrency is not reproducible on SQLite (see test_deduct_idempotency.py
docstring for the same caveat on the sibling fix), so this test:
  1. Asserts the fix is structurally present (the subscription lookup used by
     add_usage is a locked SELECT), so a future edit that drops the lock is
     caught even though a live race can't be simulated here.
  2. Confirms sequential correctness is unchanged (two deducted usages still
     bump used_lessons by exactly 2, no double counting from the lock itself).
"""

from __future__ import annotations

import pytest
from sqlalchemy.ext.asyncio import AsyncSession


async def _make_active_subscription(db_session: AsyncSession, *, total: int = 8) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    lesson_class = LessonClass(teacher_id="test-user-id", name="add_usage 락 테스트", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id="student-add-usage-lock",
        instrument="violin",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()

    sub = Subscription(
        student_id="student-add-usage-lock",
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


@pytest.mark.asyncio
async def test_add_usage_subscription_lookup_uses_row_lock(
    db_session: AsyncSession, create_test_user, monkeypatch: pytest.MonkeyPatch
) -> None:
    from app.models.subscription import Subscription
    from app.services.subscription_service import SubscriptionService

    user = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    service = SubscriptionService(db_session)

    captured_statements = []
    original_scalar = db_session.scalar

    async def _spy_scalar(statement, *args, **kwargs):
        captured_statements.append(statement)
        return await original_scalar(statement, *args, **kwargs)

    monkeypatch.setattr(db_session, "scalar", _spy_scalar)

    await service.add_usage(sub_id, {"lesson_id": "lesson-lock-1", "deducted": True}, user)

    subscription_lookups = [
        stmt
        for stmt in captured_statements
        if hasattr(stmt, "column_descriptions")
        and any(col.get("entity") is Subscription for col in stmt.column_descriptions)
    ]
    assert subscription_lookups, "add_usage must look up the Subscription via db.scalar(select(...)), not db.get()"
    assert any(stmt._for_update_arg is not None for stmt in subscription_lookups), (
        "add_usage's Subscription lookup must use with_for_update() to serialize concurrent deductions"
    )


@pytest.mark.asyncio
async def test_add_usage_sequential_calls_still_count_correctly(db_session: AsyncSession, create_test_user) -> None:
    from app.models.subscription import Subscription
    from app.services.subscription_service import SubscriptionService

    user = await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    service = SubscriptionService(db_session)
    await service.add_usage(sub_id, {"lesson_id": "lesson-lock-2", "deducted": True}, user)
    await service.add_usage(sub_id, {"lesson_id": "lesson-lock-3", "deducted": True}, user)

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.used_lessons == 2
