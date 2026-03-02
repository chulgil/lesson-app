"""Teacher endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_teachers(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/teachers", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_get_teacher_dashboard(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers/{id}/dashboard returns dashboard data."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/teachers/test-user-id/dashboard",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "total_students" in data
    assert "upcoming_lessons" in data


@pytest.mark.asyncio
async def test_get_teacher_students(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/teachers/{id}/students returns student list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/teachers/test-user-id/students",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] >= 0
