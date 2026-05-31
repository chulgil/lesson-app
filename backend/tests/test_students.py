"""Student endpoint tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_student(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/students creates a student (teacher only) and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={
            "name": "Alice Kim",
            "instrument": "violin",
            "level": "intermediate",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Alice Kim"
    assert data["instrument"] == "violin"
    assert data["teacher_id"] == "test-user-id-prof"
    assert "id" in data


@pytest.mark.asyncio
async def test_list_students(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/students returns a paginated list of students."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a student first
    await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "Bob Lee", "instrument": "piano"},
    )

    response = await client.get("/api/v1/students", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1
    assert len(data["items"]) >= 1


@pytest.mark.asyncio
async def test_get_student_by_id(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/students/{id} returns a single student."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "Charlie Park"},
    )
    student_id = create_resp.json()["id"]

    response = await client.get(f"/api/v1/students/{student_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == student_id
    assert data["name"] == "Charlie Park"


@pytest.mark.asyncio
async def test_update_student(client: AsyncClient, auth_headers, create_test_user):
    """PUT /api/v1/students/{id} updates student fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "Diana Choi", "instrument": "flute"},
    )
    student_id = create_resp.json()["id"]

    response = await client.put(
        f"/api/v1/students/{student_id}",
        headers=auth_headers,
        json={"name": "Diana Choi", "instrument": "cello"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["instrument"] == "cello"


@pytest.mark.asyncio
async def test_delete_student(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /api/v1/students/{id} soft-deletes a student (returns 204)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "Eve Yoon"},
    )
    student_id = create_resp.json()["id"]

    response = await client.delete(f"/api/v1/students/{student_id}", headers=auth_headers)
    assert response.status_code == 204


@pytest.mark.parametrize(
    ("method", "path_suffix", "json_body"),
    [
        ("GET", "", None),
        ("PUT", "", {"name": "Hacked Student"}),
        ("PATCH", "/status", {"status": "inactive"}),
        ("DELETE", "", None),
        ("GET", "/stats", None),
    ],
)
@pytest.mark.asyncio
async def test_other_teacher_cannot_access_student_detail_mutations_or_stats(
    method: str,
    path_suffix: str,
    json_body: dict | None,
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Student detail, mutations, and stats are scoped to the owning teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-teacher@test.com")
    create_resp = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "Owned Student"},
    )
    student_id = create_resp.json()["id"]

    response = await client.request(
        method,
        f"/api/v1/students/{student_id}{path_suffix}",
        headers=_headers("other-teacher-id"),
        json=json_body,
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_student_unauthorized(client: AsyncClient, student_auth_headers, create_test_user):
    """POST /api/v1/students with student role returns 403 (teacher only)."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")

    response = await client.post(
        "/api/v1/students",
        headers=student_auth_headers,
        json={"name": "Unauthorized Student"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_student_can_setup_own_profile_without_teacher(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
):
    """Student onboarding creates a self-profile before teacher connection."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-onboarding@test.com",
        name="Student",
    )

    response = await client.post(
        "/api/v1/students/me/profile",
        headers=student_auth_headers,
        json={
            "name": "Student",
            "instrument": "피아노",
            "level": "beginner",
        },
    )

    assert response.status_code == 201, response.text
    data = response.json()
    assert data["name"] == "Student"
    assert data["instrument"] == "피아노"
    assert data["teacher_id"] is None
    assert data["user_id"] == "test-student-id"


@pytest.mark.asyncio
async def test_student_profile_setup_is_idempotent_for_existing_self_profile(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
):
    """Retrying onboarding profile setup updates the existing self-profile."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-onboarding-retry@test.com",
        name="Student",
    )

    first = await client.post(
        "/api/v1/students/me/profile",
        headers=student_auth_headers,
        json={
            "name": "Student",
            "instrument": "피아노",
            "level": "beginner",
        },
    )
    assert first.status_code == 201, first.text

    retry = await client.post(
        "/api/v1/students/me/profile",
        headers=student_auth_headers,
        json={
            "name": "Updated Student",
            "instrument": "바이올린",
            "level": "elementary",
        },
    )

    assert retry.status_code == 201, retry.text
    data = retry.json()
    assert data["id"] == first.json()["id"]
    assert data["name"] == "Updated Student"
    assert data["instrument"] == "바이올린"
    assert data["level"] == "elementary"
