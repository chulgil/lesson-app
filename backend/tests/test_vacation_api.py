"""Tests for /api/v1/teacher/vacation endpoints (#431).

Spec: docs/specs/schedule/teacher_vacation_mode.md.
1차 BE 범위: 휴가 등록 (POST), 영향 미리보기 (GET impact), auto_extended_days 자동 증가.
"""

from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.lesson import ClassMembership, LessonClass
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


async def _seed_lesson_class(db_session: AsyncSession, teacher_id: str) -> str:
    lesson_class_id = f"lc-{uuid4()}"
    db_session.add(
        LessonClass(
            id=lesson_class_id,
            teacher_id=teacher_id,
            name="Test Class",
        )
    )
    await db_session.flush()
    return lesson_class_id


async def _seed_student_with_booking(
    db_session: AsyncSession,
    teacher_id: str,
    student_name: str,
    scheduled: date,
    *,
    lesson_class_id: str | None = None,
    with_subscription: bool = False,
) -> tuple[str, str | None]:
    """Insert one student + (optional) subscription + one active booking."""
    student_id = f"student-{uuid4()}"
    db_session.add(
        Student(
            id=student_id,
            teacher_id=teacher_id,
            name=student_name,
        )
    )
    await db_session.flush()

    subscription_id: str | None = None
    if with_subscription:
        assert lesson_class_id is not None, "Provide lesson_class_id for subscription"
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
        subscription_id = f"sub-{uuid4()}"
        db_session.add(
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
            subscription_id=subscription_id,
            status=BookingStatus.confirmed,
        )
    )
    await db_session.flush()
    return student_id, subscription_id


@pytest.mark.asyncio
async def test_impact_preview_counts_active_bookings(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """GET /impact 가 기간 내 활성 레슨을 학생별로 집계한다."""
    user = await create_test_user(user_id="teacher-x", role="teacher", email="tx@test.com")
    teacher_id = f"{user.id}-prof"

    # 3 distinct students, 3 active bookings inside vacation window
    await _seed_student_with_booking(db_session, teacher_id, "민수", date(2026, 7, 16))
    await _seed_student_with_booking(db_session, teacher_id, "서연", date(2026, 7, 18))
    await _seed_student_with_booking(db_session, teacher_id, "지원", date(2026, 7, 17))
    # Outside window — should NOT be counted
    await _seed_student_with_booking(db_session, teacher_id, "준호", date(2026, 8, 5))
    await db_session.commit()

    response = await client.get(
        "/api/v1/teacher/vacation/impact",
        params={"start": "2026-07-15", "end": "2026-07-20"},
        headers=_headers("teacher-x"),
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["impacted_lesson_count"] == 3
    assert body["impacted_student_count"] == 3


@pytest.mark.asyncio
async def test_register_vacation_rollforward_extends_subscription(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """POST 등록 시 rollForward 옵션이면 영향 받는 수강권의 auto_extended_days 가 증가한다."""
    user = await create_test_user(user_id="teacher-y", role="teacher", email="ty@test.com")
    teacher_id = f"{user.id}-prof"

    lesson_class_id = await _seed_lesson_class(db_session, teacher_id)
    _, sub_id = await _seed_student_with_booking(
        db_session,
        teacher_id,
        "민수",
        date(2026, 7, 18),
        lesson_class_id=lesson_class_id,
        with_subscription=True,
    )
    assert sub_id is not None
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("teacher-y"),
        json={
            "start_date": "2026-07-15",
            "end_date": "2026-07-21",  # 7 days inclusive
            "reason": "여름방학",
            "default_disposition": "rollForward",
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["default_disposition"] == "rollForward"
    assert body["start_date"] == "2026-07-15"
    assert body["end_date"] == "2026-07-21"

    sub = (await db_session.scalars(select(Subscription).where(Subscription.id == sub_id))).one()
    await db_session.refresh(sub)
    assert sub.auto_extended_days == 7, "rollForward 는 영향 수강권 만료일을 휴가 일수만큼 연장한다"


@pytest.mark.asyncio
async def test_register_vacation_invalid_range_returns_4xx(
    client: AsyncClient,
    create_test_user,
):
    """end < start 이면 4xx 응답 (pydantic 422 또는 service 400)."""
    await create_test_user(user_id="teacher-z", role="teacher", email="tz@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("teacher-z"),
        json={
            "start_date": "2026-07-21",
            "end_date": "2026-07-15",
            "default_disposition": "rollForward",
        },
    )
    assert response.status_code in (400, 422), response.text


@pytest.mark.asyncio
async def test_freecancel_does_not_extend_subscription(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """freeCancel 옵션이면 auto_extended_days 가 증가하지 않는다 (만료 연장 없음)."""
    user = await create_test_user(user_id="teacher-w", role="teacher", email="tw@test.com")
    teacher_id = f"{user.id}-prof"

    lesson_class_id = await _seed_lesson_class(db_session, teacher_id)
    _, sub_id = await _seed_student_with_booking(
        db_session,
        teacher_id,
        "민수",
        date(2026, 7, 18),
        lesson_class_id=lesson_class_id,
        with_subscription=True,
    )
    assert sub_id is not None
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("teacher-w"),
        json={
            "start_date": "2026-07-15",
            "end_date": "2026-07-21",
            "default_disposition": "freeCancel",
        },
    )
    assert response.status_code == 201, response.text

    sub = (await db_session.scalars(select(Subscription).where(Subscription.id == sub_id))).one()
    await db_session.refresh(sub)
    assert sub.auto_extended_days == 0
