"""Flat membership endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_flat_membership_endpoints_support_frontend_repository_todos(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """GET /memberships, GET /memberships/{id}, PATCH status, DELETE work without class_id context."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="student-user-id", role="student", name="Student", email="student@test.com")

    from app.models.lesson import ClassMembership, LessonClass

    db_session.add_all(
        [
            LessonClass(
                id="class-id",
                teacher_id="test-user-id-prof",
                name="Academy",
                type="academy",
                payment_type="parent",
            ),
            ClassMembership(
                id="membership-id",
                lesson_class_id="class-id",
                student_id="student-user-id",
                instrument="violin",
                status="active",
                monthly_fee=200000,
                lessons_per_week=1,
                lesson_day="Mon",
                lesson_time="14:00",
            ),
        ]
    )
    await db_session.flush()

    list_response = await client.get(
        "/api/v1/memberships",
        headers=auth_headers,
        params={"student_id": "student-user-id"},
    )
    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()] == ["membership-id"]

    detail_response = await client.get("/api/v1/memberships/membership-id", headers=auth_headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["lesson_class_id"] == "class-id"

    status_response = await client.patch(
        "/api/v1/memberships/membership-id/status",
        headers=auth_headers,
        json={"status": "paused"},
    )
    assert status_response.status_code == 200
    assert status_response.json()["status"] == "paused"

    delete_response = await client.delete("/api/v1/memberships/membership-id", headers=auth_headers)
    assert delete_response.status_code == 204

    missing_response = await client.get("/api/v1/memberships/membership-id", headers=auth_headers)
    assert missing_response.status_code == 404
