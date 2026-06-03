"""Authentication endpoint tests."""

from unittest.mock import patch

import jwt
import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
)


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
    """POST /api/v1/auth/oauth/google without credentials is rejected locally."""
    with patch("app.services.auth_service.httpx.AsyncClient") as async_client:
        response = await client.post(
            "/api/v1/auth/oauth/google",
            json={"provider": "google"},
        )

    assert response.status_code == 400
    async_client.assert_not_called()


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
async def test_refresh_token_reflects_current_db_role(create_test_user, db_session):
    """Fix #4: refresh issues an access token with the user's CURRENT DB role,
    not the (possibly stale/elevated) role baked into the refresh token."""
    from app.models.user import UserRole
    from app.services.auth_service import AuthService

    user = await create_test_user(user_id="role-change-user", role="teacher")
    # Refresh token still carries the OLD elevated role claim.
    refresh = create_refresh_token(data={"sub": "role-change-user", "role": "teacher"})

    # Role is downgraded in the DB after the refresh token was issued.
    user.role = UserRole("student")
    await db_session.flush()

    service = AuthService(db_session)
    result = await service.refresh_token(refresh)

    decoded = decode_access_token(result.access_token)
    assert decoded is not None
    assert decoded["role"] == "student"  # current DB role, not stale "teacher"


@pytest.mark.asyncio
async def test_logout_invalid_token_does_not_create_blacklist_row(create_test_user, db_session):
    """Fix #5: logout with an undecodable refresh token must not write an empty-jti row."""
    from app.models.user import TokenBlacklist
    from app.services.auth_service import AuthService

    await create_test_user(user_id="logout-user", role="teacher")

    service = AuthService(db_session)
    await service.logout("logout-user", "not-a-valid-token")

    rows = (await db_session.scalars(select(TokenBlacklist))).all()
    assert rows == []


@pytest.mark.asyncio
async def test_logout_valid_token_creates_blacklist_row(create_test_user, db_session):
    """Logout with a valid refresh token still blacklists it (happy path unchanged)."""
    from app.models.user import TokenBlacklist
    from app.services.auth_service import AuthService

    await create_test_user(user_id="logout-user-2", role="teacher")
    refresh = create_refresh_token(data={"sub": "logout-user-2", "role": "teacher"})

    service = AuthService(db_session)
    await service.logout("logout-user-2", refresh)

    rows = (await db_session.scalars(select(TokenBlacklist))).all()
    assert len(rows) == 1
    assert rows[0].jti  # non-empty


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


@pytest.mark.asyncio
async def test_update_role_allows_unfinished_onboarding_user_to_reselect_role(
    client: AsyncClient,
    create_test_user,
):
    """Onboarding-incomplete users can reselect role before their profile is finalized."""
    await create_test_user(
        user_id="unfinished-role-user",
        role="student",
        email="unfinished-role@example.com",
    )
    token = create_access_token(data={"sub": "unfinished-role-user", "role": "student"})

    response = await client.patch(
        "/api/v1/auth/me",
        json={"role": "teacher"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200, response.text
    assert response.json()["role"] == "teacher"
    assert response.json()["onboarding_completed"] is False


@pytest.mark.asyncio
async def test_update_role_rejects_completed_onboarding_user(
    client: AsyncClient,
    create_test_user,
):
    """Completed users cannot silently change role through onboarding endpoint."""
    user = await create_test_user(
        user_id="completed-role-user",
        role="student",
        email="completed-role@example.com",
    )
    user.onboarding_completed = True
    token = create_access_token(data={"sub": "completed-role-user", "role": "student"})

    response = await client.patch(
        "/api/v1/auth/me",
        json={"role": "teacher"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 400


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
async def test_dev_login_blocked_in_beta_without_internal_key(client: AsyncClient):
    """beta + no X-Internal-API-Key header → 403 (default-closed)."""
    with patch("app.core.config.settings.ENVIRONMENT", "beta"):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_dev_login_blocked_in_beta_with_wrong_internal_key(client: AsyncClient):
    """beta + incorrect X-Internal-API-Key → 403."""
    with (
        patch("app.core.config.settings.ENVIRONMENT", "beta"),
        patch("app.core.config.settings.INTERNAL_API_KEY", "correct-secret-" + "x" * 32),
    ):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
            headers={"X-Internal-API-Key": "wrong-secret"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_dev_login_allowed_in_beta_with_correct_internal_key(client: AsyncClient):
    """beta + correct X-Internal-API-Key → 200 (integration-test gateway)."""
    secret = "beta-integration-test-key-" + "x" * 32
    strong_jwt = "beta-strong-jwt-secret-" + "y" * 48
    with (
        patch("app.core.config.settings.ENVIRONMENT", "beta"),
        patch("app.core.config.settings.INTERNAL_API_KEY", secret),
        patch("app.core.config.settings.JWT_SECRET_KEY", strong_jwt),
    ):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "qa-teacher@lessonaza.test", "role": "teacher"},
            headers={"X-Internal-API-Key": secret},
        )
    assert response.status_code == 200, response.text
    assert "access_token" in response.json()


@pytest.mark.asyncio
async def test_dev_login_blocked_in_beta_when_internal_key_unset(client: AsyncClient):
    """beta + INTERNAL_API_KEY unset (empty) → 403 even with any header value."""
    with (
        patch("app.core.config.settings.ENVIRONMENT", "beta"),
        patch("app.core.config.settings.INTERNAL_API_KEY", ""),
    ):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
            headers={"X-Internal-API-Key": "anything"},
        )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_dev_login_blocked_in_production_even_with_correct_internal_key(client: AsyncClient):
    """production never allows dev-login, regardless of header (defense in depth)."""
    secret = "real-prod-key-" + "x" * 32
    with (
        patch("app.core.config.settings.ENVIRONMENT", "production"),
        patch("app.core.config.settings.INTERNAL_API_KEY", secret),
    ):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "hacker@evil.com", "role": "teacher"},
            headers={"X-Internal-API-Key": secret},
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


def test_production_runtime_config_requires_strong_internal_api_key():
    """Runtime config validation fails in production when INTERNAL_API_KEY is unset or weak."""
    from app.core.config import validate_runtime_configuration

    with (
        patch("app.core.config.settings.ENVIRONMENT", "production"),
        patch("app.core.config.settings.INTERNAL_API_KEY", ""),
    ):
        with pytest.raises(RuntimeError, match="INTERNAL_API_KEY"):
            validate_runtime_configuration()


def test_production_runtime_config_requires_strong_jwt_secret():
    """Runtime config validation fails before startup when JWT_SECRET_KEY is unsafe."""
    from app.core.config import validate_runtime_configuration

    with (
        patch("app.core.config.settings.ENVIRONMENT", "production"),
        patch("app.core.config.settings.JWT_SECRET_KEY", "change-me-in-production"),
        patch("app.core.config.settings.INTERNAL_API_KEY", "x" * 32),
    ):
        with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
            validate_runtime_configuration()

    with (
        patch("app.core.config.settings.ENVIRONMENT", "beta"),
        patch("app.core.config.settings.INTERNAL_API_KEY", "short-key"),
    ):
        with pytest.raises(RuntimeError, match="INTERNAL_API_KEY"):
            validate_runtime_configuration()
