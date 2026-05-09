"""Relationship and follow endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_relationships(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/relationships returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/relationships", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_list_relationships_supports_repository_filters(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """RemoteTeacherStudentRelationRepository should not need client-side filtering."""
    from app.models.relationship import TeacherStudentRelation
    from app.models.student import Student
    from app.models.teacher import Teacher

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            Student(
                id="student-001",
                user_id=None,
                teacher_id="test-user-id-prof",
                name="student-001",
                instrument="violin",
            ),
            Student(
                id="student-002",
                user_id=None,
                teacher_id="test-user-id-prof",
                name="student-002",
                instrument="violin",
            ),
            Student(
                id="student-003",
                user_id=None,
                teacher_id="test-user-id-prof",
                name="student-003",
                instrument="violin",
            ),
            Student(
                id="test-user-id",
                user_id="test-user-id",
                teacher_id="test-user-id-prof",
                name="student-as-user-id",
                instrument="violin",
            ),
            Teacher(
                id="other-teacher-prof",
                user_id="other-teacher-user-id",
                instruments=[],
            ),
        ]
    )
    await db_session.flush()

    db_session.add_all(
        [
            TeacherStudentRelation(
                id="relation-active-app",
                teacher_id="test-user-id-prof",
                student_id="student-001",
                status="active",
                is_manually_registered=False,
            ),
            TeacherStudentRelation(
                id="relation-expired-manual",
                teacher_id="test-user-id-prof",
                student_id="student-002",
                status="expired",
                is_manually_registered=True,
            ),
            TeacherStudentRelation(
                id="relation-active-manual",
                teacher_id="test-user-id-prof",
                student_id="student-003",
                status="active",
                is_manually_registered=True,
            ),
            TeacherStudentRelation(
                id="relation-current-user-as-student",
                teacher_id="other-teacher-prof",
                student_id="test-user-id",
                status="active",
                is_manually_registered=False,
            ),
        ]
    )
    await db_session.flush()

    teacher_active = await client.get(
        "/api/v1/relationships",
        headers=auth_headers,
        params={"teacher_id": "test-user-id-prof", "status": "active"},
    )
    assert teacher_active.status_code == 200
    assert {item["id"] for item in teacher_active.json()["items"]} == {
        "relation-active-app",
        "relation-active-manual",
    }
    assert teacher_active.json()["total"] == 2

    manually_registered = await client.get(
        "/api/v1/relationships",
        headers=auth_headers,
        params={
            "teacher_id": "test-user-id-prof",
            "status": "active",
            "is_manually_registered": True,
        },
    )
    assert manually_registered.status_code == 200
    assert [item["id"] for item in manually_registered.json()["items"]] == [
        "relation-active-manual",
    ]
    assert manually_registered.json()["total"] == 1

    pair = await client.get(
        "/api/v1/relationships",
        headers=auth_headers,
        params={"teacher_id": "test-user-id-prof", "student_id": "student-002"},
    )
    assert pair.status_code == 200
    assert [item["id"] for item in pair.json()["items"]] == [
        "relation-expired-manual",
    ]
    assert pair.json()["total"] == 1

    by_student = await client.get(
        "/api/v1/relationships",
        headers=auth_headers,
        params={"student_id": "test-user-id"},
    )
    assert by_student.status_code == 200
    assert [item["id"] for item in by_student.json()["items"]] == [
        "relation-current-user-as-student",
    ]
    assert by_student.json()["total"] == 1


@pytest.mark.asyncio
async def test_invite_student(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/relationships/invite sends an invitation."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/relationships/invite",
        headers=auth_headers,
        json={"student_id": "student-001", "method": "sms"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["teacher_id"] == "test-user-id-prof"
    assert data["student_id"] == "student-001"
    assert "invite_code" in data
    assert data["can_view_practice"] is True
    assert data["can_comment"] is True
    assert data["can_suggest_assignments"] is True


@pytest.mark.asyncio
async def test_update_relationship_practice_permissions(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """PATCH /relationships/{id}/status updates CoachConnection-compatible permissions."""
    await create_test_user(user_id="test-user-id", role="teacher")

    from app.models.relationship import TeacherStudentRelation

    relation = TeacherStudentRelation(
        id="relation-001",
        teacher_id="test-user-id-prof",
        student_id="student-001",
        status="active",
        is_app_connected=True,
    )
    db_session.add(relation)
    await db_session.flush()

    response = await client.patch(
        "/api/v1/relationships/relation-001/status",
        headers=auth_headers,
        json={
            "status": "active",
            "can_view_practice": False,
            "can_comment": False,
            "can_suggest_assignments": True,
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["can_view_practice"] is False
    assert data["can_comment"] is False
    assert data["can_suggest_assignments"] is True


@pytest.mark.asyncio
async def test_follow_teacher(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/follows creates a follow relationship."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/follows",
        headers=auth_headers,
        json={"following_id": "teacher-002", "target_type": "teacher"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["follower_id"] == "test-user-id"
    assert data["following_id"] == "teacher-002"


@pytest.mark.asyncio
async def test_follow_list_supports_server_side_filters(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """RemoteFollowRepository should not need to fetch every follow and filter client-side."""
    from app.models.relationship import Follow

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add_all(
        [
            Follow(
                id="follow-001",
                follower_id="test-user-id",
                following_id="teacher-001",
                target_type="teacher",
            ),
            Follow(
                id="follow-002",
                follower_id="other-user",
                following_id="test-user-id",
                target_type="teacher",
            ),
            Follow(
                id="follow-003",
                follower_id="test-user-id",
                following_id="academy-001",
                target_type="academy",
            ),
        ]
    )
    await db_session.flush()

    pair = await client.get(
        "/api/v1/follows",
        headers=auth_headers,
        params={"follower_id": "test-user-id", "following_id": "teacher-001"},
    )
    assert pair.status_code == 200
    assert [item["id"] for item in pair.json()["items"]] == ["follow-001"]
    assert pair.json()["total"] == 1

    following_teachers = await client.get(
        "/api/v1/follows",
        headers=auth_headers,
        params={"direction": "following", "target_type": "teacher"},
    )
    assert following_teachers.status_code == 200
    assert [item["id"] for item in following_teachers.json()["items"]] == ["follow-001"]

    followers = await client.get(
        "/api/v1/follows",
        headers=auth_headers,
        params={"direction": "followers"},
    )
    assert followers.status_code == 200
    assert [item["id"] for item in followers.json()["items"]] == ["follow-002"]

    forbidden_pair = await client.get(
        "/api/v1/follows",
        headers=auth_headers,
        params={"follower_id": "other-user", "following_id": "someone-else"},
    )
    assert forbidden_pair.status_code == 200
    assert forbidden_pair.json()["items"] == []
