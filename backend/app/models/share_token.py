"""Share token model for public lesson summary access."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ShareToken(UUIDMixin, TimestampMixin, Base):
    """Hash-only public token for sharing a single lesson summary."""

    __tablename__ = "share_tokens"

    token_hash: Mapped[str] = mapped_column(String(128), nullable=False, unique=True, index=True)
    lesson_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("lessons.id", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    student_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="SET NULL"),
        nullable=True,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_accessed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    access_count: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
    )

    __table_args__ = (
        Index("idx_share_token_hash", "token_hash"),
        Index("idx_share_token_lesson", "lesson_id"),
        Index("idx_share_token_teacher", "teacher_id"),
        Index("idx_share_token_expires", "expires_at"),
        CheckConstraint("access_count >= 0", name="ck_share_tokens_access_count_non_negative"),
    )
