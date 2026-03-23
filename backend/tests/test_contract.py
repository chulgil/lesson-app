"""Contract tests — simulate frontend Remote Repository requests.

These tests verify that the backend accepts the exact request format
that frontend Remote Repositories send, and returns responses
in the format frontend expects.
"""

import pytest


# ---------------------------------------------------------------------------
# Auth contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_logout_no_body(client, auth_headers, create_test_user):
    """Frontend sends POST /auth/logout with no body."""
    await create_test_user()
    resp = await client.post("/api/v1/auth/logout", headers=auth_headers)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_logout_with_refresh_token(client, auth_headers, create_test_user):
    """Frontend may send refresh_token in body."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": "some-token"},
        headers=auth_headers,
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_refresh_returns_both_tokens(client, auth_headers, create_test_user):
    """Frontend expects both access_token and refresh_token in refresh response."""
    await create_test_user()
    # First, do dev-login to get a real refresh token
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "test@test.com", "role": "teacher"},
    )
    assert login_resp.status_code == 200
    refresh_token = login_resp.json()["refresh_token"]

    resp = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_contract_dev_login_response_format(client):
    """Frontend expects {access_token, refresh_token, token_type, user: {...}}."""
    resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "contract@test.com", "role": "teacher"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user" in data
    user = data["user"]
    assert "id" in user
    assert "email" in user
    assert "name" in user


# ---------------------------------------------------------------------------
# Teacher Profile contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_get_my_profile(client, auth_headers, create_test_user):
    """Frontend calls GET /teachers/me/profile."""
    await create_test_user()
    # Auto-create teacher profile via dev-login
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "teacher@test.com", "role": "teacher"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/teachers/me/profile", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "id" in data
    assert "user_id" in data
    assert "instruments" in data
    # Should include enriched fields
    assert "education" in data
    assert "career" in data
    assert "certificates" in data
    assert "lesson_areas" in data
    assert "visibility_settings" in data


@pytest.mark.asyncio
async def test_contract_teacher_response_includes_user(client, auth_headers, create_test_user):
    """Frontend expects TeacherResponse.user to contain UserResponse."""
    await create_test_user()
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "teacher@test.com", "role": "teacher"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/teachers/me/profile", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"] is not None
    assert data["user"]["name"] is not None


# ---------------------------------------------------------------------------
# Student contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_student_search_param(client, auth_headers, create_test_user):
    """Frontend sends ?search= instead of ?q=."""
    await create_test_user()
    resp = await client.get(
        "/api/v1/students?search=김",
        headers=auth_headers,
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_student_status_update(client, auth_headers, create_test_user):
    """Frontend sends PATCH /students/{id}/status."""
    await create_test_user()
    # Create student first
    create_resp = await client.post(
        "/api/v1/students",
        json={"name": "테스트학생", "instrument": "piano"},
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    student_id = create_resp.json()["id"]

    resp = await client.patch(
        f"/api/v1/students/{student_id}/status",
        json={"status": "paused"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "paused"


@pytest.mark.asyncio
async def test_contract_student_create_all_fields(client, auth_headers, create_test_user):
    """Frontend sends many fields that backend should accept."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/students",
        json={
            "name": "김학생",
            "instrument": "violin",
            "level": "beginner",
            "email": "student@test.com",
            "parent_name": "김부모",
            "phone": "010-1234-5678",
            "parent_phone": "010-8765-4321",
            "lesson_day": "monday",
            "lesson_time": "14:00",
            "lesson_duration": 45,
            "notes": "특이사항 없음",
            "birth_date": "2015-03-15",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == "student@test.com"
    assert data["parent_name"] == "김부모"
    assert data["lesson_day"] == "monday"
    assert data["lesson_time"] == "14:00"
    assert data["lesson_duration"] == 45
    assert data["notes"] == "특이사항 없음"


@pytest.mark.asyncio
async def test_contract_student_response_all_fields(client, auth_headers, create_test_user):
    """Frontend expects many fields in StudentResponse."""
    await create_test_user()
    create_resp = await client.post(
        "/api/v1/students",
        json={"name": "필드테스트", "instrument": "piano"},
        headers=auth_headers,
    )
    student_id = create_resp.json()["id"]

    resp = await client.get(
        f"/api/v1/students/{student_id}",
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    # All fields should be present (even if null)
    expected_fields = [
        "id", "teacher_id", "name", "instrument", "level", "status",
        "phone", "parent_phone", "parent_name", "email",
        "lesson_day", "lesson_time", "lesson_duration",
        "birth_date", "age_group", "connection_status",
        "practice_level", "break_reason", "notes", "is_active",
    ]
    for field in expected_fields:
        assert field in data, f"Missing field: {field}"


# ---------------------------------------------------------------------------
# Location contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_location_crud(client, auth_headers, create_test_user):
    """Frontend expects full CRUD on /locations."""
    await create_test_user()

    # Create
    create_resp = await client.post(
        "/api/v1/locations",
        json={
            "name": "연습실 A",
            "type": "teacherStudio",
            "address": "서울시 강남구",
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    location_id = create_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/locations/{location_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "연습실 A"

    # List
    list_resp = await client.get("/api/v1/locations", headers=auth_headers)
    assert list_resp.status_code == 200

    # Update
    update_resp = await client.put(
        f"/api/v1/locations/{location_id}",
        json={"name": "연습실 B"},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["name"] == "연습실 B"

    # Deactivate
    deact_resp = await client.patch(
        f"/api/v1/locations/{location_id}/deactivate",
        headers=auth_headers,
    )
    assert deact_resp.status_code == 200

    # Reactivate
    react_resp = await client.patch(
        f"/api/v1/locations/{location_id}/reactivate",
        headers=auth_headers,
    )
    assert react_resp.status_code == 200


# ---------------------------------------------------------------------------
# Schedule exception contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_schedule_exception_rich_format(client, auth_headers, create_test_user):
    """Frontend sends rich format (start_date, end_date, start_time, end_time)."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/schedule/exceptions",
        json={
            "type": "vacation",
            "start_date": "2026-04-01",
            "end_date": "2026-04-05",
            "start_time": "09:00",
            "end_time": "18:00",
            "reason": "봄방학",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["type"] == "vacation"
    assert data["start_date"] == "2026-04-01"
    assert data["end_date"] == "2026-04-05"


# ---------------------------------------------------------------------------
# Lesson request contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_lesson_request_crud(client, auth_headers, student_auth_headers, create_test_user):
    """Frontend calls /schedule/lesson-requests for full CRUD."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id", role="student",
        name="Student", email="student@test.com",
    )

    # Create (as student)
    create_resp = await client.post(
        "/api/v1/schedule/lesson-requests",
        json={
            "teacher_id": "test-user-id",
            "message": "다시 레슨 받고 싶습니다",
            "preferred_timing": "nextWeek",
        },
        headers=student_auth_headers,
    )
    assert create_resp.status_code == 201
    request_id = create_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200

    # List
    list_resp = await client.get(
        "/api/v1/schedule/lesson-requests?teacher_id=test-user-id",
        headers=auth_headers,
    )
    assert list_resp.status_code == 200

    # Update status (teacher accepts)
    status_resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        json={"status": "accepted"},
        headers=auth_headers,
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "accepted"


# ---------------------------------------------------------------------------
# Relationship contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_relationship_get_by_id(client, auth_headers, create_test_user):
    """Frontend calls GET /relationships/{id}."""
    await create_test_user()
    # Create a relationship via invite
    invite_resp = await client.post(
        "/api/v1/relationships/invite",
        json={"student_id": "some-student", "method": "sms"},
        headers=auth_headers,
    )
    assert invite_resp.status_code == 201
    rel_id = invite_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/relationships/{rel_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    data = get_resp.json()
    # Should include extended fields
    assert "total_lesson_count" in data
    assert "is_manually_registered" in data
    assert "last_lesson_day" in data


@pytest.mark.asyncio
async def test_contract_relationship_status_with_metadata(client, auth_headers, create_test_user):
    """Frontend sends extra metadata with status update."""
    await create_test_user()
    invite_resp = await client.post(
        "/api/v1/relationships/invite",
        json={"student_id": "some-student"},
        headers=auth_headers,
    )
    rel_id = invite_resp.json()["id"]

    resp = await client.patch(
        f"/api/v1/relationships/{rel_id}/status",
        json={
            "status": "active",
            "subscription_id": "sub-123",
            "last_lesson_day": "monday",
            "last_lesson_time": "14:00",
            "last_lesson_duration": 45,
        },
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["active_subscription_id"] == "sub-123"
    assert data["last_lesson_day"] == "monday"
