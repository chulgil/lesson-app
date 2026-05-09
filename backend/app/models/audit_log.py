"""Audit log model for tracking user actions and account changes."""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Index, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class AuditAction(str, enum.Enum):
    """Enumeration of audit log actions."""

    ACCOUNT_DELETE_REQUESTED = "account_delete_requested"
    ACCOUNT_DELETED = "account_deleted"
    DATA_EXPORT_REQUESTED = "data_export_requested"
    LOGIN = "login"
    LOGOUT = "logout"
    ROLE_CHANGED = "role_changed"
    SETTINGS_CHANGED = "settings_changed"


class AuditLog(UUIDMixin, Base):
    """Audit log for tracking user actions and system events."""

    __tablename__ = "audit_logs"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    action: Mapped[str] = mapped_column(String(50), nullable=False)
    details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_audit_log_user", "user_id"),
        Index("idx_audit_log_action", "action"),
        Index("idx_audit_log_created", "created_at"),
    )
