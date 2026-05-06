from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import JSON, Boolean, Date, DateTime, Enum, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class RangeType(StrEnum):
    full = "full"
    line = "line"
    measure = "measure"
    measures = "measures"


class PracticeItemType(StrEnum):
    repertoire = "repertoire"
    technique = "technique"
    theory = "theory"
    custom = "custom"


class PracticeItemPriority(StrEnum):
    must = "must"
    should = "should"
    could = "could"


class PieceProgress(StrEnum):
    notStarted = "notStarted"  # noqa: N815
    inProgress = "inProgress"  # noqa: N815
    polishing = "polishing"
    completed = "completed"


class PracticePiece(UUIDMixin, TimestampMixin, Base):
    """Teacher-owned practice piece library item."""

    __tablename__ = "practice_pieces"

    owner_teacher_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("teachers.id"), nullable=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    composer: Mapped[str | None] = mapped_column(String(200), nullable=True)
    opus: Mapped[str | None] = mapped_column(String(100), nullable=True)
    movement: Mapped[str | None] = mapped_column(String(100), nullable=True)
    difficulty: Mapped[str | None] = mapped_column(String(50), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_practice_piece_owner", "owner_teacher_id"),
        Index("idx_practice_piece_title", "title"),
    )


class StudentPracticePiece(UUIDMixin, TimestampMixin, Base):
    """Student assignment/progress for a practice library piece."""

    __tablename__ = "student_practice_pieces"

    student_id: Mapped[str] = mapped_column(String(36), ForeignKey("students.id"), nullable=False)
    piece_id: Mapped[str] = mapped_column(String(36), ForeignKey("practice_pieces.id"), nullable=False)
    progress: Mapped[PieceProgress] = mapped_column(
        Enum(PieceProgress, native_enum=True),
        nullable=False,
        default=PieceProgress.notStarted,
    )
    progress_percentage: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("uk_student_piece", "student_id", "piece_id", unique=True),
        Index("idx_student_piece_student", "student_id"),
        Index("idx_student_piece_piece", "piece_id"),
    )


class PracticeRepertoire(UUIDMixin, TimestampMixin, Base):
    """Practice repertoire — a collection of sections for a student."""

    __tablename__ = "practice_repertoires"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_archived: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    archived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sort_order: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index("idx_repertoire_student", "student_id"),
        Index("idx_repertoire_dates", "student_id", "start_date", "end_date"),
    )


class PracticeSection(UUIDMixin, TimestampMixin, Base):
    """A specific practice passage within a repertoire."""

    __tablename__ = "practice_sections"

    repertoire_id: Mapped[str] = mapped_column(String(36), nullable=False)
    piece_name: Mapped[str] = mapped_column(String(200), nullable=False)
    range_type: Mapped[RangeType] = mapped_column(
        Enum(RangeType, native_enum=True),
        nullable=False,
        default=RangeType.full,
    )
    start_measure: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    end_measure: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    start_line: Mapped[int | None] = mapped_column(Integer, nullable=True)
    end_line: Mapped[int | None] = mapped_column(Integer, nullable=True)
    section_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_repeat: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    repeat_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    daily_repeat_counts: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    practice_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_practice_seconds: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    target_practice_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sort_order: Mapped[int | None] = mapped_column(Integer, nullable=True)
    last_practiced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_section_repertoire", "repertoire_id"),
        Index("idx_section_completed", "is_completed"),
    )


class DailyPracticeStatus(UUIDMixin, Base):
    """Per-section, per-day completion status."""

    __tablename__ = "daily_practice_statuses"

    section_id: Mapped[str] = mapped_column(String(36), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("uk_daily_section_date", "section_id", "date", unique=True),
        Index("idx_daily_date", "date"),
    )


class PracticeRecording(UUIDMixin, Base):
    """Audio recording of a practice section."""

    __tablename__ = "practice_recordings"

    section_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    file_path: Mapped[str] = mapped_column(Text, nullable=False)
    file_key: Mapped[str | None] = mapped_column(Text, nullable=True)
    file_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    bpm: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_representative: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_practice_rec_section", "section_id"),
        Index("idx_practice_rec_student", "student_id"),
    )


class PracticeNote(UUIDMixin, TimestampMixin, Base):
    """Text note attached to a practice section."""

    __tablename__ = "practice_notes"

    section_id: Mapped[str] = mapped_column(String(36), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)

    __table_args__ = (
        Index("idx_note_section", "section_id"),
    )


class PracticeGoal(UUIDMixin, TimestampMixin, Base):
    """Student practice goals (daily/weekly targets)."""

    __tablename__ = "practice_goals"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    daily_time_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    daily_section_count: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    weekly_time_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=150)
    weekly_day_count: Mapped[int] = mapped_column(Integer, nullable=False, default=5)

    __table_args__ = (
        Index("uk_goal_student", "student_id", unique=True),
    )


class PracticeStreak(UUIDMixin, TimestampMixin, Base):
    """Student practice streak statistics."""

    __tablename__ = "practice_streaks"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    current_streak: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    longest_streak: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_practice_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    total_practice_days: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("uk_streak_student", "student_id", unique=True),
    )


class PracticeItem(UUIDMixin, TimestampMixin, Base):
    """Teacher-assigned practice item from a lesson."""

    __tablename__ = "practice_items"

    lesson_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[PracticeItemType] = mapped_column(
        Enum(PracticeItemType, native_enum=True),
        nullable=False,
        default=PracticeItemType.repertoire,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    repertoire_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    section_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    priority: Mapped[PracticeItemPriority] = mapped_column(
        Enum(PracticeItemPriority, native_enum=True),
        nullable=False,
        default=PracticeItemPriority.should,
    )
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    practice_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    has_like: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    liked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_item_lesson", "lesson_id"),
        Index("idx_item_student", "student_id"),
        Index("idx_item_teacher", "teacher_id"),
    )


class PracticeItemResource(UUIDMixin, Base):
    """Teaching resource attached to a teacher-assigned practice item."""

    __tablename__ = "practice_item_resources"

    item_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("practice_items.id", ondelete="CASCADE"),
        nullable=False,
    )
    resource_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teaching_resources.id", ondelete="CASCADE"),
        nullable=False,
    )

    __table_args__ = (
        Index("uk_practice_item_resource", "item_id", "resource_id", unique=True),
        Index("idx_practice_item_resource_resource", "resource_id"),
    )
