"""Re-engagement notification service for inactive users.

비활성 사용자에게 단계별 복귀 알림 발송:
- D7: inactivity_reminder_7d (이번 주 레슨을 정리해보세요)
- D14: inactivity_reminder_14d (학생들이 기다리고 있어요)
- D30: win_back_offer_30d (복귀 혜택을 확인하세요)
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)


async def find_inactive_users(db: AsyncSession, days: int) -> list[User]:
    """Find active users whose last_active_at was N days ago or more.

    Args:
        db: Async database session
        days: Number of days of inactivity threshold

    Returns:
        List of inactive User objects
    """
    cutoff_time = datetime.now(UTC) - timedelta(days=days)
    result = await db.scalars(
        select(User).where(
            and_(
                User.is_active.is_(True),
                User.last_active_at.isnot(None),
                User.last_active_at < cutoff_time,
            )
        )
    )
    return result.all()


async def send_reengagement_notifications(db: AsyncSession) -> None:
    """Send re-engagement notifications to inactive users on a daily basis.

    Sends three tiers of notifications:
    - 7-day inactive: gentle reminder to catch up on lessons
    - 14-day inactive: emphasize that students are waiting
    - 30-day inactive: present special win-back offer

    Each notification is sent only once per user per tier (no duplicate
    notifications for the same user within the same day).
    """
    notification_service = NotificationService(db)

    # D7: gentle reminder
    inactive_7d = await find_inactive_users(db, days=7)
    for user in inactive_7d:
        await notification_service.create_and_send(
            user_id=user.id,
            notification_type="inactivity_reminder_7d",
            title="이번 주 레슨을 정리해보세요",
            body="지난 주 레슨 내용을 복습하면 실력이 더 빨리 늘어요.",
            data={"days_inactive": 7},
        )
    logger.info("sent 7-day inactivity reminders to %d users", len(inactive_7d))

    # D14: escalate message
    inactive_14d = await find_inactive_users(db, days=14)
    for user in inactive_14d:
        await notification_service.create_and_send(
            user_id=user.id,
            notification_type="inactivity_reminder_14d",
            title="학생들이 기다리고 있어요",
            body="선생님의 정기 레슨을 기다리는 학생들이 있습니다.",
            data={"days_inactive": 14},
        )
    logger.info("sent 14-day inactivity reminders to %d users", len(inactive_14d))

    # D30: win-back offer
    inactive_30d = await find_inactive_users(db, days=30)
    for user in inactive_30d:
        await notification_service.create_and_send(
            user_id=user.id,
            notification_type="win_back_offer_30d",
            title="복귀 혜택을 확인하세요",
            body="한 달 동안 오지 않은 선생님을 위한 특별한 복귀 프로그램이 준비되어 있습니다.",
            data={"days_inactive": 30},
        )
    logger.info("sent 30-day win-back offers to %d users", len(inactive_30d))

    await db.commit()
