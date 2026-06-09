"""Phase 25 — makeup_credit_spec.md §8.2 일괄변경 endpoint + §8.1 booking useCredit."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_subscription_and_bookings(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
) -> tuple[str, list[str]]:
    """수강권 1개 + 미래 LessonBooking 3건 (3주 연속 월요일)."""
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
    )
    db_session.add(sub)
    await db_session.flush()
    # 미래 월요일 3건 생성.
    base = date(2126, 7, 6)  # 월요일.
    booking_ids: list[str] = []
    for i in range(3):
        booking = LessonBooking(
            teacher_id=teacher_id,
            student_id=student_id,
            scheduled_date=base + timedelta(days=7 * i),
            scheduled_time="14:00",
            duration=60,
            subscription_id=sub.id,
            status=BookingStatus.confirmed,
        )
        db_session.add(booking)
        await db_session.flush()
        booking_ids.append(booking.id)
    return sub.id, booking_ids


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )


@pytest.mark.asyncio
async def test_bulk_change_moves_all_future_bookings(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """spec §7 — 충돌이 없으면 모든 미래 booking 을 새 요일/시간으로 이동."""
    from app.models.schedule import LessonBooking

    await _setup(create_test_user)
    # Pin "today" to before the bookings via date manipulation — bookings 2126.
    sub_id, booking_ids = await _seed_subscription_and_bookings(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    # 월요일 14:00 → 수요일 15:00 으로 일괄변경.
    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/bulk-change",
        headers=auth_headers,
        json={"new_day_of_week": 2, "new_time": "15:00"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["rescheduled_count"] == 3
    assert body["lost_count"] == 0
    assert body["credits_accrued"] == 0
    # 각 booking 이 수요일(weekday=2), 15:00 으로 이동되었는지 검증.
    db_session.expire_all()
    for bid in booking_ids:
        row = await db_session.get(LessonBooking, bid)
        assert row is not None
        assert row.scheduled_date.weekday() == 2
        assert row.scheduled_time == "15:00"


@pytest.mark.asyncio
async def test_bulk_change_accrues_credit_for_conflicting_slot(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """spec §7 — 같은 새 date 로 두 booking 이 모이면 두번째는 cancel + credit (seen_dates 충돌)."""
    from sqlalchemy import select as _select

    from app.models.lesson import ClassMembership, LessonClass
    from app.models.makeup_credit import MakeupCredit
    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.subscription import Subscription
    from app.services.subscription_service import resolve_teacher_id

    await _setup(create_test_user)
    teacher_profile_id = await resolve_teacher_id(db_session, "test-user-id")
    # 시나리오: 월요일 + 화요일 booking 둘 다 수요일 15:00 로 옮기면 → seen_dates 충돌.
    lc = LessonClass(teacher_id=teacher_profile_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id="test-student-id",
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id="test-student-id",
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
    )
    db_session.add(sub)
    await db_session.flush()
    monday = LessonBooking(
        teacher_id=teacher_profile_id,
        student_id="test-student-id",
        scheduled_date=date(2126, 7, 6),  # 월요일
        scheduled_time="14:00",
        duration=60,
        subscription_id=sub.id,
        status=BookingStatus.confirmed,
    )
    tuesday = LessonBooking(
        teacher_id=teacher_profile_id,
        student_id="test-student-id",
        scheduled_date=date(2126, 7, 7),  # 화요일
        scheduled_time="14:00",
        duration=60,
        subscription_id=sub.id,
        status=BookingStatus.confirmed,
    )
    db_session.add_all([monday, tuesday])
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/bulk-change",
        headers=auth_headers,
        json={"new_day_of_week": 2, "new_time": "15:00"},  # 수요일.
    )

    assert response.status_code == 200, response.text
    body = response.json()
    # 둘 다 7/8 (수요일) 새 date → 첫번째는 이동, 두번째는 seen_dates 충돌 → lost.
    assert body["rescheduled_count"] == 1
    assert body["lost_count"] == 1
    assert body["credits_accrued"] == 1
    db_session.expire_all()
    credits = (
        await db_session.scalars(_select(MakeupCredit).where(MakeupCredit.student_id == "test-student-id"))
    ).all()
    assert len(credits) == 1
    assert credits[0].reason.value == "bulkChangeLoss"


@pytest.mark.asyncio
async def test_bulk_change_rejects_invalid_day_of_week(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id, _ = await _seed_subscription_and_bookings(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/bulk-change",
        headers=auth_headers,
        json={"new_day_of_week": 7, "new_time": "15:00"},
    )

    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_booking_with_use_credit_consumes_active_credit(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """spec §8.1 — POST /bookings 의 useCredit=true 는 active 크레딧 1건 소비."""
    from app.models.makeup_credit import MakeupCredit, MakeupCreditReason

    await _setup(create_test_user)
    # 학생용 active credit 1건 (teacher 발급).
    credit = MakeupCredit(
        student_id="test-student-id",
        teacher_id="test-user-id-prof",
        reason=MakeupCreditReason.manualGrant,
        expires_at=datetime.now(UTC) + timedelta(days=30),
    )
    db_session.add(credit)
    await db_session.flush()
    credit_id = credit.id
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": "test-student-id",
            "scheduled_date": date(2126, 8, 1).isoformat(),
            "scheduled_time": "14:00",
            "duration": 60,
            "use_credit": True,
        },
    )

    assert response.status_code == 201, response.text
    # 크레딧이 used_at 으로 마킹되었는지.
    db_session.expire_all()
    refreshed = await db_session.get(MakeupCredit, credit_id)
    assert refreshed is not None
    assert refreshed.used_at is not None


@pytest.mark.asyncio
async def test_booking_with_use_credit_no_active_returns_422(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """active credit 없는데 useCredit=true → 422."""
    await _setup(create_test_user)
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": "test-student-id",
            "scheduled_date": date(2126, 8, 1).isoformat(),
            "scheduled_time": "14:00",
            "duration": 60,
            "use_credit": True,
        },
    )

    assert response.status_code == 422, response.text
