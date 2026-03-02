"""Relationship and follow endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_relationships(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/relationships returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/relationships", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_invite_student(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/relationships/invite sends an invitation."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/relationships/invite",
        headers=auth_headers,
        json={"student_id": "student-001", "method": "sms"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["teacher_id"] == "test-user-id"
    assert data["student_id"] == "student-001"
    assert "invite_code" in data


@pytest.mark.asyncio
async def test_follow_teacher(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/follows creates a follow relationship."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/follows",
        headers=auth_headers,
        json={"following_id": "teacher-002", "target_type": "teacher"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["follower_id"] == "test-user-id"
    assert data["following_id"] == "teacher-002"
