"""Authentication endpoint tests."""

from unittest.mock import patch

import jwt
import pytest
from httpx import AsyncClient

from app.core.security import create_access_token, create_refresh_token


@pytest.mark.asyncio
async def test_oauth_login_unsupported_provider(client: AsyncClient):
    """POST /api/v1/auth/oauth/{provider} with an unsupported provider returns 400."""
    response = await client.post(
        "/api/v1/auth/oauth/github",
        json={"provider": "github", "code": "fake-code"},
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_oauth_login_missing_code(client: AsyncClient):
    """POST /api/v1/auth/oauth/google without proper credentials returns error."""
    response = await client.post(
        "/api/v1/auth/oauth/google",
        json={"provider": "google"},
    )
    # Should fail because code is None and Google exchange will fail
    assert response.status_code in (401, 422, 500)


@pytest.mark.asyncio
async def test_refresh_token_invalid(client: AsyncClient):
    """POST /api/v1/auth/token/refresh with an invalid token returns 401."""
    response = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": "not-a-valid-token"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token_success(client: AsyncClient, create_test_user):
    """POST /api/v1/auth/token/refresh with a valid refresh token returns a new access token."""
    await create_test_user(user_id="test-user-id", role="teacher")
    refresh = create_refresh_token(data={"sub": "test-user-id", "role": "teacher"})

    response = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": refresh},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_get_me_authenticated(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/auth/me with valid token returns the current user."""
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")

    response = await client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "test-user-id"
    assert data["name"] == "Test Teacher"


@pytest.mark.asyncio
async def test_get_me_unauthenticated(client: AsyncClient):
    """GET /api/v1/auth/me without token returns 401."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


# ------------------------------------------------------------------
# Dev Login
# ------------------------------------------------------------------


@pytest.mark.asyncio
async def test_dev_login_creates_user(client: AsyncClient):
    """POST /api/v1/auth/dev-login creates a new user and returns tokens."""
    response = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "new-dev@example.com", "role": "teacher", "name": "Dev Teacher"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == "new-dev@example.com"
    assert data["user"]["name"] == "Dev Teacher"
    assert data["user"]["role"] == "teacher"


@pytest.mark.asyncio
async def test_dev_login_existing_user(client: AsyncClient, create_test_user):
    """POST /api/v1/auth/dev-login with existing user returns tokens without duplicating."""
    await create_test_user(user_id="existing-id", role="teacher", email="existing@example.com")

    response = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "existing@example.com", "role": "teacher"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["id"] == "existing-id"


@pytest.mark.asyncio
async def test_dev_login_parent_creates_profile(client: AsyncClient):
    """POST /api/v1/auth/dev-login with role=parent auto-creates Parent profile."""
    response = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "parent-dev@example.com", "role": "parent", "name": "Dev Parent"},
    )
    assert response.status_code == 200
    assert response.json()["user"]["role"] == "parent"


@pytest.mark.asyncio
async def test_dev_login_blocked_in_production(client: AsyncClient):
    """POST /api/v1/auth/dev-login returns 403 when ENVIRONMENT != development."""
    with patch("app.core.config.settings.ENVIRONMENT", "production"):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_dev_login_blocked_in_beta(client: AsyncClient):
    """POST /api/v1/auth/dev-login returns 403 in beta-like environments."""
    with patch("app.core.config.settings.ENVIRONMENT", "beta"):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_apple_oauth_requires_configured_client_id(client: AsyncClient):
    """Apple login must not accept identity tokens without configured audience verification."""
    identity_token = jwt.encode(
        {"sub": "apple-user-id", "email": "apple@example.com"},
        key="",
        algorithm="none",
    )

    with patch("app.core.config.settings.APPLE_CLIENT_ID", ""):
        response = await client.post(
            "/api/v1/auth/oauth/apple",
            json={
                "provider": "apple",
                "identity_token": identity_token,
            },
        )

    assert response.status_code == 401


def test_production_jwt_secret_must_be_strong():
    """Token creation fails in production when JWT_SECRET_KEY is default or too short."""
    with (
        patch("app.core.config.settings.ENVIRONMENT", "production"),
        patch("app.core.config.settings.JWT_SECRET_KEY", "change-me-in-production"),
    ):
        with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
            create_access_token(data={"sub": "test-user-id"})

    with (
        patch("app.core.config.settings.ENVIRONMENT", "production"),
        patch("app.core.config.settings.JWT_SECRET_KEY", "short-secret"),
    ):
        with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
            create_refresh_token(data={"sub": "test-user-id"})
