"""Phase 27 — booking 변경 시 subscription 변경권 차감 + 알림 wiring.

spec subscription_edit_spec.md §2.1 / §7.1 + notification_master.md.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_sub_and_booking(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
    *,
    total_reschedule_allowance: int = 2,
    used_reschedule_count: int = 0,
    bonus_reschedule_count: int = 0,
) -> tuple[str, str]:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.subscription import Subscription
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=student_id,
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id=student_id,
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
        total_reschedule_allowance=total_reschedule_allowance,
        used_reschedule_count=used_reschedule_count,
        bonus_reschedule_count=bonus_reschedule_count,
    )
    db_session.add(sub)
    await db_session.flush()
    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id=student_id,
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        subscription_id=sub.id,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    return sub.id, booking.id


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="김학생",
        email="student@test.com",
    )


@pytest.mark.asyncio
async def test_booking_change_consumes_reschedule_credit(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """booking 변경 → subscription.used_reschedule_count 가 +1."""
    from sqlalchemy import select

    from app.models.subscription import Subscription, SubscriptionUsage

    await _setup(create_test_user)
    sub_id, booking_id = await _seed_sub_and_booking(
        db_session, "test-user-id", "test-student-id", total_reschedule_allowance=2
    )
    await db_session.commit()

    response = await client.post(
        f"/api/v1/bookings/{booking_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2126-07-13", "new_time": "15:00", "reason": "사정"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    sub_row = await db_session.get(Subscription, sub_id)
    assert sub_row is not None
    assert sub_row.used_reschedule_count == 1
    usage_rows = (
        await db_session.scalars(select(SubscriptionUsage).where(SubscriptionUsage.subscription_id == sub_id))
    ).all()
    assert any(u.type == "reschedule" for u in usage_rows)


@pytest.mark.asyncio
async def test_booking_change_rejected_when_no_remaining_credits(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """잔여 변경권 0 → 422 + 차감 누락 + status 미변경."""
    from app.models.schedule import LessonBooking

    await _setup(create_test_user)
    sub_id, booking_id = await _seed_sub_and_booking(
        db_session,
        "test-user-id",
        "test-student-id",
        total_reschedule_allowance=1,
        used_reschedule_count=1,
    )
    await db_session.commit()

    response = await client.post(
        f"/api/v1/bookings/{booking_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2126-07-13", "new_time": "15:00"},
    )

    assert response.status_code == 422, response.text
    db_session.expire_all()
    booking = await db_session.get(LessonBooking, booking_id)
    assert booking is not None
    # 차단되었으니 원래 date/time 그대로.
    assert booking.scheduled_date == date(2126, 7, 6)
    assert booking.scheduled_time == "14:00"


@pytest.mark.asyncio
async def test_booking_change_uses_bonus_allowance(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """bonus_reschedule_count 가 effective allowance 에 합산되어 통과."""
    from app.models.subscription import Subscription

    await _setup(create_test_user)
    sub_id, booking_id = await _seed_sub_and_booking(
        db_session,
        "test-user-id",
        "test-student-id",
        total_reschedule_allowance=1,
        used_reschedule_count=1,
        bonus_reschedule_count=1,
    )
    await db_session.commit()

    response = await client.post(
        f"/api/v1/bookings/{booking_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2126-07-13", "new_time": "15:00"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    sub_row = await db_session.get(Subscription, sub_id)
    assert sub_row.used_reschedule_count == 2


@pytest.mark.asyncio
async def test_booking_change_sends_schedule_change_notification(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """변경 요청 시 상대편 user 에게 scheduleChangeRequested 알림 생성."""
    from sqlalchemy import select

    from app.models.notification import Notification

    await _setup(create_test_user)
    _, booking_id = await _seed_sub_and_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    # 선생님(actor) → 학생 알림.
    response = await client.post(
        f"/api/v1/bookings/{booking_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2126-07-13", "new_time": "15:00"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    notifs = (
        await db_session.scalars(
            select(Notification)
            .where(Notification.user_id == "test-student-id")
            .where(Notification.type == "scheduleChangeRequested")
        )
    ).all()
    assert len(notifs) >= 1


@pytest.mark.asyncio
async def test_booking_change_without_subscription_skips_credit(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """booking 에 subscription_id 가 없으면 차감 로직 건너뜀 (trial/free booking)."""
    from app.models.schedule import BookingStatus, LessonBooking
    from app.services.subscription_service import resolve_teacher_id

    await _setup(create_test_user)
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id="test-student-id",
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        subscription_id=None,  # 정규권 외.
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    await db_session.commit()

    response = await client.post(
        f"/api/v1/bookings/{booking.id}/change-request",
        headers=auth_headers,
        json={"new_date": "2126-07-13", "new_time": "15:00"},
    )

    assert response.status_code == 200, response.text
