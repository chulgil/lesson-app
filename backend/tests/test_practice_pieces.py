"""Practice piece library API contract tests."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_teacher_can_crud_and_search_practice_pieces(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Teachers can manage their piece library and search by title/composer."""
    await create_test_user(user_id="test-user-id", role="teacher", name="Teacher")

    create_response = await client.post(
        "/api/v1/practice/pieces",
        headers=auth_headers,
        json={
            "title": "Minuet in G",
            "composer": "Bach",
            "opus": "BWV Anh. 114",
            "movement": "I",
            "difficulty": "beginner",
            "notes": "For early bow control",
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["title"] == "Minuet in G"
    assert created["composer"] == "Bach"
    assert created["progress"] == "notStarted"
    assert created["progressPercentage"] == 0.0

    piece_id = created["id"]
    detail_response = await client.get(f"/api/v1/practice/pieces/{piece_id}", headers=auth_headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == piece_id

    update_response = await client.put(
        f"/api/v1/practice/pieces/{piece_id}",
        headers=auth_headers,
        json={"title": "Minuet in G Major", "difficulty": "elementary"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["title"] == "Minuet in G Major"

    search_response = await client.get(
        "/api/v1/practice/pieces/search",
        headers=auth_headers,
        params={"q": "bach"},
    )
    assert search_response.status_code == 200
    assert [item["id"] for item in search_response.json()] == [piece_id]

    delete_response = await client.delete(f"/api/v1/practice/pieces/{piece_id}", headers=auth_headers)
    assert delete_response.status_code == 204
    missing_response = await client.get(f"/api/v1/practice/pieces/{piece_id}", headers=auth_headers)
    assert missing_response.status_code == 404


@pytest.mark.asyncio
async def test_teacher_assigns_piece_to_student_and_updates_progress(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Teachers can assign owned pieces to their students and update progress."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher", name="Teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/practice/pieces",
        headers=auth_headers,
        json={"title": "Etude No. 1", "composer": "Kayser"},
    )
    piece_id = create_response.json()["id"]

    assign_response = await client.post(
        f"/api/v1/practice/students/student-001/pieces/{piece_id}",
        headers=auth_headers,
    )
    assert assign_response.status_code == 200

    repertoire_response = await client.get(
        "/api/v1/practice/students/student-001/repertoire",
        headers=auth_headers,
    )
    assert repertoire_response.status_code == 200
    assert repertoire_response.json()["studentId"] == "student-001"
    assert [item["id"] for item in repertoire_response.json()["currentPieces"]] == [piece_id]
    assert repertoire_response.json()["completedPieces"] == []

    progress_response = await client.patch(
        f"/api/v1/practice/students/student-001/pieces/{piece_id}/progress",
        headers=auth_headers,
        json={"progress": "completed"},
    )
    assert progress_response.status_code == 200
    assert progress_response.json()["progress"] == "completed"
    assert progress_response.json()["progressPercentage"] == 1.0

    completed_repertoire = await client.get(
        "/api/v1/practice/students/student-001/repertoire",
        headers=auth_headers,
    )
    assert [item["id"] for item in completed_repertoire.json()["completedPieces"]] == [piece_id]
    assert completed_repertoire.json()["currentPieces"] == []

    remove_response = await client.delete(
        f"/api/v1/practice/students/student-001/pieces/{piece_id}",
        headers=auth_headers,
    )
    assert remove_response.status_code == 204


@pytest.mark.asyncio
async def test_parent_can_read_linked_child_piece_repertoire(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """A linked parent can read a child's piece repertoire but not an unrelated child."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher", name="Teacher")
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    db_session.add_all(
        [
            Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"),
            Student(id="student-002", teacher_id="test-user-id-prof", name="Other", instrument="piano"),
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-001"),
        ]
    )
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/practice/pieces",
        headers=auth_headers,
        json={"title": "Suzuki Twinkle", "composer": "Suzuki"},
    )
    piece_id = create_response.json()["id"]
    await client.post(f"/api/v1/practice/students/student-001/pieces/{piece_id}", headers=auth_headers)

    parent_response = await client.get(
        "/api/v1/practice/students/student-001/repertoire",
        headers=_headers("parent-user-id", "parent"),
    )
    assert parent_response.status_code == 200
    assert [item["id"] for item in parent_response.json()["currentPieces"]] == [piece_id]

    forbidden_response = await client.get(
        "/api/v1/practice/students/student-002/repertoire",
        headers=_headers("parent-user-id", "parent"),
    )
    assert forbidden_response.status_code == 403
