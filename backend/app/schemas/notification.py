"""Notification schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

from app.models.notification import NotificationPriority


class NotificationResponse(BaseModel):
    """Notification representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    type: str | None = None
    priority: NotificationPriority = NotificationPriority.normal
    title: str | None = None
    body: str | None = None
    data: dict | None = None
    scheduled_at: _dt.datetime | None = None
    sent_at: _dt.datetime | None = None
    read_at: _dt.datetime | None = None
    is_read: bool = False
    is_push: bool = True
    is_in_app: bool = True
    action_url: str | None = None
    action_label: str | None = None
    created_at: _dt.datetime | None = None


class UnreadCountResponse(BaseModel):
    """Unread notification count."""

    count: int = 0
