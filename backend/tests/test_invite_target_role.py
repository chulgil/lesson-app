"""#1267 — invite target_role prebinding (teacher/student/parent QR scan routing)."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

# ---------------------------------------------------------------------------
# Creation
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
@pytest.mark.parametrize("target_role", ["teacher", "student", "parent"])
async def test_create_invite_with_target_role(client: AsyncClient, auth_headers, create_test_user, target_role: str):
    """Creating an invite with each of the 3 target roles should persist and echo it back."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"target_role": target_role},
    )
    assert response.status_code == 201, response.text
    assert response.json()["target_role"] == target_role


@pytest.mark.asyncio
async def test_create_invite_without_target_role_defaults_to_null(client: AsyncClient, auth_headers, create_test_user):
    """Legacy behavior: omitting target_role keeps it null."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    assert response.status_code == 201
    assert response.json()["target_role"] is None


@pytest.mark.asyncio
async def test_create_invite_with_invalid_target_role_returns_422(client: AsyncClient, auth_headers, create_test_user):
    """Any value outside {teacher, student, parent} must be rejected."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"target_role": "principal"},
    )
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# Lookup
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_lookup_by_id_and_code_include_target_role(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """GET-by-id (creator) and GET-by-code (joiner) responses both expose target_role."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    create_resp = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"target_role": "student"},
    )
    invite = create_resp.json()

    by_id = await client.get(f"/api/v1/invites/{invite['id']}", headers=auth_headers)
    assert by_id.status_code == 200
    assert by_id.json()["target_role"] == "student"

    by_code = await client.get(f"/api/v1/invites/code/{invite['invite_code']}", headers=student_auth_headers)
    assert by_code.status_code == 200
    assert by_code.json()["target_role"] == "student"


# ---------------------------------------------------------------------------
# Redemption validation
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_redeem_matches_target_role_succeeds(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """An existing user whose role matches target_role can redeem via connection-requests."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "student"},
        )
    ).json()

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert response.status_code == 201, response.text


@pytest.mark.asyncio
async def test_redeem_mismatched_target_role_rejected(client: AsyncClient, auth_headers, create_test_user):
    """An existing user whose role != target_role is rejected with a 4xx."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-other-teacher-id",
        role="teacher",
        email="other-teacher@test.com",
        name="Other Teacher",
    )
    other_teacher_token = create_access_token(data={"sub": "test-other-teacher-id", "role": "teacher"})
    other_teacher_headers = {"Authorization": f"Bearer {other_teacher_token}"}

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "student"},
        )
    ).json()

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=other_teacher_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert 400 <= response.status_code < 500, response.text
    assert response.status_code != 404


@pytest.mark.asyncio
async def test_redeem_parent_target_invite_mismatched_by_teacher_rejected(
    client: AsyncClient, auth_headers, create_test_user
):
    """A parent-target invite still rejects a non-parent existing user."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-other-teacher-id",
        role="teacher",
        email="other-teacher@test.com",
        name="Other Teacher",
    )
    other_teacher_token = create_access_token(data={"sub": "test-other-teacher-id", "role": "teacher"})
    other_teacher_headers = {"Authorization": f"Bearer {other_teacher_token}"}

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "parent"},
        )
    ).json()

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=other_teacher_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert 400 <= response.status_code < 500, response.text


# ---------------------------------------------------------------------------
# #1275 — parent-target invite full redemption (teacher issues, parent redeems)
# ---------------------------------------------------------------------------


def _parent_headers(user_id: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_redeem_parent_target_invite_succeeds(client: AsyncClient, auth_headers, create_test_user):
    """A parent whose role matches target_role="parent" can redeem via connection-requests.

    #1275 — this used to fail with a Postgres enum write error (masked by
    SQLite in earlier tests) because ``InviteUserRole`` had no "parent" member.
    """
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-parent-id", role="parent", email="parent@test.com", name="Parent")

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "parent"},
        )
    ).json()

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=_parent_headers("test-parent-id"),
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert response.status_code == 201, response.text
    assert response.json()["requester_role"] == "parent"
    assert response.json()["target_role"] == "teacher"


@pytest.mark.asyncio
async def test_accept_parent_target_request_creates_parent_teacher_connection(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Accepting a parent-target request must create ParentTeacherConnection.

    #1275 — the generic teacher/student accept branch would otherwise
    misattach the parent onto the roster as a fake Student via
    ``_attach_student_to_teacher``. The correct relationship is
    ``ParentTeacherConnection`` (mirrors how teacher-student acceptance
    materializes ``TeacherStudentRelation``, adapted to parent semantics).
    """
    from app.models.parent import Parent, ParentTeacherConnection
    from app.services.teacher_id_resolver import resolve_teacher_id

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-parent-id", role="parent", email="parent@test.com", name="Parent")

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "parent"},
        )
    ).json()

    redeem = await client.post(
        "/api/v1/invites/connection-requests",
        headers=_parent_headers("test-parent-id"),
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert redeem.status_code == 201, redeem.text

    response = await client.patch(
        f"/api/v1/invites/connection-requests/{redeem.json()['id']}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "accepted"

    # No fake Student/Connection should exist for the parent's user id.
    connections = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert connections.json()["total"] == 0

    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    parent = await db_session.scalar(select(Parent).where(Parent.user_id == "test-parent-id"))
    assert parent is not None
    link = await db_session.scalar(
        select(ParentTeacherConnection).where(
            ParentTeacherConnection.parent_id == parent.id,
            ParentTeacherConnection.teacher_id == teacher_id,
        )
    )
    assert link is not None


# ---------------------------------------------------------------------------
# Legacy compatibility
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_legacy_invite_without_target_role_unchanged(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Invites created before this feature (target_role=None) redeem exactly as before."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    invite = (await client.post("/api/v1/invites/", headers=auth_headers, json={})).json()
    assert invite["target_role"] is None

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert response.status_code == 201, response.text


# ---------------------------------------------------------------------------
# Accept guard — teacher-target invite referral (no connection)
# ---------------------------------------------------------------------------


async def _redeem_teacher_target_invite(client: AsyncClient, auth_headers, create_test_user) -> str:
    """Teacher A issues a teacher-target invite, teacher B redeems it. Returns the request id."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-other-teacher-id",
        role="teacher",
        email="other-teacher@test.com",
        name="Other Teacher",
    )
    other_teacher_token = create_access_token(data={"sub": "test-other-teacher-id", "role": "teacher"})
    other_teacher_headers = {"Authorization": f"Bearer {other_teacher_token}"}

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "teacher"},
        )
    ).json()

    redeem = await client.post(
        "/api/v1/invites/connection-requests",
        headers=other_teacher_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert redeem.status_code == 201, redeem.text
    return redeem.json()["id"]


@pytest.mark.asyncio
async def test_teacher_target_referral_accept_rejected(client: AsyncClient, auth_headers, create_test_user):
    """(a) Accepting a teacher-teacher referral request must be rejected with a 4xx.

    Without this guard, accept would run the teacher/student split in
    ``respond_to_request`` and attach the referring teacher to the roster as
    a Student — a data corruption bug.
    """
    request_id = await _redeem_teacher_target_invite(client, auth_headers, create_test_user)

    response = await client.patch(
        f"/api/v1/invites/connection-requests/{request_id}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert 400 <= response.status_code < 500, response.text

    # No Connection should have been created.
    connections = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert connections.json()["total"] == 0


@pytest.mark.asyncio
async def test_teacher_target_referral_reject_still_allowed(client: AsyncClient, auth_headers, create_test_user):
    """(b) Reject remains a valid cleanup path for an unwanted referral request."""
    request_id = await _redeem_teacher_target_invite(client, auth_headers, create_test_user)

    response = await client.patch(
        f"/api/v1/invites/connection-requests/{request_id}/respond",
        headers=auth_headers,
        json={"action": "reject", "rejection_reason": "Not interested"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "rejected"


@pytest.mark.asyncio
async def test_student_target_invite_accept_unaffected(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """(c) A student-target invite's connection request still accepts normally.

    (The parent side of (c) is covered separately by
    ``test_accept_parent_target_request_creates_parent_teacher_connection``
    above, since it takes a different accept branch.)
    """
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    invite = (
        await client.post(
            "/api/v1/invites/",
            headers=auth_headers,
            json={"target_role": "student"},
        )
    ).json()

    redeem = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "", "method": "inviteCode", "invite_code": invite["invite_code"]},
    )
    assert redeem.status_code == 201, redeem.text

    response = await client.patch(
        f"/api/v1/invites/connection-requests/{redeem.json()['id']}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "accepted"

    connections = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert connections.json()["total"] == 1
