"""Lesson endpoint tests."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.student import Student


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_lesson(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/lessons creates a lesson (teacher only) and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "instrument": "violin",
            "date": "2026-03-10",
            "start_time": "14:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "student-001"
    assert data["instrument"] == "violin"
    assert data["date"] == "2026-03-10"
    assert data["duration"] == 60
    assert data["lesson_source"] == "manual"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_lesson_with_empty_student_id_does_not_500(
    client: AsyncClient, auth_headers, create_test_user
):
    """Empty student_id must not raise NameError (500) (GitHub #466)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "",
            "instrument": "violin",
            "date": "2026-03-10",
            "start_time": "14:00",
            "duration": 60,
        },
    )
    # Either a clean creation or a validation error — never a 500 NameError.
    assert response.status_code != 500


@pytest.mark.asyncio
async def test_create_subscription_lesson_assigns_next_session_number(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Manual lesson creation with subscription_id should persist the next subscription session."""
    from datetime import date

    from app.models.lesson import ClassMembership, Lesson, LessonClass
    from app.models.subscription import Subscription

    await create_test_user(user_id="test-user-id", role="teacher")
    student = Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin")
    lesson_class = LessonClass(id="class-001", teacher_id="test-user-id-prof", name="Class")
    membership = ClassMembership(id="membership-001", lesson_class_id="class-001", student_id="student-001")
    subscription = Subscription(
        id="sub-001",
        student_id="student-001",
        membership_id="membership-001",
        type="package",
        total_lessons=4,
        amount=200000,
    )
    existing_lesson = Lesson(
        student_id="student-001",
        teacher_id="test-user-id-prof",
        student_name="Student",
        instrument="violin",
        date=date(2026, 3, 3),
        start_time="14:00",
        duration=60,
        subscription_id="sub-001",
        session_number=1,
    )
    db_session.add_all([lesson_class, student, membership, subscription, existing_lesson])
    await db_session.flush()

    response = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "instrument": "violin",
            "date": "2026-03-10",
            "start_time": "14:00",
            "duration": 60,
            "subscription_id": "sub-001",
        },
    )

    assert response.status_code == 201
    assert response.json()["subscription_id"] == "sub-001"
    assert response.json()["session_number"] == 2


@pytest.mark.asyncio
async def test_list_lessons(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/lessons returns a paginated list of lessons."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a lesson first
    await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2026-03-10",
            "duration": 45,
        },
    )

    response = await client.get("/api/v1/lessons", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_get_upcoming_lessons(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/lessons/upcoming returns a list of upcoming lessons."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a lesson in the future
    await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2027-06-15",
            "start_time": "10:00",
            "duration": 60,
        },
    )

    response = await client.get("/api/v1/lessons/upcoming", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_update_lesson_status(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/lessons/{id}/status changes the lesson status."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2026-03-10",
            "duration": 60,
        },
    )
    lesson_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/lessons/{lesson_id}/status",
        headers=auth_headers,
        json={"status": "completed"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"


@pytest.mark.asyncio
async def test_update_lesson_status_invalid_value_returns_422(
    client: AsyncClient, auth_headers, create_test_user
):
    """PATCH /status with an unknown status value returns 422, not a 500 (GitHub #470)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2026-03-10",
            "duration": 60,
        },
    )
    lesson_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/lessons/{lesson_id}/status",
        headers=auth_headers,
        json={"status": "definitely-not-a-status"},
    )
    assert response.status_code == 422
    assert response.status_code != 500


@pytest.mark.asyncio
async def test_update_lesson_feedback(client: AsyncClient, auth_headers, create_test_user):
    """PUT /api/v1/lessons/{id}/feedback writes feedback on a lesson."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "date": "2026-03-10",
            "duration": 60,
        },
    )
    lesson_id = create_resp.json()["id"]

    response = await client.put(
        f"/api/v1/lessons/{lesson_id}/feedback",
        headers=auth_headers,
        json={
            "feedback": "Great progress on the concerto.",
            "key_points": ["intonation", "dynamics"],
            "practice_tips": "Focus on measure 32-48",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["feedback"] == "Great progress on the concerto."
    assert data["practice_tips"] == "Focus on measure 32-48"


@pytest.mark.parametrize(
    ("method", "path_suffix", "json_body"),
    [
        ("GET", "", None),
        ("PUT", "", {"duration": 30}),
        ("DELETE", "", None),
        ("PATCH", "/status", {"status": "completed"}),
        ("PUT", "/feedback", {"feedback": "Not allowed"}),
    ],
)
@pytest.mark.asyncio
async def test_other_teacher_cannot_access_lesson_detail_mutations_or_feedback(
    method: str,
    path_suffix: str,
    json_body: dict | None,
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Lesson detail, mutations, status, and feedback are scoped to the owning teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-lesson-teacher@test.com")
    create_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": "student-001", "date": "2026-03-10", "duration": 60},
    )
    lesson_id = create_resp.json()["id"]

    response = await client.request(
        method,
        f"/api/v1/lessons/{lesson_id}{path_suffix}",
        headers=_headers("other-teacher-id"),
        json=json_body,
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_teacher_cannot_create_lesson_for_other_teachers_existing_student(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Creating a lesson with an existing student requires owning that student."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-existing-student@test.com")
    db_session.add(
        Student(
            id="other-owned-student",
            teacher_id="other-teacher-id-prof",
            name="Other Teacher Student",
            instrument="piano",
        )
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": "other-owned-student",
            "date": "2026-03-10",
            "duration": 60,
        },
    )

    assert response.status_code == 403


@pytest.mark.parametrize(
    ("method", "path_suffix", "json_body"),
    [
        ("GET", "", None),
        ("PUT", "", {"name": "Hacked Class"}),
        ("DELETE", "", None),
        ("PATCH", "/restore", None),
        ("GET", "/memberships", None),
        ("POST", "/memberships", {"student_id": "student-001", "instrument": "violin"}),
    ],
)
@pytest.mark.asyncio
async def test_other_teacher_cannot_access_lesson_class_or_scoped_memberships(
    method: str,
    path_suffix: str,
    json_body: dict | None,
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Lesson class detail/mutations and scoped memberships are owner-teacher only."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-class-teacher@test.com")
    create_resp = await client.post(
        "/api/v1/lessons-classes",
        headers=auth_headers,
        json={"name": "Owner Class", "type": "academy"},
    )
    class_id = create_resp.json()["id"]

    response = await client.request(
        method,
        f"/api/v1/lessons-classes/{class_id}{path_suffix}",
        headers=_headers("other-teacher-id"),
        json=json_body,
    )

    assert response.status_code == 403


# ---------------------------------------------------------------------------
# 0702 audit M4 — create-time conflict validation (defense-in-depth)
# ---------------------------------------------------------------------------

_M4_BASE = {
    "student_id": "student-001",
    "instrument": "violin",
    "date": "2026-03-10",
    "duration": 60,
}


@pytest.mark.asyncio
async def test_create_lesson_overlap_returns_409(
    client: AsyncClient, auth_headers, create_test_user
):
    """Overlapping lesson for the same teacher is rejected with 409."""
    await create_test_user(user_id="test-user-id", role="teacher")

    first = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "14:00"}
    )
    assert first.status_code == 201

    overlap = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "14:30"}
    )
    assert overlap.status_code == 409


@pytest.mark.asyncio
async def test_create_lesson_adjacent_slot_allowed(
    client: AsyncClient, auth_headers, create_test_user
):
    """Back-to-back lessons without minute overlap are both accepted."""
    await create_test_user(user_id="test-user-id", role="teacher")

    first = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "14:00"}
    )
    assert first.status_code == 201

    adjacent = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "15:00"}
    )
    assert adjacent.status_code == 201


@pytest.mark.asyncio
async def test_create_lesson_overlap_with_cancelled_lesson_allowed(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Cancelled lessons do not block the slot."""
    from datetime import date as _date

    from app.models.lesson import Lesson, LessonStatus

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(
        Lesson(
            student_id="student-001",
            student_name="student-001",
            teacher_id="test-user-id",
            instrument="violin",
            date=_date(2026, 3, 10),
            start_time="14:00",
            duration=60,
            status=LessonStatus.cancelled,
        )
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "14:30"}
    )
    assert response.status_code == 201


@pytest.mark.asyncio
async def test_create_lesson_overlap_with_active_booking_returns_409(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A non-cancelled booking at the same time blocks manual creation."""
    from datetime import date as _date

    from app.models.schedule import BookingLessonType, BookingStatus, LessonBooking

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(
        LessonBooking(
            teacher_id="test-user-id",
            student_id="student-001",
            lesson_type=BookingLessonType.regular,
            scheduled_date=_date(2026, 3, 10),
            scheduled_time="14:00",
            duration=60,
            status=BookingStatus.confirmed,
        )
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/lessons", headers=auth_headers, json={**_M4_BASE, "start_time": "14:30"}
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_create_lesson_other_teacher_same_time_allowed(
    client: AsyncClient, create_test_user
):
    """Conflict scope is per-teacher — another teacher's lesson does not block."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-teacher", role="teacher", email="other-teacher@test.com"
    )

    first = await client.post(
        "/api/v1/lessons",
        headers=_headers("test-user-id"),
        json={**_M4_BASE, "start_time": "14:00"},
    )
    assert first.status_code == 201

    other = await client.post(
        "/api/v1/lessons",
        headers=_headers("other-teacher"),
        json={**_M4_BASE, "start_time": "14:00"},
    )
    assert other.status_code == 201
