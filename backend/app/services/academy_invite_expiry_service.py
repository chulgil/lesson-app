"""Issue #633 — 학원 초대 토큰 lifecycle cron.

정책 (academy_master.md §2.2):
- 기본 유효기간 7일 (168시간), 최대 30일 (720시간)
- pending → expired 자동 전환 (만료 시각 도래)
- D-1 (24시간 미만 잔여) 학원 owner 에 academyInviteExpiringSoon 알림 (1회만)

실행:
```bash
python -m scripts.cron.invite_expiry_tick
```

또는 외부 scheduler 에서 `run_tick(db)` 직접 호출.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academy import Academy, AcademyInvite, AcademyInviteState

logger = logging.getLogger(__name__)

# Issue #633 정책 — D-1 임박 윈도우.
EXPIRING_SOON_WINDOW_HOURS = 24


def _utcnow() -> datetime:
    return datetime.now(UTC)


def _aware(dt: datetime) -> datetime:
    """SQLite 호환 — naive datetime 을 UTC tz-aware 로 정규화."""
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=UTC)


async def transition_expired_invites(db: AsyncSession) -> int:
    """만료 시각 지난 pending invite 를 expired 로 일괄 전환. 반환: 전환 건수."""
    now = _utcnow()
    rows = (await db.scalars(select(AcademyInvite).where(AcademyInvite.state == AcademyInviteState.pending))).all()
    transitioned = 0
    for invite in rows:
        if _aware(invite.expires_at) < now:
            invite.state = AcademyInviteState.expired
            transitioned += 1
    if transitioned:
        await db.flush()
    return transitioned


async def notify_expiring_soon(db: AsyncSession, notification_service: Any) -> int:
    """D-1 임박 pending invite owner 에 알림 1회 발송.

    반환: 알림 발송 건수 (expiring_soon_notified_at 갱신).
    """
    now = _utcnow()
    cutoff = now + timedelta(hours=EXPIRING_SOON_WINDOW_HOURS)

    candidates = (
        await db.scalars(
            select(AcademyInvite)
            .where(AcademyInvite.state == AcademyInviteState.pending)
            .where(AcademyInvite.expiring_soon_notified_at.is_(None))
        )
    ).all()

    sent = 0
    for invite in candidates:
        exp = _aware(invite.expires_at)
        # 이미 만료된 것은 별도 transition 함수에서 처리.
        if exp < now or exp >= cutoff:
            continue
        academy = await db.get(Academy, invite.academy_id)
        if academy is None:
            continue
        await notification_service.create_and_send(
            user_id=academy.owner_user_id,
            notification_type="academyInviteExpiringSoon",
            title="강사 초대 만료 임박",
            body="발급한 강사 초대가 24시간 내 만료됩니다.",
            data={
                "academy_id": invite.academy_id,
                "invite_id": invite.id,
                "expires_at": exp.isoformat(),
            },
        )
        invite.expiring_soon_notified_at = now
        sent += 1
    if sent:
        await db.flush()
    return sent


async def run_tick(db: AsyncSession) -> dict[str, int]:
    """cron 진입점 — transition + notify 모두 실행. 반환: 통계 dict."""
    from app.services.notification_service import NotificationService

    expired = await transition_expired_invites(db)
    notif = NotificationService(db)
    notified = await notify_expiring_soon(db, notif)
    logger.info("academy_invite_expiry: transitioned=%d notified_d1=%d", expired, notified)
    return {"transitioned": expired, "notified_d1": notified}
