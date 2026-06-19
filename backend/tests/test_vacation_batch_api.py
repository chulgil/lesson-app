"""Tests for POST /api/v1/teacher/vacation/batch — 다구간 휴가 (#768 ②).

배치 계약: 사유/학생별 예외는 전 구간 공유, 보상옵션(disposition)은 구간별.
각 구간은 별도 VacationPeriod 로 저장되며 한 요청 = 한 트랜잭션.
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
    db_session.add(LessonClass(id=lesson_class_id, teacher_id=teacher_id, name="Test Class"))
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
    student_id = f"student-{uuid4()}"
    db_session.add(Student(id=student_id, teacher_id=teacher_id, name=student_name))
    await db_session.flush()

    subscription_id: str | None = None
    if with_subscription:
        assert lesson_class_id is not None
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
async def test_batch_creates_multiple_periods(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """2개의 비겹침 구간 → 201 + 구간 수만큼 VacationPeriod 생성."""
    await create_test_user(user_id="batch-a", role="teacher", email="ba@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-a"),
        json={
            "reason": "여름방학",
            "segments": [
                {"start_date": "2026-07-15", "end_date": "2026-07-17", "default_disposition": "rollForward"},
                {"start_date": "2026-07-20", "end_date": "2026-07-22", "default_disposition": "rollForward"},
            ],
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["total_count"] == 2
    assert len(body["vacations"]) == 2
    # 공유 사유가 모든 구간에 적용된다.
    assert all(v["reason"] == "여름방학" for v in body["vacations"])


@pytest.mark.asyncio
async def test_batch_per_segment_disposition(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """구간별 보상옵션: rollForward 구간만 수강권을 연장한다."""
    user = await create_test_user(user_id="batch-b", role="teacher", email="bb@test.com")
    teacher_id = f"{user.id}-prof"

    lesson_class_id = await _seed_lesson_class(db_session, teacher_id)
    _, sub_a = await _seed_student_with_booking(
        db_session,
        teacher_id,
        "민수",
        date(2026, 7, 16),
        lesson_class_id=lesson_class_id,
        with_subscription=True,
    )
    _, sub_b = await _seed_student_with_booking(
        db_session,
        teacher_id,
        "서연",
        date(2026, 7, 21),
        lesson_class_id=lesson_class_id,
        with_subscription=True,
    )
    assert sub_a is not None and sub_b is not None
    await db_session.commit()

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-b"),
        json={
            "segments": [
                {"start_date": "2026-07-15", "end_date": "2026-07-17", "default_disposition": "rollForward"},
                {"start_date": "2026-07-20", "end_date": "2026-07-22", "default_disposition": "freeCancel"},
            ],
        },
    )
    assert response.status_code == 201, response.text

    sa = (await db_session.scalars(select(Subscription).where(Subscription.id == sub_a))).one()
    sb = (await db_session.scalars(select(Subscription).where(Subscription.id == sub_b))).one()
    await db_session.refresh(sa)
    await db_session.refresh(sb)
    # 구간1(rollForward, 3일) → subA 만 연장. 구간2(freeCancel) → subB 연장 없음.
    assert sa.auto_extended_days == 3
    assert sb.auto_extended_days == 0


@pytest.mark.asyncio
async def test_batch_shares_per_student_override(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학생별 예외는 모든 구간에 동일하게 적용된다."""
    await create_test_user(user_id="batch-c", role="teacher", email="bc@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-c"),
        json={
            "per_student_disposition": {"stu-x": "freeCancel"},
            "segments": [
                {"start_date": "2026-07-15", "end_date": "2026-07-17", "default_disposition": "rollForward"},
                {"start_date": "2026-07-20", "end_date": "2026-07-22", "default_disposition": "rollForward"},
            ],
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert len(body["vacations"]) == 2
    for v in body["vacations"]:
        assert v["per_student_disposition"] == {"stu-x": "freeCancel"}


@pytest.mark.asyncio
async def test_batch_empty_segments_returns_4xx(
    client: AsyncClient,
    create_test_user,
):
    """빈 segments → 4xx (요청 거부)."""
    await create_test_user(user_id="batch-d", role="teacher", email="bd@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-d"),
        json={"segments": []},
    )
    assert response.status_code in (400, 422), response.text


@pytest.mark.asyncio
async def test_batch_overlapping_segments_returns_400(
    client: AsyncClient,
    create_test_user,
):
    """겹치는 구간 → 400 (이중 처리로 인한 데이터 무결성 훼손 방지)."""
    await create_test_user(user_id="batch-e", role="teacher", email="be@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-e"),
        json={
            "segments": [
                {"start_date": "2026-07-15", "end_date": "2026-07-20", "default_disposition": "rollForward"},
                {"start_date": "2026-07-18", "end_date": "2026-07-22", "default_disposition": "rollForward"},
            ],
        },
    )
    assert response.status_code in (400, 422), response.text


@pytest.mark.asyncio
async def test_batch_invalid_segment_range_returns_4xx(
    client: AsyncClient,
    create_test_user,
):
    """구간 내부 end < start → 4xx."""
    await create_test_user(user_id="batch-f", role="teacher", email="bf@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation/batch",
        headers=_headers("batch-f"),
        json={
            "segments": [
                {"start_date": "2026-07-22", "end_date": "2026-07-15", "default_disposition": "rollForward"},
            ],
        },
    )
    assert response.status_code in (400, 422), response.text
