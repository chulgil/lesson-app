"""Vacation disposition pipeline tests — #4 H-001 spec §5 + §7.3.

Adds disposition-aware processing on top of the existing rollForward
auto-extend behavior:
  - freeCancel : booking.status = cancelled, no makeup credit, no auto-extend
  - makeupCredit : booking.status = cancelled + 1 MakeupCredit/lesson accrued
  - per_student override : uses per-student disposition for that student's bookings
  - Recovery : revert cancelled bookings + drop accrued credits + revert auto-extend
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta, timezone
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.lesson import ClassMembership, LessonClass
from app.models.makeup_credit import MakeupCredit
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
)
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType


def _headers(user_id: str = "test-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_lesson_class(db: AsyncSession, teacher_id: str) -> str:
    lc_id = f"lc-{uuid4()}"
    db.add(LessonClass(id=lc_id, teacher_id=teacher_id, name="Test Class"))
    await db.flush()
    return lc_id


async def _seed_student(
    db: AsyncSession,
    teacher_id: str,
    name: str = "민수",
) -> tuple[str, str]:
    """Return (student_id, teacher_pk_id_of_teacher)."""
    student_id = f"student-{uuid4()}"
    db.add(Student(id=student_id, teacher_id=teacher_id, name=name))
    await db.flush()
    return student_id, teacher_id


async def _seed_booking(
    db: AsyncSession,
    teacher_id: str,
    student_id: str,
    scheduled: date,
    *,
    lesson_class_id: str | None = None,
    with_subscription: bool = False,
) -> tuple[str, str | None]:
    """Insert one booking + optional subscription. Returns (booking_id, sub_id)."""
    subscription_id: str | None = None
    if with_subscription:
        assert lesson_class_id is not None
        membership_id = f"mem-{uuid4()}"
        db.add(
            ClassMembership(
                id=membership_id,
                lesson_class_id=lesson_class_id,
                student_id=student_id,
                instrument="violin",
                lesson_duration=60,
            )
        )
        await db.flush()
        subscription_id = f"sub-{uuid4()}"
        db.add(
            Subscription(
                id=subscription_id,
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
            )
        )
        await db.flush()

    booking_id = f"booking-{uuid4()}"
    db.add(
        LessonBooking(
            id=booking_id,
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_type=BookingLessonType.regular,
            scheduled_date=scheduled,
            scheduled_time="14:00",
            duration=60,
            subscription_id=subscription_id,
            status=BookingStatus.confirmed,
        )
    )
    await db.flush()
    return booking_id, subscription_id


# --------------------------------------------------------------------- freeCancel


@pytest.mark.asyncio
async def test_free_cancel_cancels_bookings_without_credit(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    user = await create_test_user(user_id="t-fc", role="teacher", email="tfc@test.com")
    teacher_id = f"{user.id}-prof"
    lc = await _seed_lesson_class(db_session, teacher_id)
    student_id, _ = await _seed_student(db_session, teacher_id, "민수")
    booking_id, _ = await _seed_booking(
        db_session,
        teacher_id,
        student_id,
        date(2026, 8, 2),
        lesson_class_id=lc,
        with_subscription=True,
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-fc"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "freeCancel",
        },
    )
    assert response.status_code == 201, response.text
    period_id = response.json()["id"]

    booking = await db_session.get(LessonBooking, booking_id)
    await db_session.refresh(booking)
    assert booking.status == BookingStatus.cancelled
    assert booking.vacation_period_id == period_id

    credits = (await db_session.scalars(select(MakeupCredit).where(MakeupCredit.student_id == student_id))).all()
    assert credits == []


# --------------------------------------------------------------------- makeupCredit


@pytest.mark.asyncio
async def test_makeup_credit_accrues_one_per_booking(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    user = await create_test_user(user_id="t-mc", role="teacher", email="tmc@test.com")
    teacher_id = f"{user.id}-prof"
    lc = await _seed_lesson_class(db_session, teacher_id)
    student_id, _ = await _seed_student(db_session, teacher_id, "서연")
    # Both bookings reuse the same subscription — a single ClassMembership row.
    await _seed_booking(
        db_session,
        teacher_id,
        student_id,
        date(2026, 8, 2),
        lesson_class_id=lc,
        with_subscription=True,
    )
    # Second booking for the same student — share membership, skip making another sub.
    await _seed_booking(
        db_session,
        teacher_id,
        student_id,
        date(2026, 8, 4),
        lesson_class_id=lc,
        with_subscription=False,
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-mc"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "makeupCredit",
        },
    )
    assert response.status_code == 201, response.text
    period_id = response.json()["id"]

    credits = (await db_session.scalars(select(MakeupCredit).where(MakeupCredit.source_event_id == period_id))).all()
    assert len(credits) == 2
    assert all(c.student_id == student_id for c in credits)


# --------------------------------------------------------------------- per_student override


@pytest.mark.asyncio
async def test_per_student_override_routes_each_student(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Default = rollForward, but student A uses makeupCredit and student B uses freeCancel."""
    user = await create_test_user(user_id="t-ps", role="teacher", email="tps@test.com")
    teacher_id = f"{user.id}-prof"
    lc = await _seed_lesson_class(db_session, teacher_id)
    student_a, _ = await _seed_student(db_session, teacher_id, "A")
    student_b, _ = await _seed_student(db_session, teacher_id, "B")

    booking_a, _ = await _seed_booking(
        db_session,
        teacher_id,
        student_a,
        date(2026, 8, 2),
        lesson_class_id=lc,
        with_subscription=True,
    )
    booking_b, _ = await _seed_booking(
        db_session,
        teacher_id,
        student_b,
        date(2026, 8, 3),
        lesson_class_id=lc,
        with_subscription=True,
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-ps"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "rollForward",
            "per_student_disposition": {
                student_a: "makeupCredit",
                student_b: "freeCancel",
            },
        },
    )
    assert response.status_code == 201, response.text
    period_id = response.json()["id"]

    # Student A: 1 makeup credit, booking cancelled
    credits_a = (await db_session.scalars(select(MakeupCredit).where(MakeupCredit.student_id == student_a))).all()
    assert len(credits_a) == 1
    booking_a_row = await db_session.get(LessonBooking, booking_a)
    await db_session.refresh(booking_a_row)
    assert booking_a_row.status == BookingStatus.cancelled
    assert booking_a_row.vacation_period_id == period_id

    # Student B: 0 credits, booking cancelled (freeCancel)
    credits_b = (await db_session.scalars(select(MakeupCredit).where(MakeupCredit.student_id == student_b))).all()
    assert credits_b == []
    booking_b_row = await db_session.get(LessonBooking, booking_b)
    await db_session.refresh(booking_b_row)
    assert booking_b_row.status == BookingStatus.cancelled


# --------------------------------------------------------------------- Recovery


# 취소 가드("이미 시작된 휴가")는 KST 오늘 기준이라 고정 날짜는 그 날이 지나면
# 썩는다 — 복원 경로 테스트는 항상 미래 창을 쓴다.
_KST_TZ = timezone(timedelta(hours=9))


def _future_vacation_window(days: int = 5) -> tuple[date, date]:
    start = datetime.now(_KST_TZ).date() + timedelta(days=1)
    return start, start + timedelta(days=days - 1)


@pytest.mark.asyncio
async def test_recovery_restores_bookings_and_drops_credits(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """DELETE within 24h: cancelled bookings → confirmed, credits removed."""
    user = await create_test_user(user_id="t-rec", role="teacher", email="trec@test.com")
    teacher_id = f"{user.id}-prof"
    lc = await _seed_lesson_class(db_session, teacher_id)
    student_id, _ = await _seed_student(db_session, teacher_id, "복원")
    vac_start, vac_end = _future_vacation_window()
    booking_id, _ = await _seed_booking(
        db_session,
        teacher_id,
        student_id,
        vac_start + timedelta(days=1),
        lesson_class_id=lc,
        with_subscription=True,
    )
    await db_session.commit()

    register = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-rec"),
        json={
            "start_date": vac_start.isoformat(),
            "end_date": vac_end.isoformat(),
            "default_disposition": "makeupCredit",
        },
    )
    assert register.status_code == 201, register.text
    period_id = register.json()["id"]

    # Sanity: booking cancelled + 1 credit created
    booking = await db_session.get(LessonBooking, booking_id)
    await db_session.refresh(booking)
    assert booking.status == BookingStatus.cancelled

    cancel = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-rec"),
    )
    assert cancel.status_code == 200, cancel.text

    await db_session.refresh(booking)
    assert booking.status == BookingStatus.confirmed
    assert booking.vacation_period_id is None

    credits = (await db_session.scalars(select(MakeupCredit).where(MakeupCredit.source_event_id == period_id))).all()
    assert credits == []


# --------------------------------------------------------------------- rollForward fallback


@pytest.mark.asyncio
async def test_rollforward_disposition_skips_booking_cancellation(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """rollForward keeps the booking (auto_extended_days handles the slip)."""
    user = await create_test_user(user_id="t-rf", role="teacher", email="trf@test.com")
    teacher_id = f"{user.id}-prof"
    lc = await _seed_lesson_class(db_session, teacher_id)
    student_id, _ = await _seed_student(db_session, teacher_id, "민준")
    booking_id, _ = await _seed_booking(
        db_session,
        teacher_id,
        student_id,
        date(2026, 8, 2),
        lesson_class_id=lc,
        with_subscription=True,
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-rf"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "rollForward",
        },
    )
    assert response.status_code == 201, response.text

    booking = await db_session.get(LessonBooking, booking_id)
    await db_session.refresh(booking)
    # rollForward keeps the booking active.
    assert booking.status == BookingStatus.confirmed
    assert booking.vacation_period_id is None
