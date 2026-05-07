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
