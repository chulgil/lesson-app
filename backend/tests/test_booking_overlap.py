"""Booking overlap validation tests (#237)."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_booking_rejects_overlapping_slot(
    client: AsyncClient, auth_headers, create_test_user
):
    """POST /api/v1/bookings returns 409 when time slot overlaps."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # First booking: 14:00-15:00
    resp1 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert resp1.status_code == 201

    # Overlapping booking: 14:30-15:30
    resp2 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "14:30",
            "duration": 60,
        },
    )
    assert resp2.status_code == 409
    assert "이미 예약" in resp2.json()["detail"]


@pytest.mark.asyncio
async def test_create_booking_allows_adjacent_slot(
    client: AsyncClient, auth_headers, create_test_user
):
    """Adjacent slots (14:00-15:00 then 15:00-16:00) should be allowed."""
    await create_test_user(user_id="test-user-id", role="teacher")

    resp1 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert resp1.status_code == 201

    # Adjacent: starts exactly when previous ends
    resp2 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "15:00",
            "duration": 60,
        },
    )
    assert resp2.status_code == 201


@pytest.mark.asyncio
async def test_create_booking_allows_different_date(
    client: AsyncClient, auth_headers, create_test_user
):
    """Same time on different dates should be allowed."""
    await create_test_user(user_id="test-user-id", role="teacher")

    resp1 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert resp1.status_code == 201

    resp2 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-11",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert resp2.status_code == 201


@pytest.mark.asyncio
async def test_create_makeup_booking_rejects_overlap(
    client: AsyncClient, auth_headers, create_test_user
):
    """POST /api/v1/bookings/makeup returns 409 on overlap."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a regular booking first: 10:00-11:00
    resp1 = await client.post(
        "/api/v1/bookings",
        headers=auth_headers,
        json={
            "teacher_id": "test-user-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "10:00",
            "duration": 60,
        },
    )
    assert resp1.status_code == 201

    # Makeup booking overlapping: 10:30-11:30
    resp2 = await client.post(
        "/api/v1/bookings/makeup",
        headers=auth_headers,
        json={
            "student_id": "some-student-id",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "10:30",
            "duration": 60,
            "reason": "makeup lesson",
        },
    )
    assert resp2.status_code == 409
    assert "이미 예약" in resp2.json()["detail"]
