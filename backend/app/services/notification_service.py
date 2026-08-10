"""Notification service."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import and_, func, or_, select, true, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import NotificationPriority
from app.schemas.common import PaginatedResponse
from app.schemas.notification import NotificationPreferenceResponse, NotificationResponse
from app.services.device_token_service import DeviceTokenService
from app.services.fcm_service import FcmService

logger = logging.getLogger(__name__)

# Module-level singleton for FCM service
_fcm_service = FcmService()

TEACHER_NOTIFICATION_TYPES = frozenset(
    {
        "newStudentRegistered",
        "trialBookingRequest",
        # #1207 — 학생이 레슨을 신청하면 교사 인박스에 도착 (전용 타입).
        "lessonRequestReceived",
        "studentPracticeReport",
        "reviewReceived",
        "paymentReceived",
        "proposalAccepted",
        "rescheduleAllowanceUsed",
        "rescheduleAllowanceDepleted",
        "generalAnnouncement",
        "paymentReminderSentNotice",
        "renewalReminderSentNotice",
        # Issue #632 — 학원 강사 초대 거절 알림 (학원 owner).
        "academyInviteDeclined",
        # Issue #633 — 학원 강사 초대 만료 임박 알림 (학원 owner, D-1).
        "academyInviteExpiringSoon",
    }
)
STUDENT_NOTIFICATION_TYPES = frozenset(
    {
        "practiceReminder",
        "practiceAssigned",
        "streakWarning",
        "streakMilestone",
        "weeklyGoalAchieved",
        "recordingFeedbackReceived",
        "proposalReceived",
        "proposalReminder24h",
        "proposalReminder48h",
        "proposalReminder72h",
        "proposalExpired",
        "paymentRequested",
        "paymentReminder",
        "paymentConfirmed",
        "lessonsRunningLow",
        "teacherNoshow",
        "compensationApplied",
        "lessonNoteShared",
        # P2-2 — 그룹 수업 5종. 학생/학부모 인박스 대상 (교사는 출석부에서 직접 본다).
        "groupBookingConfirmed",
        "groupLessonReminderDayBefore",
        "groupLessonReminderDayOf",
        "groupDropInOpened",
        "groupNoShowWarning",
    }
)
BOTH_ROLE_NOTIFICATION_TYPES = frozenset(
    {
        "lessonBooked",
        "lessonReminder",
        "lessonCancelled",
        "lessonRescheduled",
        "lessonStarting",
        "lessonCompleted",
        "noshowWarning",
        "noshowConfirmed",
        "cancellationDeadline",
        "connectionRequestReceived",
        "connectionRequestAccepted",
        "connectionRequestRejected",
        "connectionEstablished",
        "connectionDisconnected",
        "makeupLessonCreated",
        "makeupLessonExpiring",
        "makeupLessonExpired",
        "scheduleChangeRequested",
        "scheduleChangeApproved",
        "scheduleChangeRejected",
        "scheduleChangeAlternative",
        "subscriptionExpiringSoon",
        "subscriptionExpired",
        "generalAnnouncement",
    }
)
KNOWN_ROLE_TARGETED_TYPES = TEACHER_NOTIFICATION_TYPES | STUDENT_NOTIFICATION_TYPES | BOTH_ROLE_NOTIFICATION_TYPES


class NotificationService:
    """Handle notification listing, read marking, unread counting, and push sending."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_preferences(self, current_user: Any) -> NotificationPreferenceResponse:
        """Return user notification preferences, creating role defaults on first access."""
        preference = await self._get_or_create_preferences(current_user)
        return NotificationPreferenceResponse.model_validate(preference)

    async def update_preferences(
        self,
        current_user: Any,
        settings: dict[str, Any],
    ) -> NotificationPreferenceResponse:
        """Merge and persist user notification preference settings."""
        preference = await self._get_or_create_preferences(current_user)
        preference.settings = {**self._default_preferences(current_user), **(preference.settings or {}), **settings}
        preference.role = self._role_value(current_user)
        await self.db.flush()
        await self.db.refresh(preference)
        return NotificationPreferenceResponse.model_validate(preference)

    async def get_all(
        self,
        *,
        user_id: str,
        user_role: Any = None,
        page: int,
        size: int,
        offset: int,
        is_read: bool | None = None,
        notification_type: str | None = None,
    ) -> PaginatedResponse[NotificationResponse]:
        """List notifications for a user."""
        from app.models.notification import Notification

        visible_filter = self._visible_in_app_filter(Notification)
        query = select(Notification).where(
            Notification.user_id == user_id,
            visible_filter,
            self._recipient_role_filter(Notification, user_role),
        )
        if is_read is not None:
            if is_read:
                query = query.where(Notification.read_at.isnot(None))
            else:
                query = query.where(Notification.read_at.is_(None))
        if notification_type:
            query = query.where(Notification.type == notification_type)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.order_by(Notification.created_at.desc()).offset(offset).limit(size))
        items = [NotificationResponse.model_validate(n) for n in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def _get_or_create_preferences(self, current_user: Any) -> Any:
        from app.models.notification import UserNotificationPreference

        preference = await self.db.scalar(
            select(UserNotificationPreference).where(UserNotificationPreference.user_id == current_user.id)
        )
        if preference is None:
            preference = UserNotificationPreference(
                user_id=current_user.id,
                role=self._role_value(current_user),
                settings=self._default_preferences(current_user),
            )
            self.db.add(preference)
            await self.db.flush()
            await self.db.refresh(preference)
        return preference

    def _default_preferences(self, current_user: Any) -> dict[str, Any]:
        role = self._role_value(current_user)
        if role == "teacher":
            return {
                "lessonReminderEnabled": True,
                "lessonReminderTimes": [1440],
                "newStudentAlert": True,
                "trialBookingAlert": True,
                "paymentReceivedAlert": True,
                "studentPracticeReport": False,
                "reviewReceivedAlert": True,
                "dndEnabled": True,
                "dndStart": {"hour": 22, "minute": 0},
                "dndEnd": {"hour": 8, "minute": 0},
            }
        return {
            "lessonReminderEnabled": True,
            "lessonReminderTimes": [1440],
            "practiceReminderEnabled": True,
            "practiceReminderTime": {"hour": 19, "minute": 0},
            "streakWarningEnabled": True,
            "streakWarningTime": {"hour": 21, "minute": 0},
            "paymentReminderEnabled": True,
            "dndEnabled": True,
            "dndStart": {"hour": 22, "minute": 0},
            "dndEnd": {"hour": 8, "minute": 0},
            "maxDailyNotifications": 5,
        }

    def _role_value(self, current_user: Any) -> str | None:
        return getattr(getattr(current_user, "role", None), "value", getattr(current_user, "role", None))

    async def mark_read(self, notification_id: str, user_id: str) -> None:
        """Mark a single notification as read."""
        from app.models.notification import Notification

        notif = await self.db.get(Notification, notification_id)
        if notif is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
        if notif.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your notification")
        if notif.read_at is None:
            notif.read_at = datetime.now(UTC)
        await self.db.flush()

    async def delete(self, notification_id: str, user_id: str) -> None:
        """Delete a single notification (ownership 검증)."""
        from app.models.notification import Notification

        notif = await self.db.get(Notification, notification_id)
        if notif is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
        if notif.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your notification")
        await self.db.delete(notif)
        await self.db.flush()

    async def mark_all_read(self, user_id: str, user_role: Any = None) -> None:
        """Mark all notifications as read for a user."""
        from app.models.notification import Notification

        visible_filter = self._visible_in_app_filter(Notification)
        role_filter = self._recipient_role_filter(Notification, user_role)
        await self.db.execute(
            update(Notification)
            .where(
                Notification.user_id == user_id,
                visible_filter,
                role_filter,
                Notification.read_at.is_(None),
            )
            .values(read_at=datetime.now(UTC))
        )
        await self.db.flush()

    async def get_unread_count(self, user_id: str, user_role: Any = None) -> int:
        """Return the number of unread notifications."""
        from app.models.notification import Notification

        visible_filter = self._visible_in_app_filter(Notification)
        count = await self.db.scalar(
            select(func.count()).where(
                Notification.user_id == user_id,
                visible_filter,
                self._recipient_role_filter(Notification, user_role),
                Notification.read_at.is_(None),
            )
        )
        return count or 0

    def _recipient_role_filter(self, notification_model: Any, user_role: Any) -> Any:
        """Return the predicate matching frontend notification target-role policy."""
        role = getattr(user_role, "value", user_role)
        if role == "teacher":
            allowed_types = TEACHER_NOTIFICATION_TYPES | BOTH_ROLE_NOTIFICATION_TYPES
        elif role in {"student", "parent"}:
            allowed_types = STUDENT_NOTIFICATION_TYPES | BOTH_ROLE_NOTIFICATION_TYPES
        else:
            return true()

        return or_(
            notification_model.type.not_in(KNOWN_ROLE_TARGETED_TYPES),
            notification_model.type.in_(allowed_types),
        )

    def _visible_in_app_filter(self, notification_model: Any) -> Any:
        """Return the predicate for notifications visible in the in-app inbox."""
        return and_(
            notification_model.is_in_app.is_(True),
            or_(
                notification_model.sent_at.isnot(None),
                notification_model.scheduled_at.is_(None),
                notification_model.scheduled_at <= datetime.now(UTC),
            ),
        )

    async def create_and_send(
        self,
        *,
        user_id: str,
        notification_type: str,
        title: str,
        body: str,
        priority: NotificationPriority = NotificationPriority.normal,
        data: dict[str, Any] | None = None,
        action_url: str | None = None,
        action_label: str | None = None,
        is_push: bool = True,
        is_in_app: bool = True,
    ) -> None:
        """Create a notification record and send push notification.

        This is the primary method for triggering notifications from business logic.
        It persists the notification to DB and sends FCM push if enabled.
        """
        from app.models.notification import Notification

        now = datetime.now(UTC)

        notification = Notification(
            user_id=user_id,
            type=notification_type,
            priority=priority,
            title=title,
            body=body,
            data=data,
            is_push=is_push,
            is_in_app=is_in_app,
            action_url=action_url,
            action_label=action_label,
            sent_at=now,
        )
        self.db.add(notification)
        await self.db.flush()

        # Send push notification if enabled. Best-effort: a push-path failure
        # (token lookup, FCM transport, token cleanup) must never abort the
        # caller's business transaction — the in-app row above is the source
        # of truth and ~30 core write paths call this without their own guard.
        if is_push:
            try:
                token_service = DeviceTokenService(self.db)
                tokens = await token_service.get_tokens_for_user(user_id)

                if tokens:
                    failed_tokens = await _fcm_service.send_to_user(
                        tokens=tokens,
                        title=title,
                        body=body,
                        notification_type=notification_type,
                        priority=priority,
                        data=data,
                        action_url=action_url,
                        action_label=action_label,
                    )

                    # Clean up invalid tokens
                    for token in failed_tokens:
                        await token_service.unregister(token, user_id)
            except Exception:  # noqa: BLE001 — push is best-effort by contract
                logger.warning(
                    "push send failed for user %s (type=%s) — in-app row kept",
                    user_id,
                    notification_type,
                    exc_info=True,
                )
