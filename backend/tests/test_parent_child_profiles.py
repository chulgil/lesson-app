"""Parent child profile API contract tests."""

from datetime import date

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_parent_lists_only_linked_child_profiles(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can list only active child profiles linked to their parent profile."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Student(
                id="child-001",
                teacher_id="teacher-001",
                name="Child One",
                instrument="violin",
                level="beginner",
                birth_date=date(2017, 1, 1),
                profile_color="#112233",
            ),
            Student(
                id="child-002",
                teacher_id="teacher-001",
                name="Child Two",
                instrument="piano",
                level="intermediate",
                birth_date=date(2015, 1, 1),
            ),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-001"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-002", status="inactive"),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/parents/parent-profile-id/child-profiles",
        headers=_headers("parent-user-id", "parent"),
    )

    assert response.status_code == 200
    assert response.json() == [
        {
            "id": "child-001",
            "parentId": "parent-profile-id",
            "name": "Child One",
            "birthYear": 2017,
            "instrument": "violin",
            "level": "beginner",
            "teacherId": "teacher-001",
            "teacherName": None,
            "linkedStudentId": "child-001",
            "profileColor": "#112233",
            "status": "active",
            "connectionStatus": "connected",
            "createdAt": response.json()[0]["createdAt"],
            "updatedAt": response.json()[0]["updatedAt"],
        }
    ]


@pytest.mark.asyncio
async def test_parent_child_profile_crud_and_access_control(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can CRUD own child profiles and cannot access unrelated children."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    await create_test_user(
        user_id="other-parent-user-id",
        role="parent",
        name="Other Parent",
        email="other-parent@test.com",
    )
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Parent(id="other-parent-profile-id", user_id="other-parent-user-id", name="Other Parent"),
            Student(id="other-child", teacher_id="", name="Other Child", instrument="piano"),
            ParentChildRelation(parent_id="other-parent-profile-id", student_id="other-child"),
        ]
    )
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/parents/child-profiles",
        headers=_headers("parent-user-id", "parent"),
        json={
            "parentId": "parent-profile-id",
            "name": "New Child",
            "birthYear": 2018,
            "instrument": "cello",
            "level": "elementary",
            "profileColor": "#445566",
        },
    )
    assert create_response.status_code == 201
    child_id = create_response.json()["id"]
    assert create_response.json()["linkedStudentId"] == child_id
    assert create_response.json()["connectionStatus"] == "unconnected"

    detail_response = await client.get(
        f"/api/v1/parents/child-profiles/{child_id}",
        headers=_headers("parent-user-id", "parent"),
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["name"] == "New Child"

    update_response = await client.put(
        f"/api/v1/parents/child-profiles/{child_id}",
        headers=_headers("parent-user-id", "parent"),
        json={"name": "Updated Child", "instrument": "violin", "level": "beginner"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "Updated Child"
    assert update_response.json()["instrument"] == "violin"

    forbidden_response = await client.get(
        "/api/v1/parents/child-profiles/other-child",
        headers=_headers("parent-user-id", "parent"),
    )
    assert forbidden_response.status_code == 403

    delete_response = await client.delete(
        f"/api/v1/parents/child-profiles/{child_id}",
        headers=_headers("parent-user-id", "parent"),
    )
    assert delete_response.status_code == 204

    deleted_detail = await client.get(
        f"/api/v1/parents/child-profiles/{child_id}",
        headers=_headers("parent-user-id", "parent"),
    )
    assert deleted_detail.status_code == 200
    assert deleted_detail.json()["status"] == "inactive"


@pytest.mark.asyncio
async def test_parent_connects_and_disconnects_teacher_for_child_profile(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can connect/disconnect a teacher for a linked child profile."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    await create_test_user(user_id="teacher-user-id", role="teacher", name="Teacher", email="teacher@test.com")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Student(id="child-001", teacher_id="", name="Child", instrument="violin"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-001"),
        ]
    )
    await db_session.flush()

    connect_response = await client.post(
        "/api/v1/parents/child-profiles/child-001/teacher",
        headers=_headers("parent-user-id", "parent"),
        json={"teacherId": "teacher-user-id-prof", "teacherName": "Teacher"},
    )
    assert connect_response.status_code == 200
    assert connect_response.json()["teacherId"] == "teacher-user-id-prof"
    assert connect_response.json()["teacherName"] == "Teacher"
    assert connect_response.json()["connectionStatus"] == "connected"

    disconnect_response = await client.delete(
        "/api/v1/parents/child-profiles/child-001/teacher",
        headers=_headers("parent-user-id", "parent"),
    )
    assert disconnect_response.status_code == 200
    assert disconnect_response.json()["teacherId"] is None
    assert disconnect_response.json()["connectionStatus"] == "unconnected"
