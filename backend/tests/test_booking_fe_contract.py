"""Phase 26 — 학생 가입→스케줄 조절 FE contract 정합성 regression.

학생이 FE 에서 API 호출 시 막힘/UI 빈칸이 없도록 보장.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_booking(db_session: AsyncSession, teacher_user_id: str, student_id: str) -> str:
    from app.models.schedule import BookingStatus, LessonBooking
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id=student_id,
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    return booking.id


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="김학생",
        email="student@test.com",
    )


@pytest.mark.asyncio
async def test_booking_response_includes_teacher_and_student_name(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE 가 UI 빈칸 없이 받도록 teacher_name / student_name join 응답."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.get(f"/api/v1/bookings/{booking_id}", headers=auth_headers)

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["teacher_name"] == "홍선생"
    assert body["student_name"] == "김학생"
    # FE 호환 alias.
    assert body["lesson_date"] == "2126-07-06"
    assert body["start_time"] == "14:00"
    assert body["duration_minutes"] == 60


@pytest.mark.asyncio
async def test_booking_update_with_duration_minutes_alias(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE 가 duration_minutes 키로 보내도 BE 가 수용."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.put(
        f"/api/v1/bookings/{booking_id}",
        headers=auth_headers,
        json={"duration_minutes": 90, "instrument": "violin"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["duration"] == 90
    assert body["duration_minutes"] == 90
    assert body["instrument"] == "violin"
    # date/time 변경 없음 → 기존 status 유지.
    assert body["status"] != "changeRequested"


@pytest.mark.asyncio
async def test_booking_update_with_date_change_marks_change_requested(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE 가 PUT 으로 date 변경 → BE 가 status=changeRequested 로 일관 마킹."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.put(
        f"/api/v1/bookings/{booking_id}",
        headers=auth_headers,
        json={"scheduled_date": "2126-07-13", "scheduled_time": "15:00"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["scheduled_date"] == "2126-07-13"
    assert body["scheduled_time"] == "15:00"
    # 변경 의도 → status changeRequested.
    assert body["status"] == "changeRequested"


@pytest.mark.asyncio
async def test_refresh_token_response_includes_non_null_refresh_token(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """RefreshTokenResponse 의 refresh_token 은 non-null — FE TypeError 방지."""
    from app.core.security import create_refresh_token

    await _setup(create_test_user)
    await db_session.commit()
    refresh_token = create_refresh_token(data={"sub": "test-user-id"})

    response = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": refresh_token},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert isinstance(body["access_token"], str) and body["access_token"]
    assert isinstance(body["refresh_token"], str) and body["refresh_token"]
