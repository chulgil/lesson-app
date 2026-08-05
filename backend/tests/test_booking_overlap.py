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


@pytest.mark.asyncio
async def test_check_booking_overlap_locks_teacher_row(db_session, create_test_user, monkeypatch):
    """Regression: _check_booking_overlap must lock the teacher row first.

    Locking existing overlapping bookings alone can't prevent two concurrent
    requests for a brand-new (not-yet-booked) slot from both seeing zero
    conflicts and both inserting — there's nothing to lock via
    with_for_update() on the booking table when no row exists yet. Locking
    the teacher row instead serializes concurrent booking-creation attempts
    for that teacher, closing the phantom-insert window.

    True concurrency is not reproducible on SQLite (same caveat as
    test_deduct_idempotency.py), so this asserts the lock is structurally
    present.
    """
    import datetime

    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import AsyncSession

    from app.models.teacher import Teacher
    from app.services.schedule_service import ScheduleService

    await create_test_user(user_id="test-user-id", role="teacher")

    service = ScheduleService(db_session)

    captured_statements = []
    original_scalar = db_session.scalar

    async def _spy_scalar(statement, *args, **kwargs):
        captured_statements.append(statement)
        return await original_scalar(statement, *args, **kwargs)

    monkeypatch.setattr(db_session, "scalar", _spy_scalar)

    await service._check_booking_overlap(
        teacher_id="test-user-id",
        scheduled_date=datetime.date(2026, 5, 10),
        scheduled_time="14:00",
        duration=60,
    )

    teacher_lookups = [
        stmt
        for stmt in captured_statements
        if hasattr(stmt, "column_descriptions")
        and any(col.get("entity") is Teacher for col in stmt.column_descriptions)
    ]
    assert teacher_lookups, "_check_booking_overlap must lock the teacher row before checking for conflicts"
    assert any(stmt._for_update_arg is not None for stmt in teacher_lookups), (
        "teacher row lookup must use with_for_update() to serialize concurrent booking creation"
    )
