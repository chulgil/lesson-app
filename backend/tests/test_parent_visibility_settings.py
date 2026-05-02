"""Parent visibility settings endpoint tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_teacher_can_save_and_read_parent_visibility_settings(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Teachers can manage the parent visibility settings for their own profile."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student@test.com",
    )

    payload = {
        "teacher_id": "test-user-id-prof",
        "student_id": "student-user-id",
        "can_view_recordings": True,
        "can_view_chat": True,
    }

    save_response = await client.put(
        "/api/v1/parents/visibility-settings",
        headers=auth_headers,
        json=payload,
    )
    assert save_response.status_code == 200
    saved = save_response.json()
    assert saved["teacher_id"] == "test-user-id-prof"
    assert saved["student_id"] == "student-user-id"
    assert saved["can_view_schedule"] is True
    assert saved["can_view_recordings"] is True
    assert saved["can_view_chat"] is True

    get_response = await client.get(
        "/api/v1/parents/visibility-settings",
        headers=auth_headers,
        params={"teacher_id": "test-user-id-prof", "student_id": "student-user-id"},
    )
    assert get_response.status_code == 200
    assert get_response.json()["can_view_recordings"] is True


@pytest.mark.asyncio
async def test_parent_can_read_linked_child_visibility_settings(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can read settings for linked children."""
    await create_test_user(user_id="teacher-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )

    from app.models.parent import Parent, ParentChildRelation, ParentVisibilitySettings

    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-user-id"),
            ParentVisibilitySettings(
                teacher_id="teacher-user-id-prof",
                student_id="student-user-id",
                can_view_recordings=True,
            ),
        ]
    )
    await db_session.flush()

    parent_token = create_access_token(data={"sub": "parent-user-id", "role": "parent"})
    response = await client.get(
        "/api/v1/parents/visibility-settings",
        headers={"Authorization": f"Bearer {parent_token}"},
        params={"teacher_id": "teacher-user-id-prof", "student_id": "student-user-id"},
    )

    assert response.status_code == 200
    assert response.json()["can_view_recordings"] is True


@pytest.mark.asyncio
async def test_parent_cannot_save_visibility_settings(
    client: AsyncClient,
    create_test_user,
):
    """Parents cannot change teacher-controlled visibility settings."""
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )

    parent_token = create_access_token(data={"sub": "parent-user-id", "role": "parent"})
    response = await client.put(
        "/api/v1/parents/visibility-settings",
        headers={"Authorization": f"Bearer {parent_token}"},
        json={
            "teacher_id": "teacher-user-id-prof",
            "student_id": "student-user-id",
            "can_view_recordings": True,
        },
    )

    assert response.status_code == 403
