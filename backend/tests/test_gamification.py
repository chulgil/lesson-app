"""Tests for gamification endpoints."""

import pytest
from httpx import AsyncClient


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
async def test_award_points_unauthorized_student(client: AsyncClient, student_auth_headers, create_test_user):
    """POST /gamification/points as student should return 403."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")

    response = await client.post(
        "/api/v1/gamification/points",
        headers=student_auth_headers,
        json={"student_id": "s1", "points": 10, "type": "practiceComplete", "description": "x"},
    )
    assert response.status_code == 403
