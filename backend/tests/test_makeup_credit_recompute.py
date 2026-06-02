"""recompute_for_subscriptions tests — #7 H-002."""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, LessonClass
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
)
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType
from app.services.makeup_credit_service import MakeupCreditService


async def _seed_subscription_with_bookings(
    db: AsyncSession,
    *,
    teacher_id: str = "t-1",
    student_name: str = "민준",
    active_count: int = 2,
    cancelled_count: int = 1,
) -> str:
    student_id = f"student-{uuid4()}"
    db.add(Student(id=student_id, teacher_id=teacher_id, name=student_name))
    await db.flush()

    lc_id = f"lc-{uuid4()}"
    db.add(LessonClass(id=lc_id, teacher_id=teacher_id, name="Test Class"))
    await db.flush()

    membership_id = f"mem-{uuid4()}"
    db.add(
        ClassMembership(
            id=membership_id,
            lesson_class_id=lc_id,
            student_id=student_id,
            instrument="violin",
            lesson_duration=60,
        )
    )
    await db.flush()

    sub_id = f"sub-{uuid4()}"
    db.add(
        Subscription(
            id=sub_id,
            student_id=student_id,
            membership_id=membership_id,
            type=SubscriptionType.monthly,
            lessons_per_month=4,
            used_lessons=0,
            start_date=date(2026, 6, 1),
            end_date=date(2026, 7, 31),
            amount=200000,
            status=SubscriptionStatus.active,
            payment_confirmed=True,
            paid_at=datetime.now(UTC),
            payment_confirmed_at=datetime.now(UTC),
            scheduled_lessons=0,
        )
    )
    await db.flush()

    for i in range(active_count):
        db.add(
            LessonBooking(
                id=f"booking-active-{uuid4()}",
                teacher_id=teacher_id,
                student_id=student_id,
                lesson_type=BookingLessonType.regular,
                scheduled_date=date(2026, 8, 1 + i),
                scheduled_time="14:00",
                duration=60,
                subscription_id=sub_id,
                status=BookingStatus.confirmed,
            )
        )
    for i in range(cancelled_count):
        db.add(
            LessonBooking(
                id=f"booking-cx-{uuid4()}",
                teacher_id=teacher_id,
                student_id=student_id,
                lesson_type=BookingLessonType.regular,
                scheduled_date=date(2026, 8, 20 + i),
                scheduled_time="14:00",
                duration=60,
                subscription_id=sub_id,
                status=BookingStatus.cancelled,
            )
        )
    await db.flush()
    return sub_id


@pytest.mark.asyncio
async def test_recompute_returns_active_booking_count_per_subscription(
    db_session: AsyncSession,
):
    sub_id = await _seed_subscription_with_bookings(db_session, active_count=3, cancelled_count=2)
    service = MakeupCreditService(db_session)
    result = await service.recompute_for_subscriptions([sub_id])
    assert result == {sub_id: 3}

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.scheduled_lessons == 3


@pytest.mark.asyncio
async def test_recompute_handles_multiple_subscriptions(db_session: AsyncSession):
    sub_a = await _seed_subscription_with_bookings(db_session, student_name="A", active_count=4, cancelled_count=0)
    sub_b = await _seed_subscription_with_bookings(db_session, student_name="B", active_count=1, cancelled_count=1)
    service = MakeupCreditService(db_session)
    result = await service.recompute_for_subscriptions([sub_a, sub_b])
    assert result == {sub_a: 4, sub_b: 1}


@pytest.mark.asyncio
async def test_recompute_skips_unknown_subscription_ids(db_session: AsyncSession):
    sub_id = await _seed_subscription_with_bookings(db_session, active_count=2)
    service = MakeupCreditService(db_session)
    result = await service.recompute_for_subscriptions([sub_id, "does-not-exist"])
    assert result == {sub_id: 2}


@pytest.mark.asyncio
async def test_recompute_empty_input_returns_empty_dict(db_session: AsyncSession):
    service = MakeupCreditService(db_session)
    assert await service.recompute_for_subscriptions([]) == {}
