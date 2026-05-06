"""Practice item API contract tests for frontend mock replacement."""

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_teacher_can_manage_practice_items_with_normalized_resources(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """PracticeItemRepository contract is backed by reusable remote APIs."""
    from app.models.settings import TeachingResource
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher", name="Teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    db_session.add(
        TeachingResource(
            id="resource-001",
            teacher_id="test-user-id",
            type="youtube",
            title="Scale guide",
        )
    )
    await db_session.flush()

    created_response = await client.post(
        "/api/v1/practice/items",
        headers=auth_headers,
        json={
            "lessonId": "lesson-001",
            "studentId": "student-001",
            "type": "technique",
            "title": "G Major scale",
            "description": "Slow bowing",
            "priority": "must",
            "resourceIds": ["resource-001", "resource-001"],
        },
    )
    assert created_response.status_code == 201
    created = created_response.json()
    assert created["lessonId"] == "lesson-001"
    assert created["studentId"] == "student-001"
    assert created["teacherId"] == "test-user-id-prof"
    assert created["resourceIds"] == ["resource-001"]
    assert created["isCompleted"] is False
    assert created["practiceCount"] == 0

    item_id = created["id"]

    by_lesson = await client.get(
        "/api/v1/practice/items",
        headers=auth_headers,
        params={"lesson_id": "lesson-001"},
    )
    assert by_lesson.status_code == 200
    assert [item["id"] for item in by_lesson.json()] == [item_id]

    by_student = await client.get(
        "/api/v1/practice/items",
        headers=auth_headers,
        params={
            "student_id": "student-001",
            "date_from": datetime.now(UTC).date().isoformat(),
            "date_to": datetime.now(UTC).date().isoformat(),
        },
    )
    assert by_student.status_code == 200
    assert [item["id"] for item in by_student.json()] == [item_id]

    completed = await client.patch(
        f"/api/v1/practice/items/{item_id}/complete",
        headers=auth_headers,
    )
    assert completed.status_code == 200
    assert completed.json()["isCompleted"] is True
    assert completed.json()["practiceCount"] == 1
    assert completed.json()["completedAt"] is not None

    awaiting = await client.get(
        "/api/v1/practice/items/awaiting-feedback",
        headers=auth_headers,
    )
    assert awaiting.status_code == 200
    assert [item["id"] for item in awaiting.json()] == [item_id]

    liked = await client.patch(
        f"/api/v1/practice/items/{item_id}/like",
        headers=auth_headers,
    )
    assert liked.status_code == 200
    assert liked.json()["hasLike"] is True

    incremented = await client.patch(
        f"/api/v1/practice/items/{item_id}/practice-count/increment",
        headers=auth_headers,
    )
    assert incremented.status_code == 200
    assert incremented.json()["practiceCount"] == 2

    decremented = await client.patch(
        f"/api/v1/practice/items/{item_id}/practice-count/decrement",
        headers=auth_headers,
    )
    assert decremented.status_code == 200
    assert decremented.json()["practiceCount"] == 1

    incomplete = await client.get(
        "/api/v1/practice/items/incomplete",
        headers=auth_headers,
        params={"student_id": "student-001"},
    )
    assert incomplete.status_code == 200
    assert incomplete.json() == []

    deleted = await client.delete(f"/api/v1/practice/items/{item_id}", headers=auth_headers)
    assert deleted.status_code == 204


def test_practice_item_resources_are_normalized_in_metadata() -> None:
    """Attached teaching resources are rows with FK/unique constraints."""
    from app.models.base import Base

    item_table = Base.metadata.tables["practice_items"]
    resource_table = Base.metadata.tables["practice_item_resources"]

    assert "resource_ids" not in item_table.c
    assert "practice_items.id" in {
        fk.target_fullname for fk in resource_table.c.item_id.foreign_keys
    }
    assert "teaching_resources.id" in {
        fk.target_fullname for fk in resource_table.c.resource_id.foreign_keys
    }

    indexes = {
        tuple(index.expressions)
        for index in resource_table.indexes
        if index.unique
    }
    assert (resource_table.c.item_id, resource_table.c.resource_id) in indexes
