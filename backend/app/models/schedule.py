import enum
from datetime import date, datetime

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class BookingLessonType(str, enum.Enum):
    trial = "trial"
    regular = "regular"
    oneTime = "oneTime"
    makeup = "makeup"


class BookingStatus(str, enum.Enum):
    """spec §10.2 7값 SSOT (#238, 결정 2026-04-29 옵션 A 채택).

    제거 (rename / 분리):
    - approved → confirmed (rename)
    - rejected → cancelled + decline_reason 컬럼 (사유 분리)
    - noShow → cancelled + NoShowRecord 테이블 (이력 분리)

    추가:
    - unavailable: 강사 불가 슬롯 (휴무 마킹)
    - expired: 마감 시점까지 confirm 미도달
    """

    pending = "pending"
    confirmed = "confirmed"
    changeRequested = "changeRequested"
    completed = "completed"
    cancelled = "cancelled"
    unavailable = "unavailable"
    expired = "expired"


class RequestTiming(str, enum.Enum):
    nextWeek = "nextWeek"
    nextMonth = "nextMonth"
    afterConsultation = "afterConsultation"


class RequestType(str, enum.Enum):
    trial = "trial"
    regular = "regular"


class LessonGoal(str, enum.Enum):
    hobby = "hobby"
    exam = "exam"
    major = "major"
    other = "other"


class ExperienceLevel(str, enum.Enum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"


class RequestStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    negotiating = "negotiating"
    timeConfirmed = "timeConfirmed"
    proposalSent = "proposalSent"
    proposalAccepted = "proposalAccepted"
    subscriptionIssued = "subscriptionIssued"
    paymentNotified = "paymentNotified"
    paymentConfirmed = "paymentConfirmed"
    scheduleChanged = "scheduleChanged"
    lessonCompleted = "lessonCompleted"
    lessonCancelled = "lessonCancelled"
    withdrawApproval = "withdrawApproval"
    completed = "completed"
    accepted = "accepted"
    declined = "declined"
    rejected = "rejected"
    expired = "expired"
    cancelled = "cancelled"


class GroupClassType(str, enum.Enum):
    regular = "regular"
    dropIn = "dropIn"


class VacationDisposition(str, enum.Enum):
    """How impacted lessons are processed when a vacation period is registered.

    Spec: docs/specs/schedule/teacher_vacation_mode.md §3.2 / §5.
    - makeupCredit: 영향 받는 각 레슨당 MakeupCredit 1건 적립
    - freeCancel: 수강권 차감 없이 취소
    - rollForward: 다음 회차로 이월 (수강권 자동 연장, Subscription.autoExtendedDays 증가)
    """

    makeupCredit = "makeupCredit"
    freeCancel = "freeCancel"
    rollForward = "rollForward"


class NoShowPolicy(str, enum.Enum):
    """spec 4값 SSOT (#239, 결정 2026-04-29 4값 단일 enum 채택).

    레거시 통합:
    - deduct → deductCredit (rename, 1회 차감)
    - noDeduct → noDeduction (rename)
    추가:
    - halfCredit: 0.5회 차감
    - reschedule: 차감 없이 보강 일정 강제
    """

    deductCredit = "deductCredit"
    halfCredit = "halfCredit"
    noDeduction = "noDeduction"
    reschedule = "reschedule"


class TeacherAvailability(UUIDMixin, TimestampMixin, Base):
    """Teacher available day of the week.

    Vacation Mode (§3.5 teacher_availability_spec.md):
    - vacation_mode: bool - whether vacation mode is active
    - vacation_start_date: date | None - vacation start (inclusive)
    - vacation_end_date: date | None - vacation end (inclusive)
    - vacation_reason: str | None - vacation reason (e.g. "여름방학", "시험기간")

    Note: Separate from ScheduleException(type=vacation). Both mechanisms can be
    active simultaneously; if either is active, the slot is blocked.
    """

    __tablename__ = "teacher_availabilities"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)
    vacation_mode: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    vacation_start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    vacation_end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    vacation_reason: Mapped[str | None] = mapped_column(String(100), nullable=True)

    __table_args__ = (
        Index("uk_avail_teacher_day", "teacher_id", "day_of_week", unique=True),
        CheckConstraint("day_of_week BETWEEN 0 AND 6", name="ck_teacher_availabilities_day_of_week"),
        CheckConstraint(
            "vacation_mode = false OR (vacation_start_date IS NOT NULL AND vacation_end_date IS NOT NULL)",
            name="ck_vacation_dates_required_when_active",
        ),
        CheckConstraint(
            "vacation_end_date IS NULL OR vacation_start_date IS NULL OR vacation_end_date >= vacation_start_date",
            name="ck_vacation_end_after_start",
        ),
    )


class VacationPeriod(UUIDMixin, TimestampMixin, Base):
    """Teacher vacation period — multi-day absence with bulk lesson disposition.

    Spec: docs/specs/schedule/teacher_vacation_mode.md §3.2.

    Unlike per-day-of-week vacation flags on TeacherAvailability (§3.5 legacy
    fields), this entity supports multiple concurrent vacation periods per
    teacher and tracks how impacted lessons are processed.

    Issue: #431 (G3 휴가 모드).
    """

    __tablename__ = "vacation_periods"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)  # inclusive
    end_date: Mapped[date] = mapped_column(Date, nullable=False)  # inclusive
    reason: Mapped[str | None] = mapped_column(String(200), nullable=True)
    default_disposition: Mapped[VacationDisposition] = mapped_column(
        Enum(VacationDisposition, native_enum=True),
        nullable=False,
        default=VacationDisposition.rollForward,
    )
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_vacation_teacher", "teacher_id"),
        Index("idx_vacation_dates", "start_date", "end_date"),
        CheckConstraint("end_date >= start_date", name="ck_vacation_period_end_after_start"),
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
        CheckConstraint("end_time > start_time", name="ck_availability_time_slots_temporal_order"),
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
    subscription_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("subscriptions.id", ondelete="SET NULL"),
        nullable=True,
    )
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, native_enum=True),
        nullable=False,
        default=BookingStatus.pending,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_booking_teacher", "teacher_id"),
        Index("idx_booking_student", "student_id"),
        Index("idx_booking_subscription", "subscription_id"),
        Index("idx_booking_date", "scheduled_date"),
        Index("idx_booking_status", "status"),
    )


class LessonRequest(UUIDMixin, Base):
    """Student request for lessons with a teacher (unified: trial + regular + returning)."""

    __tablename__ = "lesson_requests"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Unified lesson request fields
    request_type: Mapped[str | None] = mapped_column(String(20), nullable=True)  # trial, regular, package
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    goal: Mapped[str | None] = mapped_column(String(20), nullable=True)  # hobby, exam, major, other
    experience_level: Mapped[str | None] = mapped_column(String(20), nullable=True)  # beginner, intermediate, advanced
    preferred_day: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 0=Mon...6=Sun
    preferred_time: Mapped[str | None] = mapped_column(String(5), nullable=True)  # HH:MM
    preferred_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)  # minutes
    preferred_slots: Mapped[list | None] = mapped_column(JSON, nullable=True)
    is_returning_student: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    time_proposals: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    current_round: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    suggested_price: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Legacy fields (kept for backward compatibility)
    preferred_timing: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True,
        default="afterConsultation",
    )
    keep_previous_schedule: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    previous_lesson_day: Mapped[int | None] = mapped_column(Integer, nullable=True)
    previous_lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    previous_lesson_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Status
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="pending")
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    proposal_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    decline_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    academy_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    status_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
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
        default=NoShowPolicy.deductCredit,
    )
    max_no_show_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    repeat_days: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    repeat_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    price_per_session: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (Index("idx_group_teacher", "teacher_id"),)
