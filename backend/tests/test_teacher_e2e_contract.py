"""Phase 28 — 선생님 가입→스케줄 운영 FE contract 정합성 regression.

선생님이 FE 에서 trial 옵션 선택 / 레슨 완료 / 자기 프로필 조회 시 흐름 막힘 없도록.
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
        status=BookingStatus.pending,
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
async def test_approve_booking_without_body_remains_backward_compatible(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """body 없이 호출하면 기존 동작 — status=confirmed."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(f"/api/v1/bookings/{booking_id}/approve", headers=auth_headers)

    assert response.status_code == 200, response.text
    assert response.json()["status"] == "confirmed"


@pytest.mark.asyncio
async def test_approve_with_selected_option_id_records_in_notes(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE approveTrialLesson — selected_option_id 가 notes 에 prefix 로 기록."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/bookings/{booking_id}/approve",
        headers=auth_headers,
        json={"selected_option_id": "option-1"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "confirmed"
    assert "[selected_option_id: option-1]" in (body["notes"] or "")


@pytest.mark.asyncio
async def test_approve_with_status_completed_marks_completed(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE completeLesson — status='completed' 면 BookingStatus.completed."""
    await _setup(create_test_user)
    booking_id = await _seed_booking(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/bookings/{booking_id}/approve",
        headers=auth_headers,
        json={"status": "completed"},
    )

    assert response.status_code == 200, response.text
    assert response.json()["status"] == "completed"


@pytest.mark.asyncio
async def test_teacher_response_includes_bank_account_id_and_created_at(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """FE BankAccount 디코딩 — bank_name/account_number 있으면 bank_account_id/created_at 채움."""
    from sqlalchemy import select

    from app.models.teacher import Teacher

    await _setup(create_test_user)
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    teacher.bank_name = "농협"
    teacher.account_number = "1234567"
    teacher.account_holder = "홍선생"
    await db_session.flush()
    await db_session.commit()

    response = await client.get("/api/v1/teachers/me/profile", headers=auth_headers)

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["bank_account_id"] == teacher.id
    assert body["bank_account_created_at"] is not None


@pytest.mark.asyncio
async def test_teacher_response_bank_account_null_when_no_bank_info(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """은행 정보가 없으면 bank_account_id/created_at 도 None."""
    await _setup(create_test_user)
    await db_session.commit()

    response = await client.get("/api/v1/teachers/me/profile", headers=auth_headers)

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["bank_account_id"] is None
    assert body["bank_account_created_at"] is None


@pytest.mark.asyncio
async def test_teacher_nickname_roundtrip_visible_in_response(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """#1145 — 선생님이 설정한 nickname 이 저장되고 teacher 응답에 노출된다.

    nickname 은 학생에게 보일 호칭. TeacherUpdate 가 받아 저장하고
    TeacherResponse 가 다시 노출해야 학생 화면(Teacher.displayName)이 볼 수 있다.
    """
    await _setup(create_test_user)
    await db_session.commit()

    # write — 선생님이 학생에게 보일 호칭을 설정
    put = await client.put(
        "/api/v1/teachers/me/profile",
        headers=auth_headers,
        json={"nickname": "지수쌤"},
    )
    assert put.status_code == 200, put.text
    assert put.json()["nickname"] == "지수쌤"

    # read — 재조회 시에도 유지(드롭되지 않음)
    got = await client.get("/api/v1/teachers/me/profile", headers=auth_headers)
    assert got.status_code == 200, got.text
    assert got.json()["nickname"] == "지수쌤"
