import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class BookingLessonType(str, enum.Enum):
    trial = "trial"
    regular = "regular"
    oneTime = "oneTime"


class BookingStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    cancelled = "cancelled"
    completed = "completed"
    noShow = "noShow"


class RequestTiming(str, enum.Enum):
    nextWeek = "nextWeek"
    nextMonth = "nextMonth"
    afterConsultation = "afterConsultation"


class RequestStatus(str, enum.Enum):
    pending = "pending"
    proposalSent = "proposalSent"
    accepted = "accepted"
    declined = "declined"
    expired = "expired"
    cancelled = "cancelled"


class GroupClassType(str, enum.Enum):
    regular = "regular"
    dropIn = "dropIn"


class NoShowPolicy(str, enum.Enum):
    deduct = "deduct"
    noDeduct = "noDeduct"


class TeacherAvailability(UUIDMixin, TimestampMixin, Base):
    """Teacher available day of the week."""

    __tablename__ = "teacher_availabilities"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)

    __table_args__ = (
        Index("uk_avail_teacher_day", "teacher_id", "day_of_week", unique=True),
    )


class AvailabilityTimeSlot(UUIDMixin, Base):
    """Time slot within a teacher availability day."""

    __tablename__ = "availability_time_slots"

    availability_id: Mapped[str] = mapped_column(String(36), nullable=False)
    start_time: Mapped[str] = mapped_column(String(5), nullable=False)
    end_time: Mapped[str] = mapped_column(String(5), nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_slot_availability", "availability_id"),
    )


class LessonBooking(UUIDMixin, TimestampMixin, Base):
    """Lesson booking / appointment request."""

    __tablename__ = "lesson_bookings"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    lesson_type: Mapped[BookingLessonType] = mapped_column(
        Enum(BookingLessonType, native_enum=True),
        nullable=False,
        default=BookingLessonType.regular,
    )
    scheduled_date: Mapped[date] = mapped_column(Date, nullable=False)
    scheduled_time: Mapped[str] = mapped_column(String(5), nullable=False)
    duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    location_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, native_enum=True),
        nullable=False,
        default=BookingStatus.pending,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_booking_teacher", "teacher_id"),
        Index("idx_booking_student", "student_id"),
        Index("idx_booking_date", "scheduled_date"),
        Index("idx_booking_status", "status"),
    )


class LessonRequest(UUIDMixin, Base):
    """Student request for lessons with a teacher."""

    __tablename__ = "lesson_requests"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    preferred_timing: Mapped[RequestTiming] = mapped_column(
        Enum(RequestTiming, native_enum=True),
        nullable=False,
        default=RequestTiming.afterConsultation,
    )
    keep_previous_schedule: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    previous_lesson_day: Mapped[int | None] = mapped_column(Integer, nullable=True)
    previous_lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    previous_lesson_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[RequestStatus] = mapped_column(
        Enum(RequestStatus, native_enum=True),
        nullable=False,
        default=RequestStatus.pending,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    proposal_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    decline_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    status_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_request_student", "student_id"),
        Index("idx_request_teacher", "teacher_id"),
        Index("idx_request_status", "status"),
    )


class GroupClass(UUIDMixin, TimestampMixin, Base):
    """Group class definition."""

    __tablename__ = "group_classes"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    organization_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    type: Mapped[GroupClassType] = mapped_column(
        Enum(GroupClassType, native_enum=True),
        nullable=False,
        default=GroupClassType.regular,
    )
    max_capacity: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    waitlist_capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    booking_deadline_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    cancel_deadline_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=1440)
    no_show_policy: Mapped[NoShowPolicy] = mapped_column(
        Enum(NoShowPolicy, native_enum=True),
        nullable=False,
        default=NoShowPolicy.deduct,
    )
    max_no_show_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    repeat_days: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    repeat_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    price_per_session: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_group_teacher", "teacher_id"),
    )
