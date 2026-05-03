"""Tests for settings endpoints (teacher, subscription, proposal, feedback, resources)."""

import pytest
from httpx import AsyncClient

# ---------------------------------------------------------------------------
# Teacher Settings
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_teacher_settings_default(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/teacher should auto-create with defaults."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/settings/teacher", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["teacher_id"] == "test-user-id"
    assert data["default_lesson_duration"] == 60
    assert data["break_time_between_lessons"] == 10
    assert data["min_booking_hours"] == 24


@pytest.mark.asyncio
async def test_update_teacher_settings(client: AsyncClient, auth_headers, create_test_user):
    """PUT /settings/teacher should update specified fields only."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/settings/teacher",
        headers=auth_headers,
        json={"default_lesson_duration": 45, "break_time_between_lessons": 15},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["default_lesson_duration"] == 45
    assert data["break_time_between_lessons"] == 15
    assert data["min_booking_hours"] == 24  # unchanged


@pytest.mark.asyncio
async def test_student_can_get_public_teacher_settings_by_teacher_id(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Students need target teacher settings for request guidance and prices."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-public-settings@test.com",
    )

    update = await client.put(
        "/api/v1/settings/teacher",
        headers=auth_headers,
        json={
            "instruments": ["바이올린"],
            "booking_guidance_message": "오디션 준비는 가능한 시간대를 2개 이상 골라주세요.",
            "lesson_price_table": {
                "바이올린": {
                    "beginner": 40000,
                    "intermediate": 50000,
                    "advanced": 70000,
                }
            },
        },
    )
    assert update.status_code == 200

    response = await client.get(
        "/api/v1/settings/teacher/test-user-id",
        headers=student_auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["teacher_id"] == "test-user-id"
    assert data["booking_guidance_message"] == "오디션 준비는 가능한 시간대를 2개 이상 골라주세요."
    assert data["lesson_price_table"]["바이올린"]["beginner"] == 40000


# ---------------------------------------------------------------------------
# Subscription Settings
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_subscription_settings_default(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/subscription should auto-create defaults."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/settings/subscription", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["renewal_alert_threshold"] == 2
    assert data["renewal_alert_days_set"] == [14, 7, 1, 0]
    assert data["enable_push_notification"] is True


@pytest.mark.asyncio
async def test_update_subscription_settings(client: AsyncClient, auth_headers, create_test_user):
    """PUT /settings/subscription should update fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/settings/subscription",
        headers=auth_headers,
        json={"renewal_alert_threshold": 5, "renewal_alert_days_set": [7, 1], "notify_parent": False},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["renewal_alert_threshold"] == 5
    assert data["renewal_alert_days_set"] == [7, 1]
    assert data["notify_parent"] is False


# ---------------------------------------------------------------------------
# Proposal Settings
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_proposal_settings_default(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/proposal should auto-create defaults."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/settings/proposal", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["auto_proposal_enabled"] is False
    assert data["golden_time_discount_percent"] == 10
    assert data["golden_time_hours"] == 72


@pytest.mark.asyncio
async def test_update_proposal_settings(client: AsyncClient, auth_headers, create_test_user):
    """PUT /settings/proposal should update."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/settings/proposal",
        headers=auth_headers,
        json={"auto_proposal_enabled": True, "golden_time_hours": 48},
    )
    assert response.status_code == 200
    assert response.json()["auto_proposal_enabled"] is True
    assert response.json()["golden_time_hours"] == 48


# ---------------------------------------------------------------------------
# Notification Settings
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_notification_settings_default(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/notification/{target} should auto-create defaults."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/settings/notification/target-user-1",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["push_enabled"] is True
    assert data["practice_share_enabled"] is True


@pytest.mark.asyncio
async def test_update_notification_settings(client: AsyncClient, auth_headers, create_test_user):
    """PUT /settings/notification/{target} should update."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/settings/notification/target-user-1",
        headers=auth_headers,
        json={"push_enabled": False},
    )
    assert response.status_code == 200
    assert response.json()["push_enabled"] is False
    assert response.json()["lesson_reminder_enabled"] is True  # unchanged


# ---------------------------------------------------------------------------
# Feedback Presets
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_feedback_preset(client: AsyncClient, auth_headers, create_test_user):
    """POST /settings/feedback-presets should create a preset."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "잘 했어요!", "sort_order": 1},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["text"] == "잘 했어요!"
    assert data["sort_order"] == 1
    assert data["is_default"] is False


@pytest.mark.asyncio
async def test_list_feedback_presets(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/feedback-presets should list visible presets."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "Preset 1"},
    )
    await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "Preset 2"},
    )

    response = await client.get("/api/v1/settings/feedback-presets", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2


@pytest.mark.asyncio
async def test_delete_feedback_preset(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /settings/feedback-presets/{id} should remove custom preset."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "To delete"},
    )
    preset_id = cr.json()["id"]

    response = await client.delete(
        f"/api/v1/settings/feedback-presets/{preset_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_nonexistent_preset(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /settings/feedback-presets/{bad-id} should return 404."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.delete(
        "/api/v1/settings/feedback-presets/nonexistent",
        headers=auth_headers,
    )
    assert response.status_code == 404


# ---------------------------------------------------------------------------
# Teaching Resources
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_teaching_resource(client: AsyncClient, auth_headers, create_test_user):
    """POST /settings/teaching-resources should create a resource."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/settings/teaching-resources",
        headers=auth_headers,
        json={
            "type": "youtube",
            "title": "Bach Partita No.2",
            "youtube_video_id": "abc123",
            "tags": ["bach", "violin"],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Bach Partita No.2"
    assert data["type"] == "youtube"
    assert data["tags"] == ["bach", "violin"]


@pytest.mark.asyncio
async def test_list_teaching_resources(client: AsyncClient, auth_headers, create_test_user):
    """GET /settings/teaching-resources should return paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/settings/teaching-resources",
        headers=auth_headers,
        json={"type": "youtube", "title": "R1"},
    )

    response = await client.get("/api/v1/settings/teaching-resources", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1


@pytest.mark.asyncio
async def test_update_teaching_resource(client: AsyncClient, auth_headers, create_test_user):
    """PUT /settings/teaching-resources/{id} should update."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/settings/teaching-resources",
        headers=auth_headers,
        json={"type": "youtube", "title": "Old Title"},
    )
    resource_id = cr.json()["id"]

    response = await client.put(
        f"/api/v1/settings/teaching-resources/{resource_id}",
        headers=auth_headers,
        json={"title": "New Title"},
    )
    assert response.status_code == 200
    assert response.json()["title"] == "New Title"


@pytest.mark.asyncio
async def test_delete_teaching_resource(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /settings/teaching-resources/{id} should remove."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/settings/teaching-resources",
        headers=auth_headers,
        json={"type": "youtube", "title": "To Delete"},
    )
    resource_id = cr.json()["id"]

    response = await client.delete(
        f"/api/v1/settings/teaching-resources/{resource_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_settings_unauthorized_student(client: AsyncClient, student_auth_headers, create_test_user):
    """Student should get 403 on teacher-only settings endpoints."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")

    response = await client.get("/api/v1/settings/teacher", headers=student_auth_headers)
    assert response.status_code == 403
