import enum
from datetime import date, datetime

from sqlalchemy import JSON, Boolean, Date, DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815, UP042


class MakeupStatus(str, enum.Enum):
    pending = "pending"
    scheduled = "scheduled"
    completed = "completed"
    expired = "expired"
    cancelled = "cancelled"


class ConfirmationCardType(str, enum.Enum):
    afterTrial = "afterTrial"
    reEnrollment = "reEnrollment"
    additionalInstrument = "additionalInstrument"


class ConfirmationCardStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    changedTime = "changedTime"
    rejected = "rejected"
    dismissed = "dismissed"
    expired = "expired"


class LessonPolicy(UUIDMixin, TimestampMixin, Base):
    """Teacher lesson policy for cancellation, reschedule, etc."""

    __tablename__ = "lesson_policies"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    lesson_class_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    cancellation_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=24)
    allow_same_day_cancel: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    late_cancel_deadline: Mapped[str | None] = mapped_column(String(5), nullable=True)
    late_cancel_deducts_lesson: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    no_show_deducts_lesson: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    grace_period_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=15)
    max_no_show_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reschedule_allowed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    reschedule_deadline_hours: Mapped[int] = mapped_column(Integer, nullable=False, default=24)
    max_reschedule_per_subscription: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    makeup_expiry_days: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    allow_carryover: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    max_carryover_lessons: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    carryover_period_months: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    full_refund_days: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    partial_refund_ratio: Mapped[int] = mapped_column(Integer, nullable=False, default=67)
    halfway_refund_ratio: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    no_show_refund_ratio: Mapped[int] = mapped_column(Integer, nullable=False, default=67)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index(
            "uk_policy_teacher_default",
            "teacher_id",
            unique=True,
            sqlite_where=lesson_class_id.is_(None),
            postgresql_where=lesson_class_id.is_(None),
        ),
        Index("uk_policy_lesson_class", "lesson_class_id", unique=True),
        Index("idx_policy_teacher_class", "teacher_id", "lesson_class_id"),
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
    lesson_request_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    card_type: Mapped[ConfirmationCardType] = mapped_column(
        Enum(ConfirmationCardType, native_enum=True),
        nullable=False,
        default=ConfirmationCardType.afterTrial,
    )
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
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
    proposed_slots: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    response_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    total_lessons: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_scc_student", "student_id"),
        Index("idx_scc_teacher", "teacher_id"),
        Index("idx_scc_status", "status"),
    )
