"""Parent visibility settings endpoint tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str = "parent") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


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


@pytest.mark.asyncio
async def test_parent_child_lessons_require_active_child_relation(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents cannot read lessons for unrelated or inactive child relations."""
    from datetime import date

    from app.models.lesson import Lesson
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent-lessons@test.com")
    await create_test_user(
        user_id="other-parent-user-id",
        role="parent",
        name="Other Parent",
        email="other-parent-lessons@test.com",
    )
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", status="active"),
            Parent(id="other-parent-profile-id", user_id="other-parent-user-id", name="Other Parent", status="active"),
            Student(id="child-lesson-student", teacher_id="teacher-user-id-prof", name="Child", instrument="violin"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-lesson-student", status="inactive"),
            Lesson(
                id="child-lesson-001",
                teacher_id="teacher-user-id-prof",
                student_id="child-lesson-student",
                student_name="Child",
                instrument="violin",
                date=date(2026, 5, 6),
                start_time="14:00",
            ),
        ]
    )
    await db_session.flush()

    inactive_response = await client.get(
        "/api/v1/parents/me/children/child-lesson-student/lessons",
        headers=_headers("parent-user-id"),
    )
    unrelated_response = await client.get(
        "/api/v1/parents/me/children/child-lesson-student/lessons",
        headers=_headers("other-parent-user-id"),
    )

    assert inactive_response.status_code == 403
    assert unrelated_response.status_code == 403


@pytest.mark.asyncio
async def test_parent_child_lessons_respect_teacher_schedule_visibility(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents see only lessons whose teacher/student visibility allows schedule access."""
    from datetime import date

    from app.models.lesson import Lesson
    from app.models.parent import Parent, ParentChildRelation, ParentVisibilitySettings
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent-visible@test.com")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", status="active"),
            Student(id="visible-child", teacher_id="visible-teacher-prof", name="Child", instrument="violin"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="visible-child", status="active"),
            ParentVisibilitySettings(
                teacher_id="hidden-teacher-prof",
                student_id="visible-child",
                can_view_schedule=False,
            ),
            Lesson(
                id="visible-lesson",
                teacher_id="visible-teacher-prof",
                student_id="visible-child",
                student_name="Child",
                instrument="violin",
                date=date(2026, 5, 7),
                start_time="14:00",
            ),
            Lesson(
                id="hidden-lesson",
                teacher_id="hidden-teacher-prof",
                student_id="visible-child",
                student_name="Child",
                instrument="violin",
                date=date(2026, 5, 8),
                start_time="15:00",
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/parents/me/children/visible-child/lessons",
        headers=_headers("parent-user-id"),
    )

    assert response.status_code == 200
    assert [item["id"] for item in response.json()] == ["visible-lesson"]
