"""Relationship notification settings endpoint tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_relationship_notification_settings_match_frontend_contract(
    client: AsyncClient,
    create_test_user,
):
    """GET/PUT/DELETE /relationships/notification-settings follows frontend contract."""
    await create_test_user(user_id="student-user-id", role="student", name="Student", email="student@test.com")
    await create_test_user(user_id="teacher-user-id", role="teacher", name="Teacher", email="teacher@test.com")

    student_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'student-user-id', 'role': 'student'})}"
    }

    get_response = await client.get(
        "/api/v1/relationships/notification-settings",
        headers=student_headers,
        params={"user_id": "student-user-id", "target_user_id": "teacher-user-id"},
    )
    assert get_response.status_code == 200
    defaults = get_response.json()
    assert defaults["user_id"] == "student-user-id"
    assert defaults["target_user_id"] == "teacher-user-id"
    assert defaults["push_enabled"] is True
    assert defaults["practice_share_enabled"] is True
    assert defaults["lesson_reminder_enabled"] is True
    assert defaults["payment_reminder_enabled"] is True
    assert defaults["created_at"] is not None
    assert defaults["updated_at"] is not None

    put_response = await client.put(
        "/api/v1/relationships/notification-settings",
        headers=student_headers,
        json={
            "id": defaults["id"],
            "user_id": "student-user-id",
            "target_user_id": "teacher-user-id",
            "push_enabled": False,
            "practice_share_enabled": False,
            "lesson_reminder_enabled": True,
            "payment_reminder_enabled": False,
        },
    )
    assert put_response.status_code == 200
    saved = put_response.json()
    assert saved["id"] == defaults["id"]
    assert saved["push_enabled"] is False
    assert saved["practice_share_enabled"] is False
    assert saved["payment_reminder_enabled"] is False

    forbidden_response = await client.put(
        "/api/v1/relationships/notification-settings",
        headers=student_headers,
        json={
            "user_id": "other-user-id",
            "target_user_id": "teacher-user-id",
            "push_enabled": True,
        },
    )
    assert forbidden_response.status_code == 403

    delete_response = await client.delete(
        f"/api/v1/relationships/notification-settings/{defaults['id']}",
        headers=student_headers,
    )
    assert delete_response.status_code == 204

    recreated_response = await client.get(
        "/api/v1/relationships/notification-settings",
        headers=student_headers,
        params={"user_id": "student-user-id", "target_user_id": "teacher-user-id"},
    )
    assert recreated_response.status_code == 200
    assert recreated_response.json()["id"] != defaults["id"]
