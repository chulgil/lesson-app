import enum
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    Index,
    Integer,
    JSON,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class LessonClassType(str, enum.Enum):
    academy = "academy"
    private = "private"


class PaymentType(str, enum.Enum):
    organization = "organization"
    parent = "parent"


class LessonStatus(str, enum.Enum):
    scheduled = "scheduled"
    completed = "completed"
    cancelled = "cancelled"
    cancelledByStudentAdvance = "cancelledByStudentAdvance"
    cancelledByStudentLate = "cancelledByStudentLate"
    cancelledByTeacher = "cancelledByTeacher"
    cancelledMutual = "cancelledMutual"
    noShow = "noShow"
    studentAbsent = "studentAbsent"
    reschedulePending = "reschedulePending"


class LocationType(str, enum.Enum):
    academyRoom = "academyRoom"
    teacherStudio = "teacherStudio"
    studentHome = "studentHome"
    externalPlace = "externalPlace"
    online = "online"


class LessonClass(UUIDMixin, TimestampMixin, Base):
    """Lesson class / organization grouping."""

    __tablename__ = "lesson_classes"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    type: Mapped[LessonClassType] = mapped_column(
        Enum(LessonClassType, native_enum=True),
        nullable=False,
        default=LessonClassType.private,
    )
    payment_type: Mapped[PaymentType] = mapped_column(
        Enum(PaymentType, native_enum=True),
        nullable=False,
        default=PaymentType.parent,
    )
    contact_person: Mapped[str | None] = mapped_column(String(100), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_archived: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index("idx_class_teacher", "teacher_id"),
    )


class ClassMembership(UUIDMixin, TimestampMixin, Base):
    """Student membership in a lesson class."""

    __tablename__ = "class_memberships"

    class MembershipStatus(str, enum.Enum):
        trial = "trial"
        active = "active"
        paused = "paused"
        terminated = "terminated"

    lesson_class_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    instrument: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    status: Mapped[MembershipStatus] = mapped_column(
        Enum(MembershipStatus, native_enum=True),
        nullable=False,
        default=MembershipStatus.active,
    )
    level: Mapped[str | None] = mapped_column(String(50), nullable=True)
    monthly_fee: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lessons_per_week: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    lesson_day: Mapped[str | None] = mapped_column(String(10), nullable=True)
    lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    lesson_duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    travel_time_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)

    __table_args__ = (
        Index("idx_membership_class", "lesson_class_id"),
        Index("idx_membership_student", "student_id"),
        Index("uk_membership_class_student", "lesson_class_id", "student_id", unique=True),
    )


class LessonLocation(UUIDMixin, TimestampMixin, Base):
    """Physical or online location for lessons."""

    __tablename__ = "lesson_locations"

    lesson_class_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    owner_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    type: Mapped[LocationType] = mapped_column(
        Enum(LocationType, native_enum=True),
        nullable=False,
        default=LocationType.teacherStudio,
    )
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    address_detail: Mapped[str | None] = mapped_column(String(200), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    online_platform: Mapped[str | None] = mapped_column(String(100), nullable=True)
    online_link: Mapped[str | None] = mapped_column(Text, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_location_class", "lesson_class_id"),
        Index("idx_location_owner", "owner_id"),
    )


class Lesson(UUIDMixin, TimestampMixin, Base):
    """Individual lesson record."""

    __tablename__ = "lessons"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    student_name: Mapped[str] = mapped_column(String(100), nullable=False)
    teacher_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    instrument: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    date: Mapped[date] = mapped_column(Date, nullable=False)
    start_time: Mapped[str] = mapped_column(String(5), nullable=False)
    duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    status: Mapped[LessonStatus] = mapped_column(
        Enum(LessonStatus, native_enum=True),
        nullable=False,
        default=LessonStatus.scheduled,
    )
    feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    key_points: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    practice_tips: Mapped[str | None] = mapped_column(Text, nullable=True)
    location_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    location_address: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_lesson_student", "student_id"),
        Index("idx_lesson_teacher", "teacher_id"),
        Index("idx_lesson_date", "date"),
        Index("idx_lesson_status", "status"),
        Index("idx_lesson_teacher_date", "teacher_id", "date"),
    )


class LessonPiece(UUIDMixin, Base):
    """Musical piece performed in a lesson."""

    __tablename__ = "lesson_pieces"

    lesson_id: Mapped[str] = mapped_column(String(36), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    composer: Mapped[str | None] = mapped_column(String(100), nullable=True)
    opus: Mapped[str | None] = mapped_column(String(50), nullable=True)
    movement: Mapped[str | None] = mapped_column(String(50), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("idx_piece_lesson", "lesson_id"),
    )


class LessonRecording(UUIDMixin, Base):
    """Audio recording of a lesson."""

    __tablename__ = "lesson_recordings"

    lesson_id: Mapped[str] = mapped_column(String(36), nullable=False)
    file_path: Mapped[str] = mapped_column(Text, nullable=False)
    file_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    duration: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    transcription: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_summary: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("idx_lesson_rec_lesson", "lesson_id"),
    )
