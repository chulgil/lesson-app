"""Practice Loop Stats — #512 (선생님 측 학생별 반복 통계).

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4 (선생님 통계) + §5 (동기화).

Per-section, per-student aggregated repeat counts. Students sync up from
their local Hive override (#506 cumulative repeat counts), teachers query
to see progress + identify difficult passages.

Sync model:
- Aggregate row keyed by (student_id, section_id) — idempotent.
- ``repeat_count`` is the cumulative total reported by the client. Server
  stores the maximum-ever-seen so duplicate / out-of-order syncs cannot
  decrement.
- ``last_played_at`` is the latest known play time across syncs.

Privacy:
- Spec §5 policy — only counts/section id/timestamps are persisted.
  Loop memos (#510), bookmarks (#511) and any free-text content stay
  client-side.
"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815, UP042


class PracticeLoopStats(UUIDMixin, TimestampMixin, Base):
    """Aggregated repeat counts for one (student, section) pair."""

    __tablename__ = "practice_loop_stats"

    student_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    teacher_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teachers.id", ondelete="CASCADE"),
        nullable=False,
    )
    section_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("practice_sections.id", ondelete="CASCADE"),
        nullable=False,
    )

    # Cumulative repeat count reported by the client. Monotonically
    # non-decreasing on the server (we keep ``max(stored, incoming)``).
    repeat_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Latest play time the client knows about for this (student, section).
    last_played_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        # Idempotent sync target.
        Index(
            "uk_loop_stats_student_section",
            "student_id",
            "section_id",
            unique=True,
        ),
        Index("idx_loop_stats_teacher", "teacher_id"),
        Index("idx_loop_stats_last_played", "last_played_at"),
    )
