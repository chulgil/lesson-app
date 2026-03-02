import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Index, String, Text, func
from sqlalchemy.dialects.mysql import JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class NotificationPriority(str, enum.Enum):
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
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    is_push: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_in_app: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    action_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    action_label: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
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
