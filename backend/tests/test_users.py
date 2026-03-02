"""User profile endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_my_profile(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/users/me returns current user profile."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "test-user-id"
    assert data["role"] == "teacher"
    assert data["email"] == "teacher@test.com"


@pytest.mark.asyncio
async def test_update_my_profile(client: AsyncClient, auth_headers, create_test_user):
    """PUT /api/v1/users/me updates user profile fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/users/me",
        headers=auth_headers,
        json={"name": "Updated Name"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Name"


@pytest.mark.asyncio
async def test_get_my_profile_unauthenticated(client: AsyncClient):
    """GET /api/v1/users/me without token returns 401."""
    response = await client.get("/api/v1/users/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_supported_locales(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/users/supported-locales returns locale list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/users/supported-locales", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "locales" in data
    locale_codes = [loc["locale"] for loc in data["locales"]]
    assert "ko" in locale_codes
