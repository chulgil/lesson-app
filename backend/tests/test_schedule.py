"""Schedule endpoint tests."""

import datetime as _dt

import pytest
from httpx import AsyncClient

from app.models.lesson import Lesson, LessonSource
from app.models.schedule import LessonBooking
from app.models.student import Student
from app.models.subscription import Subscription


@pytest.mark.asyncio
async def test_get_availability(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/schedule/availability returns teacher availability."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/schedule/availability", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_set_availability(client: AsyncClient, auth_headers, create_test_user):
    """PUT /api/v1/schedule/availability sets weekly availability."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,
                    "time_slots": [
                        {"start_time": "09:00", "end_time": "18:00"},
                    ],
                },
                {
                    "day_of_week": 3,
                    "time_slots": [
                        {"start_time": "10:00", "end_time": "17:00"},
                    ],
                },
            ],
        },
    )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_student_can_get_public_teacher_availability_by_teacher_id(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Students need the target teacher's weekly schedules for request slots."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-public-availability@test.com",
    )

    saved = await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "weekly_schedules": [
                {
                    "id": "ws_mon_1500",
                    "day_of_week": 0,
                    "start_time": "15:00",
                    "end_time": "18:00",
                    "is_active": True,
                }
            ],
            "slot_duration_minutes": 60,
        },
    )
    assert saved.status_code == 200

    response = await client.get(
        "/api/v1/schedule/availability/test-user-id",
        headers=student_auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["teacher_id"] == "test-user-id"
    assert data["weekly_schedules"] == [
        {
            "id": "0-15:00-18:00",
            "day_of_week": 0,
            "start_time": "15:00",
            "end_time": "18:00",
            "is_active": True,
        }
    ]


@pytest.mark.asyncio
async def test_get_weekly_schedule(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/schedule/weekly returns merged weekly schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/schedule/weekly", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_weekly_schedule_includes_manual_lessons(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/schedule/weekly should include lessons created by teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")

    lesson_date = _dt.date(2026, 3, 10)  # Tuesday
    create_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": str(lesson_date),
            "start_time": "14:00",
            "duration": 60,
            "instrument": "piano",
        },
    )
    assert create_resp.status_code == 201

    response = await client.get(
        "/api/v1/schedule/weekly",
        headers=auth_headers,
        params={"week_start": "2026-03-09"},
    )
    assert response.status_code == 200
    days = response.json()["days"]
    assert str(lesson_date) in days
    day_events = days[str(lesson_date)]
    lesson_events = [evt for evt in day_events if evt.get("type") == "lesson"]
    assert any(evt.get("lesson_source") == "manual" for evt in lesson_events)


@pytest.mark.asyncio
async def test_weekly_schedule_booking_event_keeps_subscription_session_metadata(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Subscription-generated booking/lesson duplicate slots must still expose lesson session metadata."""
    await create_test_user(user_id="test-user-id", role="teacher")
    lesson_date = _dt.date(2026, 3, 10)
    student = Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="piano")
    subscription = Subscription(
        id="sub-001",
        student_id="student-001",
        membership_id="membership-001",
        type="monthly",
        total_lessons=4,
        amount=200000,
    )
    booking = LessonBooking(
        id="booking-001",
        teacher_id="test-user-id-prof",
        student_id="student-001",
        lesson_type="regular",
        scheduled_date=lesson_date,
        scheduled_time="14:00",
        duration=60,
        instrument="piano",
        subscription_id="sub-001",
        status="confirmed",
    )
    lesson = Lesson(
        id="lesson-001",
        teacher_id="test-user-id-prof",
        student_id="student-001",
        student_name="Student",
        instrument="piano",
        date=lesson_date,
        start_time="14:00",
        duration=60,
        subscription_id="sub-001",
        session_number=2,
        lesson_source=LessonSource.subscription_generated,
    )
    db_session.add_all([student, subscription, booking, lesson])
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/weekly",
        headers=auth_headers,
        params={"week_start": "2026-03-09"},
    )

    assert response.status_code == 200
    events = response.json()["days"][str(lesson_date)]
    booking_events = [event for event in events if event.get("booking_id") == "booking-001"]
    assert len(booking_events) == 1
    assert booking_events[0]["subscription_id"] == "sub-001"
    assert booking_events[0]["session_number"] == 2
    assert booking_events[0]["lesson_source"] == "subscriptionGenerated"
    assert booking_events[0]["lesson_id"] == "lesson-001"


@pytest.mark.asyncio
async def test_weekly_schedule_includes_subscription_generated_lessons(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """GET /api/v1/schedule/weekly should include subscription-generated lessons."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="수강생",
        email="student-subscription@test.com",
    )

    student_response = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "수강생", "instrument": "piano"},
    )
    assert student_response.status_code == 201
    student_id = student_response.json()["id"]

    subscription_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "type": "package",
            "total_lessons": 4,
            "amount": 200000,
        },
    )
    assert subscription_response.status_code == 201
    subscription_id = subscription_response.json()["id"]

    lesson_date = _dt.date(2026, 3, 10)  # Tuesday
    db_session.add(
        Lesson(
            student_id=student_id,
            teacher_id="test-user-id",
            student_name="수강생",
            instrument="piano",
            date=lesson_date,
            start_time="15:00",
            duration=60,
            status="scheduled",
            lesson_source=LessonSource.subscription_generated,
            subscription_id=subscription_id,
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/weekly",
        headers=auth_headers,
        params={"week_start": "2026-03-09"},
    )
    assert response.status_code == 200

    days = response.json()["days"]
    assert str(lesson_date) in days
    day_events = days[str(lesson_date)]
    lesson_events = [evt for evt in day_events if evt.get("type") == "lesson"]
    assert any(evt.get("lesson_source") == "subscriptionGenerated" for evt in lesson_events)


@pytest.mark.asyncio
async def test_available_slots_blocks_manual_lesson(client: AsyncClient, auth_headers, create_test_user):
    """Manual lesson records should block newly computed booking slots."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,  # Tuesday
                    "time_slots": [
                        {"start_time": "10:00", "end_time": "18:00"},
                    ],
                }
            ]
        },
    )

    await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2026-03-10",
            "start_time": "14:00",
            "duration": 60,
            "instrument": "piano",
        },
    )

    response = await client.get(
        "/api/v1/schedule/slots",
        headers=auth_headers,
        params={"teacher_id": "test-user-id", "date": "2026-03-10"},
    )
    assert response.status_code == 200
    slots = response.json()["slots"]
    blocked_14 = [slot for slot in slots if slot["start_time"] == "14:00"]
    assert blocked_14
    assert blocked_14[0]["status"] == "booked"


@pytest.mark.asyncio
async def test_weekly_schedule_includes_full_day_exception(client: AsyncClient, auth_headers, create_test_user):
    """Weekly schedule should include teacher holiday/vacation as exceptions."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Set base availability so week has at least one visible slot.
    await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,  # Tuesday
                    "time_slots": [
                        {
                            "start_time": "10:00",
                            "end_time": "18:00",
                        }
                    ],
                }
            ]
        },
    )

    exception_resp = await client.post(
        "/api/v1/schedule/exceptions",
        headers=auth_headers,
        json={
            "type": "holiday",
            "start_date": "2026-03-10",
            "end_date": "2026-03-11",
            "reason": "긴급 휴무",
        },
    )
    assert exception_resp.status_code == 201

    response = await client.get(
        "/api/v1/schedule/weekly",
        headers=auth_headers,
        params={"week_start": "2026-03-09"},
    )
    assert response.status_code == 200

    days = response.json()["days"]
    day_events = days.get("2026-03-10", [])
    exceptions = [evt for evt in day_events if evt.get("type") == "exception"]
    assert exceptions
    assert exceptions[0]["exception_type"] == "holiday"


@pytest.mark.asyncio
async def test_weekly_schedule_includes_partial_day_exception(client: AsyncClient, auth_headers, create_test_user):
    """Weekly schedule should include partial-day vacation blocks."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,
                    "time_slots": [
                        {
                            "start_time": "09:00",
                            "end_time": "20:00",
                        }
                    ],
                }
            ]
        },
    )

    exception_resp = await client.post(
        "/api/v1/schedule/exceptions",
        headers=auth_headers,
        json={
            "type": "vacation",
            "start_date": "2026-03-10",
            "end_date": "2026-03-10",
            "start_time": "13:00",
            "end_time": "15:00",
            "reason": "오후 오피스 미팅",
        },
    )
    assert exception_resp.status_code == 201

    response = await client.get(
        "/api/v1/schedule/weekly",
        headers=auth_headers,
        params={"week_start": "2026-03-09"},
    )
    assert response.status_code == 200

    day_events = response.json()["days"].get("2026-03-10", [])
    exceptions = [
        evt
        for evt in day_events
        if evt.get("type") == "exception" and evt.get("exception_type") == "vacation"
    ]
    assert exceptions
    assert exceptions[0]["start_time"] == "13:00"
    assert exceptions[0]["end_time"] == "15:00"
