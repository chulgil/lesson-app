import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class MakeupStatus(str, enum.Enum):
    pending = "pending"
    scheduled = "scheduled"
    completed = "completed"
    expired = "expired"
    cancelled = "cancelled"


class ConfirmationCardStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    rejected = "rejected"
    expired = "expired"


class LessonPolicy(UUIDMixin, TimestampMixin, Base):
    """Teacher lesson policy for cancellation, reschedule, etc."""

    __tablename__ = "lesson_policies"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    cancellation_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=24)
    late_cancel_deducts_lesson: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    no_show_deducts_lesson: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    max_no_show_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reschedule_allowed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    reschedule_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=24)
    max_reschedule_per_subscription: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    makeup_expiry_days: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("uk_policy_teacher", "teacher_id", unique=True),
    )


class MakeupLesson(UUIDMixin, TimestampMixin, Base):
    """Makeup lesson record (rescheduled from a cancelled lesson)."""

    __tablename__ = "makeup_lessons"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    original_lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[MakeupStatus] = mapped_column(
        Enum(MakeupStatus, native_enum=True),
        nullable=False,
        default=MakeupStatus.pending,
    )
    scheduled_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    scheduled_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    expires_at: Mapped[date | None] = mapped_column(Date, nullable=True)

    __table_args__ = (
        Index("idx_makeup_student", "student_id"),
        Index("idx_makeup_status", "status"),
    )


class ScheduleConfirmationCard(UUIDMixin, Base):
    """Schedule confirmation card sent from teacher to student."""

    __tablename__ = "schedule_confirmation_cards"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    subscription_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[ConfirmationCardStatus] = mapped_column(
        Enum(ConfirmationCardStatus, native_enum=True),
        nullable=False,
        default=ConfirmationCardStatus.pending,
    )
    proposed_day: Mapped[str | None] = mapped_column(String(10), nullable=True)
    proposed_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    proposed_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)
    response_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_scc_student", "student_id"),
        Index("idx_scc_teacher", "teacher_id"),
        Index("idx_scc_status", "status"),
    )
