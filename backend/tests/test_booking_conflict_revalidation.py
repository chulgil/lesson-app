"""Conflict re-validation on booking approve / change-request.

0702 audit follow-up (M4 부산물): change_booking 이 새 시간을 무검증 반영하고
approve_booking 이 재검증 없이 확정해, changeRequested 로 이동한 충돌 시간이
approve 에서 그대로 확정되는 구멍이 있었다. M4(POST /lessons)와 동일 시맨틱:
활성 레슨+예약 겹침 → 409, 자기 자신 제외, 휴가/운영시간은 BE 강제 제외.
"""

from datetime import date as _date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _seed_teacher(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")


async def _create_booking(
    client: AsyncClient,
    auth_headers,
    *,
    time: str,
    booking_date: str = "2026-04-01",
) -> str:
    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": booking_date,
            "scheduled_time": time,
            "duration": 60,
        },
    )
    assert response.status_code == 201
    return response.json()["id"]


# ---------------------------------------------------------------------------
# change-request
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_change_booking_to_conflicting_time_returns_409(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Changing onto another active booking's slot is rejected and nothing mutates."""
    await _seed_teacher(create_test_user)
    await _create_booking(client, auth_headers, time="14:00")
    target_id = await _create_booking(client, auth_headers, time="16:00")

    response = await client.post(
        f"/api/v1/bookings/{target_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2026-04-01", "new_time": "14:30"},
    )
    assert response.status_code == 409

    from app.models.schedule import LessonBooking

    booking = await db_session.get(LessonBooking, target_id)
    assert booking.scheduled_time == "16:00"
    assert str(booking.status.value if hasattr(booking.status, "value") else booking.status) != "changeRequested"


@pytest.mark.asyncio
async def test_change_booking_to_free_time_succeeds(client: AsyncClient, auth_headers, create_test_user):
    await _seed_teacher(create_test_user)
    target_id = await _create_booking(client, auth_headers, time="16:00")

    response = await client.post(
        f"/api/v1/bookings/{target_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2026-04-01", "new_time": "18:00"},
    )
    assert response.status_code == 200
    assert response.json()["scheduled_time"] == "18:00"


@pytest.mark.asyncio
async def test_change_booking_overlap_with_lesson_returns_409(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """The new time is checked against Lessons too (not just bookings)."""
    from app.models.lesson import Lesson

    await _seed_teacher(create_test_user)
    target_id = await _create_booking(client, auth_headers, time="16:00")

    db_session.add(
        Lesson(
            student_id="student-001",
            student_name="student-001",
            teacher_id="test-user-id",
            instrument="violin",
            date=_date(2026, 4, 1),
            start_time="14:00",
            duration=60,
        )
    )
    await db_session.flush()

    response = await client.post(
        f"/api/v1/bookings/{target_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2026-04-01", "new_time": "14:30"},
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_change_booking_same_time_is_not_a_conflict(client: AsyncClient, auth_headers, create_test_user):
    """Re-submitting the booking's own slot must not self-collide."""
    await _seed_teacher(create_test_user)
    target_id = await _create_booking(client, auth_headers, time="16:00")

    response = await client.post(
        f"/api/v1/bookings/{target_id}/change-request",
        headers=auth_headers,
        json={"new_date": "2026-04-01", "new_time": "16:00"},
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# approve
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_approve_booking_without_conflict_succeeds(client: AsyncClient, auth_headers, create_test_user):
    """Self-exclusion: the pending booking itself must not block its approval."""
    await _seed_teacher(create_test_user)
    booking_id = await _create_booking(client, auth_headers, time="10:00")

    response = await client.patch(
        f"/api/v1/bookings/{booking_id}/approve",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "confirmed"


@pytest.mark.asyncio
async def test_approve_booking_with_conflict_returns_409(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A booking raced/moved onto an occupied slot is rejected at approval."""
    await _seed_teacher(create_test_user)
    await _create_booking(client, auth_headers, time="14:00")
    target_id = await _create_booking(client, auth_headers, time="16:00")

    # Simulate the pre-fix state: time moved onto the occupied slot without
    # validation (legacy changeRequested rows / direct races).
    from app.models.schedule import LessonBooking

    target = await db_session.get(LessonBooking, target_id)
    target.scheduled_time = "14:30"
    await db_session.flush()

    response = await client.patch(
        f"/api/v1/bookings/{target_id}/approve",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 409

    await db_session.refresh(target)
    status_value = target.status.value if hasattr(target.status, "value") else target.status
    assert str(status_value) != "confirmed"


@pytest.mark.asyncio
async def test_approve_as_completed_skips_conflict_check(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Marking completed records a historical fact — never blocked by overlap."""
    await _seed_teacher(create_test_user)
    await _create_booking(client, auth_headers, time="14:00")
    target_id = await _create_booking(client, auth_headers, time="16:00")

    from app.models.schedule import LessonBooking

    target = await db_session.get(LessonBooking, target_id)
    target.scheduled_time = "14:30"
    await db_session.flush()

    response = await client.patch(
        f"/api/v1/bookings/{target_id}/approve",
        headers=auth_headers,
        json={"status": "completed"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "completed"
