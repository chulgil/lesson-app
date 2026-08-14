"""#1267 — invite target_role prebinding (teacher/student/parent QR scan routing)."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

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
    """A parent-target invite still rejects a non-parent existing user.

    NOTE: A *matching* parent redeemer cannot be exercised through this same
    endpoint today — ``InviteUserRole`` (the native enum backing
    ``ConnectionRequest.requester_role``/``target_role``) only defines
    teacher/student, so parent users structurally cannot complete
    ``create_connection_request`` yet. That gap predates this change and is
    out of scope here; the role-mismatch check itself doesn't depend on it.
    """
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

    (Parent-target invites can't be exercised through this endpoint at all —
    see the note in ``test_redeem_parent_target_invite_mismatched_by_teacher_rejected``
    above — so there is nothing to assert for the parent side of (c).)
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
