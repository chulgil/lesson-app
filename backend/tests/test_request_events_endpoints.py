"""RequestEvent router tests — Plan A Phase 1 SSOT endpoints.

Covers:
- POST /api/v1/schedule/lesson-requests/{request_id}/events
- GET  /api/v1/schedule/lesson-requests/{request_id}/events
- GET  /api/v1/schedule/request-events/{event_id}
- PATCH /api/v1/schedule/request-events/{event_id}

Permission boundaries:
- Only teacher/student of the lesson_request can read events.
- Only the event author can PATCH the event.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_lesson_request(
    db_session: AsyncSession,
    *,
    teacher_id: str = "test-user-id",
    student_id: str = "test-student-id",
) -> str:
    """Insert a minimal LessonRequest and return its id."""
    from app.models.schedule import LessonRequest

    request = LessonRequest(
        student_id=student_id,
        teacher_id=teacher_id,
        message="want trial",
        status="pending",
        expires_at=datetime.now(UTC) + timedelta(days=14),
    )
    db_session.add(request)
    await db_session.flush()
    await db_session.refresh(request)
    return request.id


@pytest.mark.asyncio
async def test_create_event_as_student(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """Student can append an initialRequest event to their own lesson request."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
            "message": "안녕하세요, 레슨 신청합니다",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["request_id"] == request_id
    assert data["actor_id"] == "test-student-id"
    assert data["event_type"] == "initialRequest"
    assert data["message"] == "안녕하세요, 레슨 신청합니다"
    assert "id" in data
    assert "created_at" in data


@pytest.mark.asyncio
async def test_create_event_with_suggested_slots(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """Teacher can propose alternative slots via proposeAlternative event."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "proposeAlternative",
            "suggested_slots": [
                {"start_time": "14:00", "end_time": "15:00", "is_selected": False},
                {"start_time": "16:00", "end_time": "17:00", "is_selected": False},
            ],
            "message": "이 시간 어떠세요?",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["event_type"] == "proposeAlternative"
    assert len(data["suggested_slots"]) == 2
    assert data["suggested_slots"][0]["start_time"] == "14:00"


@pytest.mark.asyncio
async def test_create_event_request_id_mismatch(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """request_id in body must match path → 400."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": "different-id",
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
        },
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_create_event_actor_id_mismatch(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """actor_id must match the authenticated user → 403."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "someone-else",
            "event_type": "initialRequest",
        },
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_event_non_participant_forbidden(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """A user who is neither teacher nor student of the request → 403."""
    from app.core.security import create_access_token

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    await create_test_user(user_id="outsider", role="teacher", email="out@t.com")
    request_id = await _seed_lesson_request(db_session)

    outsider_token = create_access_token(data={"sub": "outsider", "role": "teacher"})
    headers = {"Authorization": f"Bearer {outsider_token}"}

    response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "outsider",
            "event_type": "message",
            "message": "hi",
        },
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_event_request_not_found(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
) -> None:
    """Unknown lesson_request id → 404."""
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")

    response = await client.post(
        "/api/v1/schedule/lesson-requests/nonexistent/events",
        headers=student_auth_headers,
        json={
            "request_id": "nonexistent",
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
        },
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_list_events_chronological(
    client: AsyncClient,
    auth_headers: dict[str, str],
    student_auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """GET /events returns events oldest first."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    # student appends 1, teacher appends 1
    await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
            "message": "first",
        },
    )
    await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "approve",
            "message": "second",
        },
    )

    response = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=auth_headers,
    )
    assert response.status_code == 200
    events = response.json()
    assert len(events) == 2
    assert events[0]["message"] == "first"
    assert events[1]["message"] == "second"


@pytest.mark.asyncio
async def test_get_single_event(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """GET /request-events/{event_id} returns one event for participants."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    create = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
            "message": "hello",
        },
    )
    event_id = create.json()["id"]

    response = await client.get(
        f"/api/v1/schedule/request-events/{event_id}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["message"] == "hello"


@pytest.mark.asyncio
async def test_patch_event_only_actor(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """PATCH allowed by author, forbidden for the other participant."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")
    request_id = await _seed_lesson_request(db_session)

    create = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=student_auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "test-student-id",
            "event_type": "initialRequest",
            "message": "hi",
        },
    )
    event_id = create.json()["id"]

    # Teacher (not the author) cannot PATCH → 403
    forbidden = await client.patch(
        f"/api/v1/schedule/request-events/{event_id}",
        headers=auth_headers,
        json={"message": "edit by teacher"},
    )
    assert forbidden.status_code == 403

    # Author can PATCH → 200
    ok = await client.patch(
        f"/api/v1/schedule/request-events/{event_id}",
        headers=student_auth_headers,
        json={"message": "edited"},
    )
    assert ok.status_code == 200
    assert ok.json()["message"] == "edited"


@pytest.mark.asyncio
async def test_patch_event_not_found(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
) -> None:
    """PATCH unknown event id → 404."""
    await create_test_user(user_id="test-student-id", role="student", email="s@t.com")

    response = await client.patch(
        "/api/v1/schedule/request-events/nonexistent",
        headers=student_auth_headers,
        json={"message": "x"},
    )
    assert response.status_code == 404
