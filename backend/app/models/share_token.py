"""Share token model for public access to student resources."""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ShareTokenScope(str, enum.Enum):
    """Scope of share token access."""

    student_summary = "student_summary"


class ShareToken(UUIDMixin, TimestampMixin, Base):
    """Token for sharing student resources publicly.

    Allows non-authenticated users to access specific student data (e.g., lesson summary)
    via a unique, expiring token.
    """

    __tablename__ = "share_tokens"

    token: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    scope: Mapped[ShareTokenScope] = mapped_column(
        Enum(ShareTokenScope, native_enum=True),
        nullable=False,
    )
    target_id: Mapped[str] = mapped_column(String(36), nullable=False)
    created_by_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("idx_share_token_expires", "expires_at"),
        Index("idx_share_token_scope_target", "scope", "target_id"),
    )
