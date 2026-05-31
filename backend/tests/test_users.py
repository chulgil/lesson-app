"""User profile endpoint tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


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


@pytest.mark.asyncio
async def test_student_onboarding_complete_requires_student_profile(
    client: AsyncClient,
    create_test_user,
):
    """Student signup cannot finish onboarding before entering profile details."""
    await create_test_user(
        user_id="student-without-profile",
        role="student",
        name="Google Name",
        email="student-without-profile@test.com",
    )
    token = create_access_token(data={"sub": "student-without-profile", "role": "student"})

    response = await client.patch(
        "/api/v1/users/me/onboarding-complete",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Student profile is required before completing onboarding"


@pytest.mark.asyncio
async def test_student_onboarding_complete_succeeds_after_student_profile(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Student signup can finish onboarding after their self-profile exists."""
    from app.models.student import Student

    await create_test_user(
        user_id="student-with-profile",
        role="student",
        name="Google Name",
        email="student-with-profile@test.com",
    )
    db_session.add(
        Student(
            id="student-profile-id",
            user_id="student-with-profile",
            teacher_id=None,
            name="Entered Name",
            instrument="violin",
            level="beginner",
        )
    )
    await db_session.flush()
    token = create_access_token(data={"sub": "student-with-profile", "role": "student"})

    response = await client.patch(
        "/api/v1/users/me/onboarding-complete",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200, response.text
    assert response.json()["onboarding_completed"] is True
