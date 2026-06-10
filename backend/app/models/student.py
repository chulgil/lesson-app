import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin

# ruff: noqa: N815, UP042


class StudentLevel(str, enum.Enum):
    beginner = "beginner"
    elementary = "elementary"
    intermediate = "intermediate"
    advanced = "advanced"


class StudentStatus(str, enum.Enum):
    trial = "trial"
    active = "active"
    paused = "paused"
    inactive = "inactive"


class AgeGroup(str, enum.Enum):
    child = "child"
    student = "student"
    adult = "adult"


class PaymentRequestTarget(str, enum.Enum):
    """Issue #636 — 입금 안내 받을 대상.

    spec user_master.md §5.2 — 선생님이 학생별로 설정.
    default = student (본인 입금).
    """

    student = "student"
    parent = "parent"


class PracticeLevel(str, enum.Enum):
    newStudent = "newStudent"
    excellent = "excellent"
    average = "average"
    poor = "poor"
    onBreak = "onBreak"


class Student(UUIDMixin, TimestampMixin, Base):
    """Student profile, may be linked to a user account."""

    __tablename__ = "students"

    user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    teacher_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("teachers.id", ondelete="RESTRICT"),
        nullable=True,
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    instrument: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    level: Mapped[StudentLevel] = mapped_column(
        Enum(StudentLevel, native_enum=True),
        nullable=False,
        default=StudentLevel.beginner,
    )
    status: Mapped[StudentStatus] = mapped_column(
        Enum(StudentStatus, native_enum=True),
        nullable=False,
        default=StudentStatus.active,
    )
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    parent_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    parent_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    age_group: Mapped[AgeGroup | None] = mapped_column(
        Enum(AgeGroup, native_enum=True),
        nullable=True,
    )
    profile_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    background_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    profile_color: Mapped[str | None] = mapped_column(String(7), nullable=True, default="#6B5B95")
    # Issue #636 — spec user_master.md §5.2 — 입금 안내 대상 (학생/학부모).
    payment_request_target: Mapped[PaymentRequestTarget] = mapped_column(
        Enum(PaymentRequestTarget, native_enum=True),
        nullable=False,
        default=PaymentRequestTarget.student,
        server_default=PaymentRequestTarget.student.value,
    )

    # Lesson defaults
    monthly_fee: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lessons_per_week: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    lesson_day: Mapped[str | None] = mapped_column(String(10), nullable=True)
    lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    lesson_duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)

    # Connection (G3 Phase B-2b — `connection_status` column dropped;
    # `connected_at` is the canonical app-connected signal, alongside
    # `TeacherStudentRelation.status`).
    connected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Practice
    practice_level: Mapped[PracticeLevel | None] = mapped_column(
        Enum(PracticeLevel, native_enum=True),
        nullable=True,
    )
    break_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    expected_return_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Address (private to connected teachers)
    postal_code: Mapped[str | None] = mapped_column(String(10), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    address_detail: Mapped[str | None] = mapped_column(String(200), nullable=True)
    district: Mapped[str | None] = mapped_column(String(50), nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_students_user_id", "user_id"),
        Index("idx_students_teacher_id", "teacher_id"),
        Index("idx_students_status", "status"),
    )
