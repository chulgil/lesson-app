"""Device token model for push notification delivery."""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Index, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class DevicePlatform(str, enum.Enum):
    ios = "ios"
    android = "android"


class DeviceToken(UUIDMixin, Base):
    """Stores FCM device tokens for push notification delivery."""

    __tablename__ = "device_tokens"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    token: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    platform: Mapped[DevicePlatform] = mapped_column(
        Enum(DevicePlatform, native_enum=True),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("idx_device_token_user", "user_id"),
        Index("idx_device_token_token", "token", unique=True),
    )
