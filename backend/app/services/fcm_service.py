"""FCM push notification sending service."""

from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

from app.models.notification import NotificationPriority

logger = logging.getLogger(__name__)

# FCM priority mapping based on notification spec
_FCM_PRIORITY_MAP = {
    NotificationPriority.urgent: "high",
    NotificationPriority.high: "high",
    NotificationPriority.normal: "normal",
    NotificationPriority.low: "normal",
}

# DND-bypassing notification types (spec: 5 types)
_DND_BYPASS_TYPES = {
    "lessonStarting",
    "lessonCancelled",
    "lessonRescheduled",
    "noshowWarning",
    "noshowConfirmed",
}

# Types excluded from push (spec: 2 types)
_PUSH_EXCLUDED_TYPES = {
    "lessonCompleted",
    "studentPracticeReport",
}


class FcmService:
    """Send push notifications via Firebase Cloud Messaging.

    Requires GOOGLE_APPLICATION_CREDENTIALS environment variable pointing
    to the Firebase service account JSON file.
    """

    def __init__(self) -> None:
        self._initialized = False

    def _ensure_initialized(self) -> bool:
        """Lazy-initialize Firebase Admin SDK."""
        if self._initialized:
            return True

        try:
            import firebase_admin
            from firebase_admin import credentials

            if not firebase_admin._apps:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred)

            self._initialized = True
            return True
        except Exception:
            logger.warning("Firebase Admin SDK not initialized. Push notifications disabled.")
            return False

    async def send_to_user(
        self,
        *,
        tokens: list[str],
        title: str,
        body: str,
        notification_type: str,
        priority: NotificationPriority = NotificationPriority.normal,
        data: dict[str, Any] | None = None,
        action_url: str | None = None,
        action_label: str | None = None,
    ) -> list[str]:
        """Send push notification to a user's devices.

        Args:
            tokens: List of FCM device tokens for the user.
            title: Notification title.
            body: Notification body text.
            notification_type: The notification type string.
            priority: Notification priority level.
            data: Extra data payload.
            action_url: Deep link URL for notification tap.
            action_label: Action button label.

        Returns:
            List of tokens that failed (for cleanup).
        """
        if not tokens:
            return []

        if notification_type in _PUSH_EXCLUDED_TYPES:
            return []

        if not self._ensure_initialized():
            return []

        from firebase_admin import messaging

        fcm_priority = _FCM_PRIORITY_MAP.get(priority, "normal")

        # Build data payload
        payload: dict[str, str] = {
            "type": notification_type,
            "priority": priority.value,
            "title": title,
            "body": body,
        }
        if data:
            payload["extra"] = json.dumps(data)
        if action_url:
            payload["action_url"] = action_url
        if action_label:
            payload["action_label"] = action_label

        # Build FCM notification (for system tray display)
        notification = messaging.Notification(title=title, body=body)

        # Android-specific config
        android_config = messaging.AndroidConfig(
            priority=fcm_priority,
            notification=messaging.AndroidNotification(
                channel_id="lesson_channel",
                priority="max" if fcm_priority == "high" else "default",
            ),
        )

        # iOS (APNs) config
        apns_headers: dict[str, str] = {
            "apns-priority": "10" if fcm_priority == "high" else "5",
        }
        if notification_type in _DND_BYPASS_TYPES:
            apns_headers["apns-push-type"] = "alert"

        apns_config = messaging.APNSConfig(
            headers=apns_headers,
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(title=title, body=body),
                    sound="default",
                    badge=1,
                ),
            ),
        )

        failed_tokens: list[str] = []

        # Send to each device token
        messages = [
            messaging.Message(
                notification=notification,
                data=payload,
                android=android_config,
                apns=apns_config,
                token=token,
            )
            for token in tokens
        ]

        try:
            response = await asyncio.to_thread(messaging.send_each, messages)

            for i, send_response in enumerate(response.responses):
                if send_response.exception is not None:
                    error = send_response.exception
                    # Mark invalid tokens for cleanup
                    if hasattr(error, "code") and error.code in (
                        "NOT_FOUND",
                        "UNREGISTERED",
                        "INVALID_ARGUMENT",
                    ):
                        failed_tokens.append(tokens[i])
                    logger.warning(
                        "FCM send failed for token %s: %s",
                        tokens[i][:20],
                        error,
                    )
        except Exception:
            logger.exception("FCM batch send failed")

        return failed_tokens

    async def send_to_topic(
        self,
        *,
        topic: str,
        title: str,
        body: str,
        notification_type: str,
        data: dict[str, Any] | None = None,
    ) -> bool:
        """Send push notification to a topic.

        Returns True if sent successfully.
        """
        if not self._ensure_initialized():
            return False

        from firebase_admin import messaging

        payload: dict[str, str] = {
            "type": notification_type,
            "title": title,
            "body": body,
        }
        if data:
            payload["extra"] = json.dumps(data)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=payload,
            topic=topic,
        )

        try:
            await asyncio.to_thread(messaging.send, message)
            return True
        except Exception:
            logger.exception("FCM topic send failed for topic %s", topic)
            return False
