"""Tests for gamification endpoints."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.student import Student


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_get_student_gamification_empty(client: AsyncClient, auth_headers, create_test_user):
    """GET /gamification/{student_id} with no data should return zero state."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/gamification/student-1",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["student_id"] == "student-1"
    assert data["total_points"] == 0
    assert data["level"] == 1
    assert data["earned_badges"] == []
    assert data["recent_history"] == []


@pytest.mark.asyncio
async def test_award_points(client: AsyncClient, auth_headers, create_test_user):
    """POST /gamification/points should create a point entry."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/gamification/points",
        headers=auth_headers,
        json={
            "student_id": "student-1",
            "points": 50,
            "type": "practiceComplete",
            "description": "연습 완료",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["points"] == 50
    assert data["type"] == "practiceComplete"


@pytest.mark.asyncio
async def test_award_points_updates_total(client: AsyncClient, auth_headers, create_test_user):
    """Awarding points should be reflected in the gamification summary."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Award 150 points (crosses level 2 threshold at 100)
    await client.post(
        "/api/v1/gamification/points",
        headers=auth_headers,
        json={"student_id": "s1", "points": 150, "type": "streakBonus", "description": "x"},
    )

    response = await client.get("/api/v1/gamification/s1", headers=auth_headers)
    data = response.json()
    assert data["total_points"] == 150
    assert data["level"] == 2  # 100 threshold passed


@pytest.mark.asyncio
async def test_award_points_boundary_level_up(client: AsyncClient, auth_headers, create_test_user):
    """Points at exact level boundary should level up."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Award exactly 100 (level 2 threshold)
    await client.post(
        "/api/v1/gamification/points",
        headers=auth_headers,
        json={"student_id": "s2", "points": 100, "type": "goalAchieved", "description": "목표 달성"},
    )

    response = await client.get("/api/v1/gamification/s2", headers=auth_headers)
    data = response.json()
    assert data["total_points"] == 100
    assert data["level"] == 2


@pytest.mark.asyncio
async def test_gamification_badge_response_matches_frontend_practice_badge_contract(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """earned_badges items expose the fields parsed by Flutter PracticeBadge."""
    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(
        Student(
            id="badge-student",
            teacher_id="test-user-id-prof",
            name="Badge Student",
            instrument="violin",
        )
    )
    await db_session.flush()
    await client.post(
        "/api/v1/gamification/badge-student/badges",
        headers=auth_headers,
        json={
            "badges": [
                {
                    "name": "First Practice",
                    "description": "Completed first practice",
                    "icon": "music_note",
                    "rarity": "common",
                }
            ]
        },
    )

    response = await client.get("/api/v1/gamification/badge-student", headers=auth_headers)

    assert response.status_code == 200
    badge = response.json()["earned_badges"][0]
    assert badge["name"] == "First Practice"
    assert badge["description"] == "Completed first practice"
    assert badge["icon"] == "music_note"
    assert badge["is_earned"] is True


@pytest.mark.asyncio
async def test_other_teacher_cannot_read_existing_students_gamification(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Gamification for an existing student is scoped to the owning teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-gamification@test.com")
    db_session.add(
        Student(
            id="owned-gamification-student",
            teacher_id="test-user-id-prof",
            name="Owned Student",
            instrument="piano",
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/gamification/owned-gamification-student",
        headers=_headers("other-teacher-id"),
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_award_points_unauthorized_student(client: AsyncClient, student_auth_headers, create_test_user):
    """POST /gamification/points as student should return 403."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")

    response = await client.post(
        "/api/v1/gamification/points",
        headers=student_auth_headers,
        json={"student_id": "s1", "points": 10, "type": "practiceComplete", "description": "x"},
    )
    assert response.status_code == 403
