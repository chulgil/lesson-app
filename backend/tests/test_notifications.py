"""Notification endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_notifications(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/notifications returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/notifications", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_get_unread_count(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/notifications/unread-count returns count."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 0


@pytest.mark.asyncio
async def test_mark_all_read(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/notifications/read-all marks all as read."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.patch("/api/v1/notifications/read-all", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
