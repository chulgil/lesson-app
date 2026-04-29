import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ExceptionType(str, enum.Enum):
    holiday = "holiday"
    vacation = "vacation"
    additionalSlot = "additionalSlot"


class GroupBookingStatus(str, enum.Enum):
    confirmed = "confirmed"
    waitlist = "waitlist"
    attended = "attended"
    noShow = "noShow"
    cancelled = "cancelled"
    autoCancelled = "autoCancelled"


class GroupScheduleStatus(str, enum.Enum):
    open = "open"
    full = "full"
    closed = "closed"
    cancelled = "cancelled"
    completed = "completed"
    inProgress = "inProgress"


# #239 통합: schedule.NoShowPolicy 단일 SSOT — IndividualNoShowPolicy 는 alias 보존
from app.models.schedule import NoShowPolicy as IndividualNoShowPolicy  # noqa: E402,F401


class ScheduleChangeType(str, enum.Enum):
    singleLesson = "singleLesson"
    bulkChange = "bulkChange"


class ScheduleChangeStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    alternativeProposed = "alternativeProposed"
    cancelled = "cancelled"


class ScheduleException(UUIDMixin, Base):
    """Time exception for teacher schedule (holidays, vacations, extra slots)."""

    __tablename__ = "schedule_exceptions"

    teacher_availability_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[ExceptionType] = mapped_column(
        Enum(ExceptionType, native_enum=True),
        nullable=False,
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    start_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    end_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_sched_exc_avail", "teacher_availability_id"),
        Index("idx_sched_exc_dates", "start_date", "end_date"),
    )


class GroupClassSchedule(UUIDMixin, TimestampMixin, Base):
    """Individual session/schedule of a group class."""

    __tablename__ = "group_class_schedules"

    group_class_id: Mapped[str] = mapped_column(String(36), nullable=False)
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[GroupScheduleStatus] = mapped_column(
        Enum(GroupScheduleStatus, native_enum=True),
        nullable=False,
        default=GroupScheduleStatus.open,
    )
    current_bookings: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    waitlist_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    max_capacity: Mapped[int] = mapped_column(Integer, nullable=False)
    waitlist_capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_gcs_group_class", "group_class_id"),
        Index("idx_gcs_start", "start_time"),
        Index("idx_gcs_status", "status"),
    )


class GroupClassBooking(UUIDMixin, TimestampMixin, Base):
    """Student booking for a group class session."""

    __tablename__ = "group_class_bookings"

    schedule_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    subscription_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    status: Mapped[GroupBookingStatus] = mapped_column(
        Enum(GroupBookingStatus, native_enum=True),
        nullable=False,
        default=GroupBookingStatus.confirmed,
    )
    waitlist_position: Mapped[int | None] = mapped_column(Integer, nullable=True)
    attended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    subscription_deducted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    promoted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("uk_gcb_schedule_student", "schedule_id", "student_id", unique=True),
        Index("idx_gcb_student", "student_id"),
        Index("idx_gcb_status", "status"),
    )


class NoShowRecord(UUIDMixin, Base):
    """Record of a student no-show with applied policy."""

    __tablename__ = "no_show_records"

    lesson_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    lesson_date: Mapped[date] = mapped_column(Date, nullable=False)
    applied_policy: Mapped[IndividualNoShowPolicy] = mapped_column(
        Enum(IndividualNoShowPolicy, native_enum=True),
        nullable=False,
    )
    deducted_credits: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    makeup_lesson_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    processed_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_noshow_student", "student_id"),
        Index("idx_noshow_teacher", "teacher_id"),
        Index("idx_noshow_date", "lesson_date"),
    )


class LessonScheduleChange(UUIDMixin, Base):
    """Lesson schedule change request."""

    __tablename__ = "lesson_schedule_changes"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    change_type: Mapped[ScheduleChangeType] = mapped_column(
        Enum(ScheduleChangeType, native_enum=True),
        nullable=False,
    )
    previous_day_of_week: Mapped[int | None] = mapped_column(Integer, nullable=True)
    previous_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    new_day_of_week: Mapped[int | None] = mapped_column(Integer, nullable=True)
    new_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[ScheduleChangeStatus] = mapped_column(
        Enum(ScheduleChangeStatus, native_enum=True),
        nullable=False,
        default=ScheduleChangeStatus.pending,
    )
    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    request_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    response_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    requested_by: Mapped[str | None] = mapped_column(String(36), nullable=True)

    __table_args__ = (
        Index("idx_lsc_student", "student_id"),
        Index("idx_lsc_teacher", "teacher_id"),
        Index("idx_lsc_status", "status"),
    )
