"""Parent read access for linked child memberships and lesson classes."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_parent_can_read_linked_child_membership_and_class(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Parent payment screens can reuse membership/class APIs for linked children."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher", name="Teacher")
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    db_session.add_all(
        [
            Student(id="student-001", teacher_id="test-user-id-prof", name="Child", instrument="violin"),
            Student(id="student-002", teacher_id="test-user-id-prof", name="Other", instrument="piano"),
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-001", status="active"),
            LessonClass(id="class-001", teacher_id="test-user-id-prof", name="Violin class"),
            LessonClass(id="class-002", teacher_id="test-user-id-prof", name="Other class"),
            ClassMembership(id="membership-001", lesson_class_id="class-001", student_id="student-001"),
            ClassMembership(id="membership-002", lesson_class_id="class-002", student_id="student-002"),
        ]
    )
    await db_session.flush()

    parent_headers = _headers("parent-user-id", "parent")

    memberships = await client.get(
        "/api/v1/memberships",
        headers=parent_headers,
        params={"student_id": "student-001"},
    )
    assert memberships.status_code == 200
    assert [item["id"] for item in memberships.json()] == ["membership-001"]

    class_detail = await client.get("/api/v1/lessons-classes/class-001", headers=parent_headers)
    assert class_detail.status_code == 200
    assert class_detail.json()["id"] == "class-001"

    forbidden_memberships = await client.get(
        "/api/v1/memberships",
        headers=parent_headers,
        params={"student_id": "student-002"},
    )
    assert forbidden_memberships.status_code == 403

    forbidden_class = await client.get("/api/v1/lessons-classes/class-002", headers=parent_headers)
    assert forbidden_class.status_code == 403

    mutation = await client.post(
        "/api/v1/lessons-classes/class-001/memberships",
        headers=parent_headers,
        json={"student_id": "student-001"},
    )
    assert mutation.status_code == 403
