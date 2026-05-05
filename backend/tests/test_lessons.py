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
    assert "id" in data


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
