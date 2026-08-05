"""Slot booking auto-confirms; request booking stays pending (#1107).

SSOT: docs/specs/schedule/student_direct_booking_spec.md (칩 탭 → 즉시 확정,
승인 불필요) + schedule_master.md §1.2 (슬롯 기반 선착순 → 즉시 확정,
autoConfirm=true). The request path (POST /bookings without slot_id) is the
승인 필요 flow and must remain pending.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _headers(user_id: str, role: str = "student") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


_BASE = {
    "teacher_id": "teacher-1107",
    "scheduled_date": "2026-04-10",
    "scheduled_time": "14:00",
    "duration": 60,
}


async def _status_of(db_session: AsyncSession, booking_id: str) -> str:
    from app.models.schedule import LessonBooking

    booking = await db_session.get(LessonBooking, booking_id)
    assert booking is not None
    raw = booking.status
    return raw.value if hasattr(raw, "value") else str(raw)


@pytest.mark.asyncio
async def test_slot_booking_is_confirmed_immediately(client: AsyncClient, create_test_user, db_session: AsyncSession):
    """A slot booking (slot_id present) persists as confirmed — no teacher approval."""
    await create_test_user(user_id="teacher-1107", role="teacher", email="t1107@test.com")
    await create_test_user(user_id="student-1107", role="student", email="s1107@test.com")

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("student-1107"),
        json={
            **_BASE,
            "student_id": "student-1107",
            "student_name": "학생",
            "slot_id": "teacher-1107-2026-04-10-14:00",
        },
    )
    assert response.status_code == 201
    body = response.json()
    booking_id = body["id"]

    assert await _status_of(db_session, booking_id) == "confirmed"


@pytest.mark.asyncio
async def test_request_booking_stays_pending(client: AsyncClient, create_test_user, db_session: AsyncSession):
    """A request booking (no slot_id) stays pending — the 승인 필요 flow is unchanged."""
    await create_test_user(user_id="teacher-1107", role="teacher", email="t1107@test.com")
    await create_test_user(user_id="student-1107", role="student", email="s1107@test.com")

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("student-1107"),
        json={**_BASE, "student_id": "student-1107"},
    )
    assert response.status_code == 201
    booking_id = response.json()["id"]

    assert await _status_of(db_session, booking_id) == "pending"


@pytest.mark.asyncio
async def test_slot_booking_overlap_still_rejected(client: AsyncClient, create_test_user, db_session: AsyncSession):
    """Auto-confirm must not bypass the existing overlap guard (#237)."""
    await create_test_user(user_id="teacher-1107", role="teacher", email="t1107@test.com")
    await create_test_user(user_id="student-1107", role="student", email="s1107@test.com")

    first = await client.post(
        "/api/v1/bookings",
        headers=_headers("student-1107"),
        json={**_BASE, "student_id": "student-1107", "student_name": "학생", "slot_id": "teacher-1107-2026-04-10-14:00"},
    )
    assert first.status_code == 201

    overlap = await client.post(
        "/api/v1/bookings",
        headers=_headers("student-1107"),
        json={
            **_BASE,
            "scheduled_time": "14:30",
            "student_id": "student-1107",
            "student_name": "학생",
            "slot_id": "teacher-1107-2026-04-10-14:30",
        },
    )
    assert overlap.status_code == 409
