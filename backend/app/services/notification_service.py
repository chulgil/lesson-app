"""Notification service."""

from __future__ import annotations

import logging
from typing import Any

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import NotificationPriority
from app.schemas.common import PaginatedResponse
from app.schemas.notification import NotificationResponse
from app.services.device_token_service import DeviceTokenService
from app.services.fcm_service import FcmService

logger = logging.getLogger(__name__)

# Module-level singleton for FCM service
_fcm_service = FcmService()


class NotificationService:
    """Handle notification listing, read marking, unread counting, and push sending."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_all(
        self,
        *,
        user_id: str,
        page: int,
        size: int,
        offset: int,
        is_read: bool | None = None,
        notification_type: str | None = None,
    ) -> PaginatedResponse[NotificationResponse]:
        """List notifications for a user."""
        from app.models.notification import Notification

        query = select(Notification).where(Notification.user_id == user_id)
        if is_read is not None:
            if is_read:
                query = query.where(Notification.read_at.isnot(None))
            else:
                query = query.where(Notification.read_at.is_(None))
        if notification_type:
            query = query.where(Notification.type == notification_type)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(
            query.order_by(Notification.created_at.desc()).offset(offset).limit(size)
        )
        items = [NotificationResponse.model_validate(n) for n in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def mark_read(self, notification_id: str, user_id: str) -> None:
        """Mark a single notification as read."""
        from app.models.notification import Notification

        notif = await self.db.get(Notification, notification_id)
        if notif is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
        if notif.user_id != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your notification")
        notif.read_at = datetime.now(timezone.utc)
        await self.db.flush()

    async def mark_all_read(self, user_id: str) -> None:
        """Mark all notifications as read for a user."""
        from app.models.notification import Notification

        await self.db.execute(
            update(Notification)
            .where(Notification.user_id == user_id, Notification.read_at.is_(None))
            .values(read_at=datetime.now(timezone.utc))
        )
        await self.db.flush()

    async def get_unread_count(self, user_id: str) -> int:
        """Return the number of unread notifications."""
        from app.models.notification import Notification

        count = await self.db.scalar(
            select(func.count()).where(
                Notification.user_id == user_id,
                Notification.read_at.is_(None),
            )
        )
        return count or 0

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

        now = datetime.now(timezone.utc)

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

        # Send push notification if enabled
        if is_push:
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
                    await token_service.unregister(token)
