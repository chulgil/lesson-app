"""Notification schemas."""


import datetime as _dt
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class NotificationResponse(BaseModel):
    """Notification representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    type: str | None = None
    priority: str = "normal"
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


class NotificationPreferenceUpdate(BaseModel):
    """Patch user-scoped notification preference settings."""

    settings: dict


class NotificationPreferenceResponse(BaseModel):
    """User-scoped notification preference state."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    role: str | None = None
    settings: dict
    created_at: _dt.datetime
    updated_at: _dt.datetime


class BroadcastNotificationRequest(BaseModel):
    """Bulk teacher announcement payload."""

    teacher_id: str
    student_ids: list[str] = Field(min_length=1)
    target_filter: Literal["active_subscription", "all"]
    title: str
    body: str


class BroadcastNotificationResponse(BaseModel):
    """Bulk teacher announcement result."""

    sent_count: int
    event_created_count: int
    filtered_out_count: int
