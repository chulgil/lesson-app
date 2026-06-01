"""GET list + DELETE recovery tests — H-001 vacation mode.

Spec: docs/specs/schedule/teacher_vacation_mode.md §7 (Recovery 24h window).

Adds two endpoints to /api/v1/teacher/vacation:
  - GET  /                 : list teacher's vacations (active by default)
  - DELETE /{period_id}    : cancel a vacation within 24h, revert auto-extended days
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.lesson import ClassMembership, LessonClass
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
    VacationDisposition,
    VacationPeriod,
)
from app.models.student import Student
from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType


def _headers(user_id: str = "test-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_lesson_class(db_session: AsyncSession, teacher_id: str) -> str:
    lesson_class_id = f"lc-{uuid4()}"
    db_session.add(LessonClass(id=lesson_class_id, teacher_id=teacher_id, name="Test Class"))
    await db_session.flush()
    return lesson_class_id


async def _seed_booking_with_subscription(
    db_session: AsyncSession,
    teacher_id: str,
    lesson_class_id: str,
    scheduled: date,
) -> tuple[str, str]:
    """Seed one student + subscription + active booking. Returns (student_id, subscription_id)."""
    student_id = f"student-{uuid4()}"
    db_session.add(Student(id=student_id, teacher_id=teacher_id, name="민수"))
    await db_session.flush()

    membership_id = f"mem-{uuid4()}"
    db_session.add(
        ClassMembership(
            id=membership_id,
            lesson_class_id=lesson_class_id,
            student_id=student_id,
            instrument="violin",
            lesson_duration=60,
        )
    )
    await db_session.flush()

    sub_id = f"sub-{uuid4()}"
    db_session.add(
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
        )
    )
    await db_session.flush()

    db_session.add(
        LessonBooking(
            id=f"booking-{uuid4()}",
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_type=BookingLessonType.regular,
            scheduled_date=scheduled,
            scheduled_time="14:00",
            duration=60,
            subscription_id=sub_id,
            status=BookingStatus.confirmed,
        )
    )
    await db_session.flush()
    return student_id, sub_id


async def _seed_vacation(
    db_session: AsyncSession,
    teacher_id: str,
    *,
    start: date,
    end: date,
    created_hours_ago: float = 0,
    cancelled: bool = False,
    disposition: VacationDisposition = VacationDisposition.rollForward,
) -> str:
    """Insert a VacationPeriod and optionally back-date `created_at`."""
    period_id = f"vac-{uuid4()}"
    db_session.add(
        VacationPeriod(
            id=period_id,
            teacher_id=teacher_id,
            start_date=start,
            end_date=end,
            default_disposition=disposition,
            cancelled_at=datetime.now(UTC) if cancelled else None,
        )
    )
    await db_session.flush()

    if created_hours_ago:
        period = await db_session.get(VacationPeriod, period_id)
        period.created_at = datetime.now(UTC) - timedelta(hours=created_hours_ago)
        await db_session.flush()
    return period_id


@pytest.mark.asyncio
async def test_list_returns_active_vacations_only_by_default(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """GET /teacher/vacation returns active periods. Cancelled ones excluded by default."""
    user = await create_test_user(user_id="t-list", role="teacher", email="tl@test.com")
    teacher_id = f"{user.id}-prof"

    active_id = await _seed_vacation(db_session, teacher_id, start=date(2026, 8, 1), end=date(2026, 8, 5))
    await _seed_vacation(db_session, teacher_id, start=date(2026, 7, 1), end=date(2026, 7, 5), cancelled=True)
    await db_session.commit()

    response = await client.get(
        "/api/v1/teacher/vacation",
        headers=_headers("t-list"),
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["total_count"] == 1
    assert body["vacations"][0]["id"] == active_id


@pytest.mark.asyncio
async def test_list_can_include_cancelled(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Query param include_cancelled=true returns both active and cancelled periods."""
    user = await create_test_user(user_id="t-cancelled", role="teacher", email="tc@test.com")
    teacher_id = f"{user.id}-prof"

    await _seed_vacation(db_session, teacher_id, start=date(2026, 8, 1), end=date(2026, 8, 5))
    await _seed_vacation(db_session, teacher_id, start=date(2026, 7, 1), end=date(2026, 7, 5), cancelled=True)
    await db_session.commit()

    response = await client.get(
        "/api/v1/teacher/vacation",
        params={"include_cancelled": "true"},
        headers=_headers("t-cancelled"),
    )
    assert response.status_code == 200, response.text
    assert response.json()["total_count"] == 2


@pytest.mark.asyncio
async def test_list_other_teacher_excluded(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """A teacher only sees their own vacations."""
    user = await create_test_user(user_id="t-own", role="teacher", email="to@test.com")
    teacher_id = f"{user.id}-prof"
    await _seed_vacation(db_session, teacher_id, start=date(2026, 8, 1), end=date(2026, 8, 5))
    await _seed_vacation(db_session, "someone-else-prof", start=date(2026, 8, 1), end=date(2026, 8, 5))
    await db_session.commit()

    response = await client.get(
        "/api/v1/teacher/vacation",
        headers=_headers("t-own"),
    )
    assert response.status_code == 200, response.text
    assert response.json()["total_count"] == 1


@pytest.mark.asyncio
async def test_cancel_within_24h_reverts_auto_extended_days(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """DELETE within 24h restores subscription.auto_extended_days."""
    user = await create_test_user(user_id="t-revert", role="teacher", email="tr@test.com")
    teacher_id = f"{user.id}-prof"
    lesson_class_id = await _seed_lesson_class(db_session, teacher_id)
    _, sub_id = await _seed_booking_with_subscription(db_session, teacher_id, lesson_class_id, date(2026, 8, 2))

    register = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-revert"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "rollForward",
        },
    )
    assert register.status_code == 201, register.text
    period_id = register.json()["id"]

    sub = await db_session.get(Subscription, sub_id)
    await db_session.refresh(sub)
    assert sub.auto_extended_days == 5  # 5-day vacation

    cancel = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-revert"),
    )
    assert cancel.status_code == 200, cancel.text

    period = await db_session.get(VacationPeriod, period_id)
    await db_session.refresh(period)
    assert period.cancelled_at is not None

    await db_session.refresh(sub)
    assert sub.auto_extended_days == 0


@pytest.mark.asyncio
async def test_cancel_after_24h_returns_409(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """DELETE after 24h returns 409 conflict."""
    user = await create_test_user(user_id="t-late", role="teacher", email="tt@test.com")
    teacher_id = f"{user.id}-prof"

    period_id = await _seed_vacation(
        db_session,
        teacher_id,
        start=date(2026, 8, 1),
        end=date(2026, 8, 5),
        created_hours_ago=25,
    )
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-late"),
    )
    assert response.status_code == 409, response.text


@pytest.mark.asyncio
async def test_cancel_after_vacation_started_returns_409(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """If vacation start_date has passed, recovery is blocked even within 24h."""
    user = await create_test_user(user_id="t-started", role="teacher", email="ts@test.com")
    teacher_id = f"{user.id}-prof"

    yesterday = (datetime.now(UTC) - timedelta(days=1)).date()
    period_id = await _seed_vacation(
        db_session,
        teacher_id,
        start=yesterday,
        end=yesterday + timedelta(days=4),
        created_hours_ago=2,
    )
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-started"),
    )
    assert response.status_code == 409, response.text


@pytest.mark.asyncio
async def test_cancel_other_teacher_rejected(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Another teacher cannot cancel someone else's vacation."""
    await create_test_user(user_id="t-self", role="teacher", email="se@test.com")
    period_id = await _seed_vacation(
        db_session,
        "stranger-prof",
        start=date(2026, 8, 1),
        end=date(2026, 8, 5),
    )
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-self"),
    )
    assert response.status_code in (403, 404)


@pytest.mark.asyncio
async def test_cancel_already_cancelled_returns_400(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Re-cancelling an already cancelled vacation returns 400."""
    user = await create_test_user(user_id="t-dup", role="teacher", email="td@test.com")
    teacher_id = f"{user.id}-prof"
    period_id = await _seed_vacation(
        db_session,
        teacher_id,
        start=date(2026, 8, 1),
        end=date(2026, 8, 5),
        cancelled=True,
    )
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teacher/vacation/{period_id}",
        headers=_headers("t-dup"),
    )
    assert response.status_code == 400
