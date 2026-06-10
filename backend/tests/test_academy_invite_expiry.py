"""Issue #633 — invite lifecycle cron (만료 전환 + D-1 임박 알림) regression."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_owner_and_academy(
    db_session: AsyncSession,
    *,
    owner_user_id: str,
    academy_id: str,
) -> None:
    from app.models.academy import Academy
    from app.models.user import User, UserRole

    db_session.add(
        User(
            id=owner_user_id,
            email=f"{owner_user_id}@test.com",
            name="원장",
            role=UserRole.teacher,
        )
    )
    await db_session.flush()
    db_session.add(
        Academy(
            id=academy_id,
            slug=f"slug-{academy_id}",
            name="학원",
            owner_user_id=owner_user_id,
        )
    )
    await db_session.flush()


async def _seed_invite(
    db_session: AsyncSession,
    *,
    invite_id: str,
    academy_id: str,
    invited_by_user_id: str,
    expires_at: datetime,
) -> None:
    from app.models.academy import AcademyInvite, AcademyInviteState

    db_session.add(
        AcademyInvite(
            id=invite_id,
            academy_id=academy_id,
            invited_by_user_id=invited_by_user_id,
            token_hash=f"hash-{invite_id}",
            roles=["teacher"],
            expires_at=expires_at,
            state=AcademyInviteState.pending,
        )
    )
    await db_session.flush()


@pytest.mark.asyncio
async def test_transition_expired_invites_marks_state(
    db_session: AsyncSession,
):
    """만료 시각 지난 pending invite → expired."""
    from app.models.academy import AcademyInvite, AcademyInviteState
    from app.services.academy_invite_expiry_service import transition_expired_invites

    await _seed_owner_and_academy(db_session, owner_user_id="owner-1", academy_id="acad-1")
    now = datetime.now(UTC)
    await _seed_invite(
        db_session,
        invite_id="invite-expired",
        academy_id="acad-1",
        invited_by_user_id="owner-1",
        expires_at=now - timedelta(hours=1),
    )
    await _seed_invite(
        db_session,
        invite_id="invite-active",
        academy_id="acad-1",
        invited_by_user_id="owner-1",
        expires_at=now + timedelta(days=3),
    )
    await db_session.commit()

    count = await transition_expired_invites(db_session)

    assert count == 1
    db_session.expire_all()
    expired = await db_session.get(AcademyInvite, "invite-expired")
    active = await db_session.get(AcademyInvite, "invite-active")
    assert expired.state == AcademyInviteState.expired
    assert active.state == AcademyInviteState.pending


@pytest.mark.asyncio
async def test_notify_expiring_soon_sends_to_owner_once(
    db_session: AsyncSession,
):
    """D-1 임박 pending invite → owner 알림 1건 + expiring_soon_notified_at 갱신."""
    from app.models.academy import AcademyInvite
    from app.models.notification import Notification
    from app.services.academy_invite_expiry_service import notify_expiring_soon
    from app.services.notification_service import NotificationService

    await _seed_owner_and_academy(db_session, owner_user_id="owner-2", academy_id="acad-2")
    now = datetime.now(UTC)
    # D-12h 임박.
    await _seed_invite(
        db_session,
        invite_id="invite-soon",
        academy_id="acad-2",
        invited_by_user_id="owner-2",
        expires_at=now + timedelta(hours=12),
    )
    # D-7일 — 임박 윈도우 밖.
    await _seed_invite(
        db_session,
        invite_id="invite-far",
        academy_id="acad-2",
        invited_by_user_id="owner-2",
        expires_at=now + timedelta(days=7),
    )
    await db_session.commit()

    notif = NotificationService(db_session)
    sent = await notify_expiring_soon(db_session, notif)

    assert sent == 1
    db_session.expire_all()
    soon = await db_session.get(AcademyInvite, "invite-soon")
    far = await db_session.get(AcademyInvite, "invite-far")
    assert soon.expiring_soon_notified_at is not None
    assert far.expiring_soon_notified_at is None
    notifs = (
        await db_session.scalars(
            select(Notification)
            .where(Notification.user_id == "owner-2")
            .where(Notification.type == "academyInviteExpiringSoon")
        )
    ).all()
    assert len(notifs) == 1


@pytest.mark.asyncio
async def test_notify_expiring_soon_dedupes_second_run(
    db_session: AsyncSession,
):
    """expiring_soon_notified_at != NULL 인 invite 는 재발송 안 됨."""
    from app.models.notification import Notification
    from app.services.academy_invite_expiry_service import notify_expiring_soon
    from app.services.notification_service import NotificationService

    await _seed_owner_and_academy(db_session, owner_user_id="owner-3", academy_id="acad-3")
    now = datetime.now(UTC)
    await _seed_invite(
        db_session,
        invite_id="invite-soon-3",
        academy_id="acad-3",
        invited_by_user_id="owner-3",
        expires_at=now + timedelta(hours=12),
    )
    await db_session.commit()

    notif = NotificationService(db_session)
    first = await notify_expiring_soon(db_session, notif)
    second = await notify_expiring_soon(db_session, notif)

    assert first == 1
    assert second == 0
    notifs = (await db_session.scalars(select(Notification).where(Notification.user_id == "owner-3"))).all()
    assert len(notifs) == 1


@pytest.mark.asyncio
async def test_run_tick_returns_combined_stats(
    db_session: AsyncSession,
):
    """run_tick 진입점 — 양 작업 통합 + dict 통계."""
    from app.services.academy_invite_expiry_service import run_tick

    await _seed_owner_and_academy(db_session, owner_user_id="owner-4", academy_id="acad-4")
    now = datetime.now(UTC)
    await _seed_invite(
        db_session,
        invite_id="invite-tick-expired",
        academy_id="acad-4",
        invited_by_user_id="owner-4",
        expires_at=now - timedelta(hours=2),
    )
    await _seed_invite(
        db_session,
        invite_id="invite-tick-soon",
        academy_id="acad-4",
        invited_by_user_id="owner-4",
        expires_at=now + timedelta(hours=6),
    )
    await db_session.commit()

    result = await run_tick(db_session)

    assert result == {"transitioned": 1, "notified_d1": 1}
