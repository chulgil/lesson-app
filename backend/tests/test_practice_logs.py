"""Tests for practice log endpoints."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_practice_log(client: AsyncClient, auth_headers, create_test_user):
    """POST /practice-logs/ should create a log for a date."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={
            "date": "2026-03-16",
            "total_minutes": 45,
            "tasks": [
                {"id": "t1", "title": "스케일 연습", "target_minutes": 15, "is_completed": False},
                {"id": "t2", "title": "에뛰드", "target_minutes": 30, "is_completed": False},
            ],
            "notes": "오늘 잘함",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "s1"
    assert data["total_minutes"] == 45
    assert len(data["tasks"]) == 2
    assert data["notes"] == "오늘 잘함"


@pytest.mark.asyncio
async def test_create_duplicate_log_same_date(client: AsyncClient, auth_headers, create_test_user):
    """Creating two logs for the same student+date should return 409."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )

    response = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 60},
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_list_practice_logs_by_month(client: AsyncClient, auth_headers, create_test_user):
    """GET /practice-logs/ should list logs for a given month."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-01", "total_minutes": 20},
    )
    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-15", "total_minutes": 30},
    )

    response = await client.get(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1", "year": 2026, "month": 3},
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 2


@pytest.mark.asyncio
async def test_get_log_by_date(client: AsyncClient, auth_headers, create_test_user):
    """GET /practice-logs/date/{date} should return specific log."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 45},
    )

    response = await client.get(
        "/api/v1/practice-logs/date/2026-03-16",
        headers=auth_headers,
        params={"student_id": "s1"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total_minutes"] == 45


@pytest.mark.asyncio
async def test_get_log_by_date_not_found(client: AsyncClient, auth_headers, create_test_user):
    """GET /practice-logs/date/{date} with no log should return null."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/practice-logs/date/2026-01-01",
        headers=auth_headers,
        params={"student_id": "s1"},
    )
    assert response.status_code == 200
    assert response.json() is None


@pytest.mark.asyncio
async def test_update_practice_log(client: AsyncClient, auth_headers, create_test_user):
    """PUT /practice-logs/{id} should update fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )
    log_id = cr.json()["id"]

    response = await client.put(
        f"/api/v1/practice-logs/{log_id}",
        headers=auth_headers,
        json={"total_minutes": 60, "notes": "추가 연습함"},
    )
    assert response.status_code == 200
    assert response.json()["total_minutes"] == 60
    assert response.json()["notes"] == "추가 연습함"


@pytest.mark.asyncio
async def test_update_practice_log_lww_conflict_rejected(client: AsyncClient, auth_headers, create_test_user):
    """#1119: a stale If-Unmodified-Since precondition → 412 CONFLICT_LWW_REJECTED, write not applied."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )
    log_id = cr.json()["id"]

    # Base version far in the past → the server row is newer → reject.
    response = await client.put(
        f"/api/v1/practice-logs/{log_id}",
        headers={**auth_headers, "If-Unmodified-Since": "2020-01-01T00:00:00Z"},
        json={"total_minutes": 99},
    )
    assert response.status_code == 412
    assert response.json()["error"]["code"] == "CONFLICT_LWW_REJECTED"

    # The rejected write must NOT have been applied.
    fetched = await client.get(f"/api/v1/practice-logs/{log_id}", headers=auth_headers)
    assert fetched.json()["total_minutes"] == 30


@pytest.mark.asyncio
async def test_update_practice_log_fresh_precondition_applies(client: AsyncClient, auth_headers, create_test_user):
    """#1119: a fresh If-Unmodified-Since precondition (server not newer) → the write applies."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )
    log_id = cr.json()["id"]

    # Base version in the future → the server row is not newer → apply.
    response = await client.put(
        f"/api/v1/practice-logs/{log_id}",
        headers={**auth_headers, "If-Unmodified-Since": "2999-01-01T00:00:00Z"},
        json={"total_minutes": 60},
    )
    assert response.status_code == 200
    assert response.json()["total_minutes"] == 60


@pytest.mark.asyncio
async def test_delete_practice_log(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /practice-logs/{id} should remove."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )
    log_id = cr.json()["id"]

    response = await client.delete(f"/api/v1/practice-logs/{log_id}", headers=auth_headers)
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_nonexistent_log(client: AsyncClient, auth_headers, create_test_user):
    """DELETE /practice-logs/{bad-id} should return 404."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.delete("/api/v1/practice-logs/nonexistent", headers=auth_headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_toggle_task(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /practice-logs/{id}/tasks/{task_id}/toggle should flip completion."""
    await create_test_user(user_id="test-user-id", role="teacher")

    cr = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={
            "date": "2026-03-16",
            "total_minutes": 30,
            "tasks": [{"id": "t1", "title": "스케일", "is_completed": False}],
        },
    )
    log_id = cr.json()["id"]

    response = await client.patch(
        f"/api/v1/practice-logs/{log_id}/tasks/t1/toggle",
        headers=auth_headers,
    )
    assert response.status_code == 200
    tasks = response.json()["tasks"]
    assert tasks[0]["is_completed"] is True

    # Toggle back
    response2 = await client.patch(
        f"/api/v1/practice-logs/{log_id}/tasks/t1/toggle",
        headers=auth_headers,
    )
    assert response2.json()["tasks"][0]["is_completed"] is False


@pytest.mark.asyncio
async def test_weekly_practice(client: AsyncClient, auth_headers, create_test_user):
    """GET /practice-logs/weekly should return 7 booleans."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create logs for Mon and Wed of a week starting 2026-03-16 (Mon)
    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 30},
    )
    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-18", "total_minutes": 20},
    )

    response = await client.get(
        "/api/v1/practice-logs/weekly",
        headers=auth_headers,
        params={"student_id": "s1", "week_start": "2026-03-16"},
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 7
    assert data[0] is True  # Mon
    assert data[1] is False  # Tue
    assert data[2] is True  # Wed


@pytest.mark.asyncio
async def test_monthly_stats(client: AsyncClient, auth_headers, create_test_user):
    """GET /practice-logs/stats should return monthly aggregate."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-01", "total_minutes": 30},
    )
    await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-02", "total_minutes": 45},
    )

    response = await client.get(
        "/api/v1/practice-logs/stats",
        headers=auth_headers,
        params={"student_id": "s1", "year": 2026, "month": 3},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["practiced_days"] == 2
    assert data["total_minutes"] == 75
    assert data["total_days"] == 31  # March has 31 days


@pytest.mark.asyncio
async def test_monthly_stats_empty(client: AsyncClient, auth_headers, create_test_user):
    """Stats for a month with no practice should return zeros."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/practice-logs/stats",
        headers=auth_headers,
        params={"student_id": "s1", "year": 2026, "month": 1},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["practiced_days"] == 0
    assert data["total_minutes"] == 0


@pytest.mark.asyncio
async def test_monthly_stats_february_leap_year(client: AsyncClient, auth_headers, create_test_user):
    """February total_days should be 28 (2026 is not a leap year)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(
        "/api/v1/practice-logs/stats",
        headers=auth_headers,
        params={"student_id": "s1", "year": 2026, "month": 2},
    )
    assert response.status_code == 200
    assert response.json()["total_days"] == 28


@pytest.mark.asyncio
async def test_zero_minutes_practice_log(client: AsyncClient, auth_headers, create_test_user):
    """Creating a log with 0 minutes should be valid."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/practice-logs/",
        headers=auth_headers,
        params={"student_id": "s1"},
        json={"date": "2026-03-16", "total_minutes": 0},
    )
    assert response.status_code == 201
    assert response.json()["total_minutes"] == 0


@pytest.mark.asyncio
async def test_teacher_cannot_access_other_teacher_practice_logs(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Teachers can only read or mutate logs for students they own."""
    from datetime import date

    from app.models.practice_log import PracticeLog
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
            PracticeLog(
                id="other-log",
                student_id="other-student",
                date=date(2026, 3, 16),
                total_minutes=30,
            ),
        ]
    )
    await db_session.flush()

    headers = _headers("teacher-user-id", "teacher")

    list_response = await client.get(
        "/api/v1/practice-logs",
        headers=headers,
        params={"student_id": "other-student"},
    )
    assert list_response.status_code == 403

    create_response = await client.post(
        "/api/v1/practice-logs",
        headers=headers,
        params={"student_id": "other-student"},
        json={"date": "2026-03-17", "total_minutes": 20},
    )
    assert create_response.status_code == 403

    update_response = await client.put(
        "/api/v1/practice-logs/other-log",
        headers=headers,
        json={"total_minutes": 60},
    )
    assert update_response.status_code == 403

    delete_response = await client.delete("/api/v1/practice-logs/other-log", headers=headers)
    assert delete_response.status_code == 403


@pytest.mark.asyncio
async def test_parent_can_read_but_not_mutate_linked_child_practice_logs(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can read active linked child logs but cannot mutate practice logs."""
    from datetime import date

    from app.models.parent import Parent, ParentChildRelation
    from app.models.practice_log import PracticeLog
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
            PracticeLog(
                id="child-log",
                student_id="child-student",
                date=date(2026, 3, 16),
                total_minutes=30,
            ),
        ]
    )
    await db_session.flush()

    headers = _headers("parent-user-id", "parent")

    list_response = await client.get(
        "/api/v1/practice-logs",
        headers=headers,
        params={"student_id": "child-student"},
    )
    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()["items"]] == ["child-log"]

    detail_response = await client.get("/api/v1/practice-logs/child-log", headers=headers)
    assert detail_response.status_code == 200

    create_response = await client.post(
        "/api/v1/practice-logs",
        headers=headers,
        params={"student_id": "child-student"},
        json={"date": "2026-03-17", "total_minutes": 20},
    )
    assert create_response.status_code == 403

    toggle_response = await client.patch(
        "/api/v1/practice-logs/child-log/tasks/t1/toggle",
        headers=headers,
    )
    assert toggle_response.status_code == 403


@pytest.mark.asyncio
async def test_student_can_access_own_practice_logs_only(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Students can read and write only their own linked student profile logs."""
    from datetime import date

    from app.models.practice_log import PracticeLog
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
            PracticeLog(
                id="own-log",
                student_id="student-profile-id",
                date=date(2026, 3, 16),
                total_minutes=30,
            ),
            PracticeLog(
                id="other-student-log",
                student_id="other-student",
                date=date(2026, 3, 16),
                total_minutes=40,
            ),
        ]
    )
    await db_session.flush()

    headers = _headers("student-user-id", "student")

    own_response = await client.get("/api/v1/practice-logs/own-log", headers=headers)
    assert own_response.status_code == 200

    other_response = await client.get("/api/v1/practice-logs/other-student-log", headers=headers)
    assert other_response.status_code == 403

    create_response = await client.post(
        "/api/v1/practice-logs",
        headers=headers,
        params={"student_id": "student-profile-id"},
        json={"date": "2026-03-17", "total_minutes": 20},
    )
    assert create_response.status_code == 201
