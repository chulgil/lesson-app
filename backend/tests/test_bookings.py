"""Booking endpoint tests."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_list_bookings(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/bookings returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/bookings", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_create_booking(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/bookings creates a booking request."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-03-15",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["teacher_id"] == "test-user-id"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_booking_without_subscription_is_manual_origin(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """POST /api/v1/bookings sets booking origin null when subscription_id is not provided."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-03-16",
            "scheduled_time": "14:30",
            "duration": 60,
        },
    )
    assert response.status_code == 201
    booking_id = response.json()["id"]

    from app.models.schedule import LessonBooking

    booking = await db_session.get(LessonBooking, booking_id)
    assert booking is not None
    assert booking.subscription_id is None
    assert response.json()["subscription_id"] is None


@pytest.mark.asyncio
async def test_list_makeup_bookings(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/bookings/makeup returns makeup lessons list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/bookings/makeup", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


# ---------------------------------------------------------------------------
# IDOR ownership regression tests (#460)
# ---------------------------------------------------------------------------


def _bearer(user_id: str, role: str) -> dict[str, str]:
    """Build Authorization headers for an arbitrary user."""
    from app.core.security import create_access_token

    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _seed_booking(client: AsyncClient, auth_headers, create_test_user) -> str:
    """Create owner teacher + self-booked student and return a booking id.

    The booking's teacher_id is the teacher's user id and the student_id is the
    student's user id (self-book convention: data.student_id or current_user.id).
    """
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="owner-student-id",
        role="student",
        name="Owner Student",
        email="owner-student@test.com",
    )

    response = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "student_id": "owner-student-id",
            "scheduled_date": "2026-04-01",
            "scheduled_time": "10:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201
    return response.json()["id"]


@pytest.mark.asyncio
async def test_get_booking_other_user_forbidden(client: AsyncClient, auth_headers, create_test_user):
    """A different authenticated user cannot GET someone else's booking."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)
    await create_test_user(user_id="attacker-id", role="teacher", email="attacker@test.com")

    response = await client.get(f"/api/v1/bookings/{booking_id}", headers=_bearer("attacker-id", "teacher"))
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_update_booking_other_user_forbidden(client: AsyncClient, auth_headers, create_test_user):
    """A different authenticated user cannot UPDATE someone else's booking."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)
    await create_test_user(user_id="attacker-id", role="teacher", email="attacker@test.com")

    response = await client.put(
        f"/api/v1/bookings/{booking_id}",
        headers=_bearer("attacker-id", "teacher"),
        json={"duration": 30},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_delete_booking_other_user_forbidden(client: AsyncClient, auth_headers, create_test_user):
    """A different authenticated user cannot DELETE someone else's booking."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)
    await create_test_user(user_id="attacker-id", role="teacher", email="attacker@test.com")

    response = await client.delete(f"/api/v1/bookings/{booking_id}", headers=_bearer("attacker-id", "teacher"))
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_cancel_booking_other_user_forbidden(client: AsyncClient, auth_headers, create_test_user):
    """A different authenticated user cannot CANCEL someone else's booking."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)
    await create_test_user(user_id="attacker-id", role="teacher", email="attacker@test.com")

    response = await client.patch(
        f"/api/v1/bookings/{booking_id}/cancel",
        headers=_bearer("attacker-id", "teacher"),
        json={"reason": "nope"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_change_booking_other_user_forbidden(client: AsyncClient, auth_headers, create_test_user):
    """A different authenticated user cannot request a CHANGE on someone else's booking."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)
    await create_test_user(user_id="attacker-id", role="teacher", email="attacker@test.com")

    response = await client.post(
        f"/api/v1/bookings/{booking_id}/change-request",
        headers=_bearer("attacker-id", "teacher"),
        json={"new_date": "2026-04-05", "new_time": "11:00"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_get_booking_owner_teacher_succeeds(client: AsyncClient, auth_headers, create_test_user):
    """The teacher who owns the booking can still read it."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)

    response = await client.get(f"/api/v1/bookings/{booking_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["id"] == booking_id


@pytest.mark.asyncio
async def test_get_booking_owner_student_succeeds(client: AsyncClient, auth_headers, create_test_user):
    """The student on the booking can still read it."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)

    response = await client.get(
        f"/api/v1/bookings/{booking_id}",
        headers=_bearer("owner-student-id", "student"),
    )
    assert response.status_code == 200
    assert response.json()["id"] == booking_id


@pytest.mark.asyncio
async def test_cancel_booking_owner_student_succeeds(client: AsyncClient, auth_headers, create_test_user):
    """The student on the booking can cancel it (either party may cancel)."""
    booking_id = await _seed_booking(client, auth_headers, create_test_user)

    response = await client.patch(
        f"/api/v1/bookings/{booking_id}/cancel",
        headers=_bearer("owner-student-id", "student"),
        json={"reason": "schedule conflict"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "cancelled"
