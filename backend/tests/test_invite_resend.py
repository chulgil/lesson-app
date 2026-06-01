"""Invite resend + pending-list tests — G3 #5 D-G3."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _create_invite(
    db_session: AsyncSession,
    *,
    creator_id: str = "test-user-id",
    invite_code: str = "ABC123",
    expires_in_days: int = 7,
    status: str = "active",
    last_resent_at: datetime | None = None,
    resent_count: int = 0,
) -> str:
    from app.models.invite import Invite, InviteStatus, InviteUserRole

    now = datetime.now(UTC)
    invite = Invite(
        creator_id=creator_id,
        creator_name="Teacher",
        creator_role=InviteUserRole.teacher,
        invite_code=invite_code,
        invite_url=f"https://lessonaza.app/i/{invite_code}",
        qr_code_data=f"qr-{invite_code}",
        status=InviteStatus(status),
        is_single_use=True,
        max_uses=None,
        use_count=0,
        expires_at=now + timedelta(days=expires_in_days),
        resent_count=resent_count,
        last_resent_at=last_resent_at,
    )
    db_session.add(invite)
    await db_session.flush()
    return invite.id


@pytest.mark.asyncio
async def test_resend_extends_expiry_and_bumps_count(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """POST /invites/{id}/resend → expires_at +7d, resent_count+1, last_resent_at set."""
    from app.models.invite import Invite

    await create_test_user(user_id="test-user-id", role="teacher")
    invite_id = await _create_invite(db_session, expires_in_days=1)

    response = await client.post(
        f"/api/v1/invites/{invite_id}/resend",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    invite = await db_session.get(Invite, invite_id)
    await db_session.refresh(invite)
    assert invite.resent_count == 1
    assert invite.last_resent_at is not None
    # expires_at must have moved out to at least 6 days from now (7d window).
    now = datetime.now(UTC)
    invite_expires = invite.expires_at if invite.expires_at.tzinfo else invite.expires_at.replace(tzinfo=UTC)
    assert (invite_expires - now) > timedelta(days=6)


@pytest.mark.asyncio
async def test_resend_within_cooldown_returns_409(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Resend within 10 minutes of the last resend is blocked."""
    await create_test_user(user_id="test-user-id", role="teacher")
    just_resent = datetime.now(UTC) - timedelta(minutes=3)
    invite_id = await _create_invite(db_session, last_resent_at=just_resent, resent_count=1)

    response = await client.post(
        f"/api/v1/invites/{invite_id}/resend",
        headers=auth_headers,
    )

    assert response.status_code == 409, response.text
    detail = response.json()["detail"]
    assert "10" in detail or "cooldown" in detail.lower()


@pytest.mark.asyncio
async def test_resend_reactivates_expired_invite(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """An expired invite can be resurrected by a resend — status flips back to active."""
    from app.models.invite import Invite, InviteStatus

    await create_test_user(user_id="test-user-id", role="teacher")
    invite_id = await _create_invite(
        db_session,
        status="expired",
        expires_in_days=-2,
    )

    response = await client.post(
        f"/api/v1/invites/{invite_id}/resend",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    invite = await db_session.get(Invite, invite_id)
    await db_session.refresh(invite)
    assert invite.status == InviteStatus.active


@pytest.mark.asyncio
async def test_resend_other_creator_is_forbidden(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Only the creator can resend their own invite."""
    await create_test_user(user_id="test-user-id", role="teacher")
    invite_id = await _create_invite(db_session, creator_id="someone-else")

    response = await client.post(
        f"/api/v1/invites/{invite_id}/resend",
        headers=auth_headers,
    )

    assert response.status_code in (403, 404)


@pytest.mark.asyncio
async def test_resend_already_used_returns_400(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Used invites cannot be resent — the connection has already happened."""
    await create_test_user(user_id="test-user-id", role="teacher")
    invite_id = await _create_invite(db_session, status="used")

    response = await client.post(
        f"/api/v1/invites/{invite_id}/resend",
        headers=auth_headers,
    )

    assert response.status_code == 400


@pytest.mark.asyncio
async def test_pending_invites_returns_only_active_with_days_since_sent(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """GET /invites/pending — active, non-expired, not yet used, with daysSinceSent."""
    from app.models.invite import Invite

    await create_test_user(user_id="test-user-id", role="teacher")
    active_id = await _create_invite(db_session, invite_code="ACTIVE")
    await _create_invite(db_session, invite_code="EXPIREDX", status="expired", expires_in_days=-2)
    await _create_invite(db_session, invite_code="USEDX", status="used")
    await _create_invite(db_session, invite_code="OTHERX", creator_id="someone-else")

    invite = await db_session.get(Invite, active_id)
    invite.created_at = datetime.now(UTC) - timedelta(days=3)
    await db_session.commit()

    response = await client.get(
        "/api/v1/invites/pending",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    data = response.json()
    assert data["total_count"] == 1
    assert data["pending"][0]["invite_id"] == active_id
    assert data["pending"][0]["days_since_sent"] == 3
    assert data["pending"][0]["can_resend"] is True
