from datetime import datetime
from enum import StrEnum

from sqlalchemy import JSON, Boolean, DateTime, Enum, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class NotificationPriority(StrEnum):
    low = "low"
    normal = "normal"
    high = "high"
    urgent = "urgent"


class Notification(UUIDMixin, Base):
    """User notification (push and/or in-app)."""

    __tablename__ = "notifications"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    priority: Mapped[NotificationPriority] = mapped_column(
        Enum(NotificationPriority, native_enum=True),
        nullable=False,
        default=NotificationPriority.normal,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    data: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_push: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_in_app: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    action_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    action_label: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    @property
    def is_read(self) -> bool:
        """Computed property for schema compatibility."""
        return self.read_at is not None

    __table_args__ = (
        Index("idx_notif_user", "user_id"),
        Index("idx_notif_read", "user_id", "read_at"),
        Index("idx_notif_created", "created_at"),
    )


class UserNotificationPreference(UUIDMixin, TimestampMixin, Base):
    """User-scoped notification preference state."""

    __tablename__ = "user_notification_preferences"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    role: Mapped[str | None] = mapped_column(String(40), nullable=True)
    settings: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    __table_args__ = (
        Index("uk_user_notification_preferences_user", "user_id", unique=True),
    )
