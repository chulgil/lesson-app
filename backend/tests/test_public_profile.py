"""Tests for the public teacher profile endpoint.

Verifies: no-auth access, correct data, 404 handling, sensitive field exclusion.
"""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_public_profile_by_id(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Public profile is returned for a valid teacher_id."""
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")

    # teacher profile id is f"{user_id}-prof" per conftest fixture
    response = await client.get("/api/v1/teachers/public/test-user-id-prof")

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "test-user-id-prof"
    assert data["name"] == "홍길동"


@pytest.mark.asyncio
async def test_get_public_profile_not_found(
    client: AsyncClient,
) -> None:
    """Non-existent teacher_id returns 404."""
    response = await client.get("/api/v1/teachers/public/does-not-exist")

    assert response.status_code == 404
    assert response.json()["detail"] == "Teacher not found"


@pytest.mark.asyncio
async def test_get_public_profile_no_auth_required(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Endpoint is accessible without an Authorization header."""
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")

    # Explicitly send no Authorization header
    response = await client.get(
        "/api/v1/teachers/public/test-user-id-prof",
        headers={},
    )

    assert response.status_code == 200


@pytest.mark.asyncio
async def test_public_profile_excludes_sensitive_fields(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Sensitive fields (phone, banking) are not present in the public response."""
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")

    response = await client.get("/api/v1/teachers/public/test-user-id-prof")

    assert response.status_code == 200
    data = response.json()

    # These fields must NOT appear in the public response
    for sensitive_field in ("phone_number", "bank_name", "account_number", "account_holder", "bank_accounts"):
        assert sensitive_field not in data, f"Sensitive field '{sensitive_field}' leaked in public profile"
