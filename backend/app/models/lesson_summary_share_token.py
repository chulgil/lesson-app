"""Lesson summary share token model."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class LessonSummaryShareToken(UUIDMixin, TimestampMixin, Base):
    """Opaque read-only token for public lesson summary pages."""

    __tablename__ = "lesson_summary_share_tokens"

    lesson_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("lessons.id", name="fk_lesson_summary_share_tokens_lesson_id_lessons", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", name="fk_lesson_summary_share_tokens_teacher_id_users", ondelete="CASCADE"),
        nullable=False,
    )
    student_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("students.id", name="fk_lesson_summary_share_tokens_student_id_students", ondelete="SET NULL"),
        nullable=True,
    )
    token_hash: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_accessed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    access_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        CheckConstraint(
            "access_count >= 0",
            name="ck_lesson_summary_share_tokens_access_count_non_negative",
        ),
        Index("idx_lesson_summary_share_tokens_lesson", "lesson_id"),
        Index("idx_lesson_summary_share_tokens_teacher", "teacher_id"),
        Index("idx_lesson_summary_share_tokens_expires", "expires_at"),
    )
