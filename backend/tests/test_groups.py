"""Tests for group class schedule/booking and no-show endpoints."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _ensure_group_class(
    db_session: AsyncSession, teacher_user_id: str = "test-user-id", class_id: str = "gc-1"
) -> str:
    """Helper: 테스트용 GroupClass 를 직접 DB 에 삽입하고 ID 를 반환.

    Group class ownership 검증이 추가된 이후, 테스트는 실제 GroupClass row 가 필요하다.
    teacher_user_id 의 Teacher.id 와 매핑하여 그 강사 소유 클래스로 만든다.
    """
    from sqlalchemy import select

    from app.models.schedule import GroupClass, GroupClassType
    from app.models.teacher import Teacher

    teacher_profile_id = await db_session.scalar(select(Teacher.id).where(Teacher.user_id == teacher_user_id))
    if teacher_profile_id is None:
        teacher_profile_id = teacher_user_id
    existing = await db_session.scalar(select(GroupClass).where(GroupClass.id == class_id))
    if existing is not None:
        return class_id
    group_class = GroupClass(
        id=class_id,
        teacher_id=teacher_profile_id,
        name="Test Group Class",
        type=GroupClassType.regular,
        max_capacity=10,
        duration_minutes=60,
        booking_deadline_minutes=60,
        cancel_deadline_minutes=1440,
        is_active=True,
    )
    db_session.add(group_class)
    await db_session.flush()
    return class_id


async def _ensure_student(
    db_session: AsyncSession, student_id: str, teacher_user_id: str = "test-user-id", name: str = "테스트 학생"
) -> str:
    """Helper: 테스트용 Student row 생성 (teacher 소속).

    no-show 등 student ownership 검증이 추가된 이후 student 가 실제 DB 에 존재해야 한다.
    """
    from sqlalchemy import select

    from app.models.student import Student
    from app.models.teacher import Teacher

    teacher_profile_id = await db_session.scalar(select(Teacher.id).where(Teacher.user_id == teacher_user_id))
    if teacher_profile_id is None:
        teacher_profile_id = teacher_user_id
    existing = await db_session.scalar(select(Student).where(Student.id == student_id))
    if existing is not None:
        return student_id
    student = Student(
        id=student_id,
        teacher_id=teacher_profile_id,
        name=name,
        instrument="piano",
    )
    db_session.add(student)
    await db_session.flush()
    return student_id


@pytest.mark.asyncio
async def test_create_group_schedule(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """POST /groups/schedules should create a group class schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_list_group_schedules(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """GET /groups/{group_class_id}/schedules should list schedules."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_cancel_group_schedule(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """PATCH /groups/schedules/{id}/cancel should set status cancelled."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_create_group_booking(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """POST /groups/bookings should book a student into a schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_group_booking_waitlist_when_full(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Booking when at capacity should go to waitlist."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_group_booking_full_no_waitlist(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Booking when full with no waitlist should return 400."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_cancel_group_booking_promotes_waitlist(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Cancelling a confirmed booking should auto-promote first waitlister."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_mark_attendance(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """PATCH /groups/bookings/{id}/attendance should mark attended."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_mark_no_show(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """PATCH attendance with attended=false should mark noShow."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_group_class(db_session)

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
async def test_create_no_show_record(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """POST /groups/no-shows should create a record."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_student(db_session, "student-1")

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
async def test_list_no_shows(client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession):
    """GET /groups/no-shows should list records for teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _ensure_student(db_session, "s1")

    await client.post(
        "/api/v1/groups/no-shows",
        headers=auth_headers,
        json={"lesson_id": "l1", "student_id": "s1", "lesson_date": "2026-03-16", "applied_policy": "noDeduction"},
    )

    response = await client.get("/api/v1/groups/no-shows", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["total"] == 1
