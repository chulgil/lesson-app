"""Notification schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    """Notification representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    type: str | None = None
    title: str | None = None
    body: str | None = None
    data: dict | None = None
    is_read: bool = False
    created_at: _dt.datetime | None = None


class UnreadCountResponse(BaseModel):
    """Unread notification count."""

    count: int = 0
