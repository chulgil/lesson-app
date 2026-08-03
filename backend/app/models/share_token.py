"""Share token model for public lesson summary access."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# Issue #1217 — resource_type discriminator. Plain string (not a native PG
# enum) to avoid the ALTER TYPE ADD VALUE migration pain documented for other
# native enums in this codebase; validity is enforced by a CheckConstraint.
SHARE_TOKEN_RESOURCE_LESSON_SUMMARY = "lesson_summary"
SHARE_TOKEN_RESOURCE_GROWTH_REPORT = "growth_report"


class ShareToken(UUIDMixin, TimestampMixin, Base):
    """Hash-only public token for sharing a lesson summary or growth report."""

    __tablename__ = "share_tokens"

    token_hash: Mapped[str] = mapped_column(String(128), nullable=False, unique=True, index=True)
    # Issue #1217 — discriminates the resource this token grants public access
    # to. Existing rows default to "lesson_summary" (the only resource type
    # before this column existed).
    resource_type: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=SHARE_TOKEN_RESOURCE_LESSON_SUMMARY,
        server_default=SHARE_TOKEN_RESOURCE_LESSON_SUMMARY,
    )
    # Nullable — growth-report tokens (#1217) are scoped by student_id, not a
    # single lesson.
    lesson_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("lessons.id", ondelete="CASCADE"),
        nullable=True,
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
        CheckConstraint(
            "resource_type IN ('lesson_summary', 'growth_report')",
            name="ck_share_tokens_resource_type_valid",
        ),
        CheckConstraint(
            "resource_type != 'growth_report' OR student_id IS NOT NULL",
            name="ck_share_tokens_growth_report_requires_student",
        ),
    )
