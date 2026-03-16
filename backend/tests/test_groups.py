"""Tests for group class schedule/booking and no-show endpoints."""

import pytest
from httpx import AsyncClient


async def _create_group_class(client: AsyncClient, headers: dict) -> str:
    """Helper: create a group class via lessons endpoint and return its ID."""
    # Group classes are created via the groups router indirectly;
    # we need to insert directly since there's no dedicated create endpoint on /groups
    # Instead, we'll create a schedule first which requires a group_class_id
    # For testing, we create via DB or use an existing endpoint
    # Since GroupClass is under lessons router, let's use that
    from app.models.schedule_ext import GroupClassSchedule
    # Actually, let's just create a schedule with a fake group_class_id
    return "test-group-class-id"


@pytest.mark.asyncio
async def test_create_group_schedule(client: AsyncClient, auth_headers, create_test_user):
    """POST /groups/schedules should create a group class schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 5,
            "waitlist_capacity": 2,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["group_class_id"] == "gc-1"
    assert data["max_capacity"] == 5
    assert data["status"] == "open"
    assert data["current_bookings"] == 0


@pytest.mark.asyncio
async def test_list_group_schedules(client: AsyncClient, auth_headers, create_test_user):
    """GET /groups/{group_class_id}/schedules should list schedules."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 5,
        },
    )

    response = await client.get("/api/v1/groups/gc-1/schedules", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["total"] == 1


@pytest.mark.asyncio
async def test_cancel_group_schedule(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /groups/schedules/{id}/cancel should set status cancelled."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 5,
        },
    )
    schedule_id = cr.json()["id"]

    response = await client.patch(
        f"/api/v1/groups/schedules/{schedule_id}/cancel",
        headers=auth_headers,
        params={"reason": "강사 사정"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "cancelled"


@pytest.mark.asyncio
async def test_create_group_booking(client: AsyncClient, auth_headers, create_test_user):
    """POST /groups/bookings should book a student into a schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 3,
        },
    )
    schedule_id = cr.json()["id"]

    response = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "student-1"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "confirmed"
    assert data["student_id"] == "student-1"


@pytest.mark.asyncio
async def test_group_booking_waitlist_when_full(client: AsyncClient, auth_headers, create_test_user):
    """Booking when at capacity should go to waitlist."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 1,
            "waitlist_capacity": 2,
        },
    )
    schedule_id = cr.json()["id"]

    # First booking fills capacity
    await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s1"},
    )

    # Second booking goes to waitlist
    response = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s2"},
    )
    assert response.status_code == 201
    assert response.json()["status"] == "waitlist"
    assert response.json()["waitlist_position"] == 1


@pytest.mark.asyncio
async def test_group_booking_full_no_waitlist(client: AsyncClient, auth_headers, create_test_user):
    """Booking when full with no waitlist should return 400."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 1,
        },
    )
    schedule_id = cr.json()["id"]

    await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s1"},
    )

    response = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s2"},
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_cancel_group_booking_promotes_waitlist(client: AsyncClient, auth_headers, create_test_user):
    """Cancelling a confirmed booking should auto-promote first waitlister."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 1,
            "waitlist_capacity": 2,
        },
    )
    schedule_id = cr.json()["id"]

    b1 = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s1"},
    )
    b2 = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "s2"},
    )
    assert b2.json()["status"] == "waitlist"

    # Cancel first booking
    await client.patch(
        f"/api/v1/groups/bookings/{b1.json()['id']}/cancel",
        headers=auth_headers,
    )

    # Check s2 was promoted
    bookings = await client.get(
        f"/api/v1/groups/schedules/{schedule_id}/bookings",
        headers=auth_headers,
    )
    active = [b for b in bookings.json() if b["status"] == "confirmed"]
    assert len(active) == 1
    assert active[0]["student_id"] == "s2"


@pytest.mark.asyncio
async def test_mark_attendance(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /groups/bookings/{id}/attendance should mark attended."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 5,
        },
    )
    b = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": cr.json()["id"], "student_id": "s1"},
    )

    response = await client.patch(
        f"/api/v1/groups/bookings/{b.json()['id']}/attendance",
        headers=auth_headers,
        json={"attended": True},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "attended"


@pytest.mark.asyncio
async def test_mark_no_show(client: AsyncClient, auth_headers, create_test_user):
    """PATCH attendance with attended=false should mark noShow."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-1",
            "start_time": "2026-04-01T10:00:00",
            "end_time": "2026-04-01T11:00:00",
            "max_capacity": 5,
        },
    )
    b = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": cr.json()["id"], "student_id": "s1"},
    )

    response = await client.patch(
        f"/api/v1/groups/bookings/{b.json()['id']}/attendance",
        headers=auth_headers,
        json={"attended": False},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "noShow"


# ---------------------------------------------------------------------------
# No-Show Records
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_no_show_record(client: AsyncClient, auth_headers, create_test_user):
    """POST /groups/no-shows should create a record."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/groups/no-shows",
        headers=auth_headers,
        json={
            "lesson_id": "lesson-1",
            "student_id": "student-1",
            "lesson_date": "2026-03-16",
            "applied_policy": "deductCredit",
            "deducted_credits": 1,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["applied_policy"] == "deductCredit"
    assert data["deducted_credits"] == 1


@pytest.mark.asyncio
async def test_list_no_shows(client: AsyncClient, auth_headers, create_test_user):
    """GET /groups/no-shows should list records for teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/groups/no-shows",
        headers=auth_headers,
        json={"lesson_id": "l1", "student_id": "s1", "lesson_date": "2026-03-16", "applied_policy": "noDeduction"},
    )

    response = await client.get("/api/v1/groups/no-shows", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["total"] == 1
