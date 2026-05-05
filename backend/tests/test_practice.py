"""Practice endpoint tests: repertoires, sections, stats."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_repertoire(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/practice/repertoires creates a repertoire and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Bach Partita No.2",
            "start_date": "2026-03-01",
            "sections": [
                {
                    "repertoire_id": "placeholder",
                    "piece_name": "Allemanda",
                    "range_type": "measures",
                    "start_measure": 1,
                    "end_measure": 16,
                },
            ],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Bach Partita No.2"
    assert data["student_id"] == "student-001"
    assert "id" in data


@pytest.mark.asyncio
async def test_list_repertoires(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/practice/repertoires returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a repertoire first
    await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Mozart Sonata K.304",
        },
    )

    response = await client.get("/api/v1/practice/repertoires", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_create_section(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/practice/sections creates a section and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a repertoire first
    rep_resp = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Vivaldi Concerto",
        },
    )
    repertoire_id = rep_resp.json()["id"]

    response = await client.post(
        "/api/v1/practice/sections",
        headers=auth_headers,
        json={
            "repertoire_id": repertoire_id,
            "piece_name": "Allegro",
            "range_type": "measures",
            "start_measure": 1,
            "end_measure": 32,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["repertoire_id"] == repertoire_id
    assert data["piece_name"] == "Allegro"
    assert data["start_measure"] == 1
    assert data["end_measure"] == 32


@pytest.mark.asyncio
async def test_toggle_section_complete(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/practice/sections/{id}/complete toggles completion."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create repertoire and section
    rep_resp = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Paganini Caprice",
        },
    )
    repertoire_id = rep_resp.json()["id"]

    sec_resp = await client.post(
        "/api/v1/practice/sections",
        headers=auth_headers,
        json={
            "repertoire_id": repertoire_id,
            "piece_name": "No.24",
            "start_measure": 1,
            "end_measure": 20,
        },
    )
    section_id = sec_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/practice/sections/{section_id}/complete",
        headers=auth_headers,
        json={
            "date": "2026-03-02",
            "is_completed": True,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == section_id


@pytest.mark.asyncio
async def test_get_practice_stats(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/practice/stats returns practice statistics."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/practice/stats", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_practice_minutes" in data
    assert "total_practice_days" in data
    assert "completed_sections" in data
    assert "current_streak" in data
    assert "longest_streak" in data


@pytest.mark.asyncio
async def test_teacher_cannot_access_other_teacher_goal_streak_stats(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Teachers cannot read or mutate goal/streak/stats for another teacher's student."""
    from app.models.student import Student

    await create_test_user(user_id="teacher-user-id", role="teacher", email="teacher@test.com")
    await create_test_user(user_id="other-teacher-user-id", role="teacher", email="other-teacher@test.com")
    db_session.add_all(
        [
            Student(
                id="owned-student",
                teacher_id="teacher-user-id-prof",
                name="Owned",
                instrument="violin",
            ),
            Student(
                id="other-student",
                teacher_id="other-teacher-user-id-prof",
                name="Other",
                instrument="piano",
            ),
        ]
    )
    await db_session.flush()

    headers = _headers("teacher-user-id", "teacher")

    for path in ("/api/v1/practice/goals", "/api/v1/practice/streak", "/api/v1/practice/stats"):
        response = await client.get(path, headers=headers, params={"student_id": "other-student"})
        assert response.status_code == 403

    goal_response = await client.put(
        "/api/v1/practice/goals",
        headers=headers,
        json={"student_id": "other-student", "daily_time_minutes": 30},
    )
    assert goal_response.status_code == 403

    streak_response = await client.put(
        "/api/v1/practice/streak",
        headers=headers,
        params={"student_id": "other-student"},
    )
    assert streak_response.status_code == 403

    record_response = await client.post(
        "/api/v1/practice/streak/record",
        headers=headers,
        params={"student_id": "other-student"},
    )
    assert record_response.status_code == 403


@pytest.mark.asyncio
async def test_parent_can_read_but_not_mutate_linked_child_goal_streak_stats(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can read linked child goal/streak/stats but cannot mutate them."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    await create_test_user(user_id="parent-user-id", role="parent")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Student(
                id="child-student",
                teacher_id="teacher-profile-id",
                name="Child",
                instrument="violin",
            ),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-student"),
        ]
    )
    await db_session.flush()

    headers = _headers("parent-user-id", "parent")

    for path in ("/api/v1/practice/goals", "/api/v1/practice/streak", "/api/v1/practice/stats"):
        response = await client.get(path, headers=headers, params={"student_id": "child-student"})
        assert response.status_code == 200

    goal_response = await client.put(
        "/api/v1/practice/goals",
        headers=headers,
        json={"student_id": "child-student", "daily_time_minutes": 30},
    )
    assert goal_response.status_code == 403

    streak_response = await client.put(
        "/api/v1/practice/streak",
        headers=headers,
        params={"student_id": "child-student"},
    )
    assert streak_response.status_code == 403

    record_response = await client.post(
        "/api/v1/practice/streak/record",
        headers=headers,
        params={"student_id": "child-student"},
    )
    assert record_response.status_code == 403


@pytest.mark.asyncio
async def test_student_can_access_own_goal_streak_stats_only(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Students can read and mutate only their own goal/streak records."""
    from app.models.student import Student

    await create_test_user(user_id="student-user-id", role="student")
    db_session.add_all(
        [
            Student(
                id="student-profile-id",
                user_id="student-user-id",
                teacher_id="teacher-profile-id",
                name="Student",
                instrument="violin",
            ),
            Student(
                id="other-student",
                user_id="other-student-user-id",
                teacher_id="teacher-profile-id",
                name="Other",
                instrument="piano",
            ),
        ]
    )
    await db_session.flush()

    headers = _headers("student-user-id", "student")

    own_goal = await client.get("/api/v1/practice/goals", headers=headers, params={"student_id": "student-profile-id"})
    assert own_goal.status_code == 200

    other_goal = await client.get("/api/v1/practice/goals", headers=headers, params={"student_id": "other-student"})
    assert other_goal.status_code == 403

    goal_response = await client.put(
        "/api/v1/practice/goals",
        headers=headers,
        json={"student_id": "student-profile-id", "daily_time_minutes": 45},
    )
    assert goal_response.status_code == 200

    streak_response = await client.put(
        "/api/v1/practice/streak",
        headers=headers,
        params={"student_id": "student-profile-id"},
    )
    assert streak_response.status_code == 200

    record_response = await client.post(
        "/api/v1/practice/streak/record",
        headers=headers,
        params={"student_id": "student-profile-id"},
    )
    assert record_response.status_code == 200
