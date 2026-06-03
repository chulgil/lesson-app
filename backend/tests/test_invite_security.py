"""Security regression tests for invite/connection-request IDOR and state bugs.

Covers:
- GET /invites/{id} ownership (creator-only).
- GET /invites/code/{code} field redaction for non-creators.
- respond_to_request double-accept guard (no duplicate Connection).
- public landing tolerates a NULL expires_at without a 500.
"""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient


# ---------------------------------------------------------------------------
# GET /invites/{id} — creator-only
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_invite_by_id_non_creator_forbidden(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """A non-creator must not read an invite by id (IDOR)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    invite = create_resp.json()

    forbidden = await client.get(f"/api/v1/invites/{invite['id']}", headers=student_auth_headers)
    assert forbidden.status_code == 403

    allowed = await client.get(f"/api/v1/invites/{invite['id']}", headers=auth_headers)
    assert allowed.status_code == 200
    assert allowed.json()["id"] == invite["id"]


# ---------------------------------------------------------------------------
# GET /invites/code/{code} — redaction for non-creators
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_code_lookup_redacts_sensitive_fields_for_non_creator(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Joiner can resolve an invite by code but cannot harvest qr/note/usage."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"max_uses": 5, "note": "secret note"},
    )
    invite = create_resp.json()

    # Non-creator: resolves invite (200) but sensitive fields are blanked.
    non_creator = await client.get(
        f"/api/v1/invites/code/{invite['invite_code']}",
        headers=student_auth_headers,
    )
    assert non_creator.status_code == 200
    data = non_creator.json()
    assert data["id"] == invite["id"]
    assert data["invite_code"] == invite["invite_code"]
    assert not data["qr_code_data"]
    assert not data["invite_url"]
    assert data["note"] is None
    assert data["use_count"] == 0
    assert data["max_uses"] is None

    # Creator: gets the full record with sensitive fields intact.
    creator = await client.get(
        f"/api/v1/invites/code/{invite['invite_code']}",
        headers=auth_headers,
    )
    assert creator.status_code == 200
    full = creator.json()
    assert full["qr_code_data"]
    assert full["invite_url"]
    assert full["note"] == "secret note"
    assert full["max_uses"] == 5


# ---------------------------------------------------------------------------
# respond_to_request — double-accept guard
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_double_accept_returns_400_and_creates_single_connection(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """A second accept on an already-accepted request must 400 and not duplicate."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    req_id = create_resp.json()["id"]

    first = await client.patch(
        f"/api/v1/invites/connection-requests/{req_id}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert first.status_code == 200
    assert first.json()["status"] == "accepted"

    second = await client.patch(
        f"/api/v1/invites/connection-requests/{req_id}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert second.status_code == 400

    conns = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert conns.status_code == 200
    assert conns.json()["total"] == 1


# ---------------------------------------------------------------------------
# Public landing — NULL expires_at must not 500
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_public_landing_null_expires_at_no_500(db_session):
    """A NULL expires_at must not raise AttributeError (500) on the landing.

    The DB schema enforces NOT NULL on `expires_at`, so the anomalous state is
    reproduced with a stub invite passed straight to the service, exercising the
    null-guard without relying on a DB row.
    """
    from fastapi import HTTPException

    from app.models.invite import InviteStatus
    from app.services.invite_service import InviteService

    class _StubInvite:
        invite_code = "NULLEX"
        status = InviteStatus.active
        expires_at = None  # the bug trigger: .tzinfo access would raise

    service = InviteService(db_session)

    async def _fake_scalar(_query):
        return _StubInvite()

    # Bypass the real query so the service evaluates the null-expiry guard.
    service.db.scalar = _fake_scalar  # type: ignore[method-assign]

    with pytest.raises(HTTPException) as exc_info:
        await service.get_public_invite_landing("NULLEX")

    # 410 (treated as unavailable) — NOT a 500 AttributeError.
    assert exc_info.value.status_code == 410
