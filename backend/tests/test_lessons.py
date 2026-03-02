"""Lesson endpoint tests."""

import pytest
from httpx import AsyncClient


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
