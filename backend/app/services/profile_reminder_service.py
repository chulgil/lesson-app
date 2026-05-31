"""Profile completion reminder service.

Sends push notifications to teachers who haven't completed their profile
at 24h, 3d, and 7d after signup.
"""
from __future__ import annotations

import logging
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification, NotificationPriority

logger = logging.getLogger(__name__)

# Reminder type constants
_TYPE_24H = "profileReminder24h"
_TYPE_3D = "profileReminder3d"
_TYPE_7D = "profileReminder7d"
_ALL_REMINDER_TYPES = (_TYPE_24H, _TYPE_3D, _TYPE_7D)


class ProfileReminderService:
    """Dispatch profile completion reminders to teachers."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def dispatch_reminders(self) -> dict[str, int]:
        """Check all teachers and send appropriate reminders.

        Returns counts of sent reminders by type.
        """
        from app.models.teacher import Teacher
        from app.models.user import User, UserRole
        from app.services.notification_service import NotificationService

        now = datetime.now(UTC)
        notification_service = NotificationService(self.db)
        counts: dict[str, int] = {"24h": 0, "3d": 0, "7d": 0}

        result = await self.db.execute(
            select(Teacher, User)
            .join(User, Teacher.user_id == User.id)
            .where(
                User.role == UserRole.teacher,
                User.created_at.isnot(None),
            )
        )
        rows = result.all()

        for teacher, user in rows:
            # SQLite returns naive datetimes; normalize to UTC before subtraction.
            created_at = user.created_at
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=UTC)
            hours_since_signup = (now - created_at).total_seconds() / 3600

            sent_types = await self._get_sent_types(user.id)

            if 24 <= hours_since_signup < 72 and _TYPE_24H not in sent_types:
                if self._calc_completion(teacher, user) < 50:
                    await notification_service.create_and_send(
                        user_id=user.id,
                        notification_type=_TYPE_24H,
                        title="프로필을 완성하면 학생에게 노출돼요!",
                        body="악기, 레슨 시간, 소개글을 추가해보세요",
                        priority=NotificationPriority.normal,
                        action_url="/profile",
                        action_label="프로필 완성하기",
                    )
                    counts["24h"] += 1
                    logger.info("24h profile reminder sent: user_id=%s", user.id)

            elif 72 <= hours_since_signup < 168 and _TYPE_3D not in sent_types:
                if not user.profile_image_url:
                    await notification_service.create_and_send(
                        user_id=user.id,
                        notification_type=_TYPE_3D,
                        title="프로필 사진만 추가하면 검색에 노출됩니다",
                        body="학생들이 사진이 있는 선생님을 더 신뢰해요",
                        priority=NotificationPriority.normal,
                        action_url="/profile",
                        action_label="사진 추가하기",
                    )
                    counts["3d"] += 1
                    logger.info("3d profile reminder sent: user_id=%s", user.id)

            elif 168 <= hours_since_signup < 336 and _TYPE_7D not in sent_types:
                if not teacher.introduction:
                    await notification_service.create_and_send(
                        user_id=user.id,
                        notification_type=_TYPE_7D,
                        title="웹 프로필 링크를 만들어 카톡에 공유해보세요",
                        body="소개글을 작성하면 웹 프로필이 활성화돼요",
                        priority=NotificationPriority.normal,
                        action_url="/profile",
                        action_label="소개글 작성하기",
                    )
                    counts["7d"] += 1
                    logger.info("7d profile reminder sent: user_id=%s", user.id)

        return counts

    async def _get_sent_types(self, user_id: str) -> set[str]:
        """Return the set of reminder types already sent for this user."""
        rows = await self.db.scalars(
            select(Notification.type).where(
                Notification.user_id == user_id,
                Notification.type.in_(_ALL_REMINDER_TYPES),
            )
        )
        return set(rows.all())

    def _calc_completion(self, teacher, user) -> int:
        """Calculate profile completion percentage (0-100)."""
        score = 0
        if user.name:
            score += 20
        if teacher.instruments:
            score += 20
        if user.profile_image_url:
            score += 20
        if teacher.introduction and len(teacher.introduction) >= 20:
            score += 20
        if teacher.fee_min is not None:
            score += 20
        return score
