"""Integrity-guard tests for lesson request actor spoofing (#739) and
terminal-state transition (#740)."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.schedule import LessonRequest


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _make_request(client: AsyncClient, student_id: str, teacher_id: str) -> str:
    """Create a lesson request and return its ID."""
    resp = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers(student_id, "student"),
        json={
            "teacher_id": teacher_id,
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# FIX 1 — actor identity spoofing (#739)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_add_event_ignores_spoofed_actor_via_events_endpoint(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Student POSTing to /events with actor_id=teacher_id must store student's own id.

    Covers LessonRequestService.add_event (the /events endpoint on the
    lesson-request router).
    """
    await create_test_user(user_id="spoof-teacher-1", role="teacher", name="선생님1")
    await create_test_user(
        user_id="spoof-student-1",
        role="student",
        name="학생1",
        email="spoof-student-1@test.com",
    )

    request_id = await _make_request(client, "spoof-student-1", "spoof-teacher-1")

    # Student posts an event but claims to be the teacher (actor spoofing attempt).
    post_resp = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("spoof-student-1", "student"),
        json={
            "request_id": request_id,
            "actor_type": "teacher",  # spoofed
            "actor_id": "spoof-teacher-1",  # spoofed
            "event_type": "message",
            "message": "이 이벤트는 학생이 보냈습니다",
        },
    )
    assert post_resp.status_code == 201, post_resp.text
    body = post_resp.json()

    # Server must record the ACTUAL caller, not the client-supplied values.
    assert body["actor_id"] == "spoof-student-1", f"actor_id spoofing not blocked: got {body['actor_id']!r}"
    assert body["actor_type"] == "student", f"actor_type spoofing not blocked: got {body['actor_type']!r}"


@pytest.mark.asyncio
async def test_request_event_service_create_event_ignores_spoofed_actor(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """RequestEventService.create_event derives actor from current_user, not from payload.

    The HTTP layer routes POST /schedule/lesson-requests/{id}/events to
    LessonRequestService.add_event (first-registered router wins). We test
    RequestEventService.create_event directly at the service level using a
    lesson request created via the HTTP endpoint (to satisfy DB constraints).
    """
    from app.schemas.request_event import RequestEventCreate
    from app.services.request_event_service import RequestEventService

    teacher_user = await create_test_user(user_id="spoof-teacher-2", role="teacher", name="선생님2")
    student_user = await create_test_user(
        user_id="spoof-student-2",
        role="student",
        name="학생2",
        email="spoof-student-2@test.com",
    )

    # Create lesson request via HTTP so all NOT NULL defaults are set correctly.
    request_id = await _make_request(client, "spoof-student-2", "spoof-teacher-2")

    # Build a spoofed payload — student claims to be the teacher.
    data = RequestEventCreate(
        request_id=request_id,
        actor_type="teacher",  # spoofed
        actor_id="spoof-teacher-2",  # spoofed
        event_type="message",
        message="이 이벤트는 학생이 보냈습니다",
    )

    service = RequestEventService(db_session)
    result = await service.create_event(request_id, data, student_user)

    # Server must pin the ACTUAL caller identity.
    assert result.actor_id == "spoof-student-2", (
        f"actor_id spoofing not blocked in RequestEventService: got {result.actor_id!r}"
    )
    assert result.actor_type == "student", (
        f"actor_type spoofing not blocked in RequestEventService: got {result.actor_type!r}"
    )


# ---------------------------------------------------------------------------
# FIX 2 — terminal-state guard (#740)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_update_status_from_terminal_cancelled_returns_400(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """PATCH /status on a cancelled request must return 400."""
    await create_test_user(user_id="terminal-teacher-1", role="teacher", name="선생님T1")
    await create_test_user(
        user_id="terminal-student-1",
        role="student",
        name="학생T1",
        email="terminal-student-1@test.com",
    )

    request_id = await _make_request(client, "terminal-student-1", "terminal-teacher-1")

    # Force the request into a terminal state directly in the DB.
    request_obj = await db_session.get(LessonRequest, request_id)
    assert request_obj is not None
    request_obj.status = "cancelled"
    await db_session.flush()

    # Attempt any status transition — must be rejected.
    resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("terminal-teacher-1", "teacher"),
        json={"status": "approved"},
    )
    assert resp.status_code == 400, (
        f"Expected 400 for cancelled→approved transition, got {resp.status_code}: {resp.text}"
    )
    assert "terminal" in resp.json()["detail"].lower(), resp.json()


@pytest.mark.asyncio
async def test_update_status_from_terminal_expired_returns_400(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """PATCH /status on an expired request must return 400."""
    await create_test_user(user_id="terminal-teacher-2", role="teacher", name="선생님T2")
    await create_test_user(
        user_id="terminal-student-2",
        role="student",
        name="학생T2",
        email="terminal-student-2@test.com",
    )

    request_id = await _make_request(client, "terminal-student-2", "terminal-teacher-2")

    request_obj = await db_session.get(LessonRequest, request_id)
    assert request_obj is not None
    request_obj.status = "expired"
    await db_session.flush()

    resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("terminal-teacher-2", "teacher"),
        json={"status": "approved"},
    )
    assert resp.status_code == 400, f"Expected 400 for expired→approved transition, got {resp.status_code}: {resp.text}"


@pytest.mark.asyncio
async def test_update_status_from_terminal_completed_returns_400(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """PATCH /status on a completed request must return 400."""
    await create_test_user(user_id="terminal-teacher-3", role="teacher", name="선생님T3")
    await create_test_user(
        user_id="terminal-student-3",
        role="student",
        name="학생T3",
        email="terminal-student-3@test.com",
    )

    request_id = await _make_request(client, "terminal-student-3", "terminal-teacher-3")

    request_obj = await db_session.get(LessonRequest, request_id)
    assert request_obj is not None
    request_obj.status = "completed"
    await db_session.flush()

    resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("terminal-teacher-3", "teacher"),
        json={"status": "approved"},
    )
    assert resp.status_code == 400, (
        f"Expected 400 for completed→approved transition, got {resp.status_code}: {resp.text}"
    )


@pytest.mark.asyncio
async def test_update_status_from_non_terminal_still_works(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Valid non-terminal transition (pending→cancelled) must still succeed."""
    await create_test_user(user_id="valid-teacher-1", role="teacher", name="선생님V1")
    await create_test_user(
        user_id="valid-student-1",
        role="student",
        name="학생V1",
        email="valid-student-1@test.com",
    )

    request_id = await _make_request(client, "valid-student-1", "valid-teacher-1")

    resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("valid-student-1", "student"),
        json={"status": "cancelled"},
    )
    assert resp.status_code == 200, (
        f"Expected 200 for pending→cancelled transition, got {resp.status_code}: {resp.text}"
    )
    assert resp.json()["status"] == "cancelled"
