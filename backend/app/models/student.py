import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


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


class ConnectionStatus(str, enum.Enum):
    offline = "offline"
    inviteSent = "inviteSent"
    inviteReceived = "inviteReceived"
    connected = "connected"
    disconnected = "disconnected"


class PracticeLevel(str, enum.Enum):
    newStudent = "newStudent"
    excellent = "excellent"
    average = "average"
    poor = "poor"
    onBreak = "onBreak"


class Student(UUIDMixin, TimestampMixin, Base):
    """Student profile, may be linked to a user account."""

    __tablename__ = "students"

    user_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
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
    profile_color: Mapped[str | None] = mapped_column(String(7), nullable=True, default="#6B5B95")

    # Lesson defaults
    monthly_fee: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lessons_per_week: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    lesson_day: Mapped[str | None] = mapped_column(String(10), nullable=True)
    lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    lesson_duration: Mapped[int] = mapped_column(Integer, nullable=False, default=60)

    # Connection
    connection_status: Mapped[ConnectionStatus] = mapped_column(
        Enum(ConnectionStatus, native_enum=True),
        nullable=False,
        default=ConnectionStatus.offline,
    )
    connected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Practice
    practice_level: Mapped[PracticeLevel | None] = mapped_column(
        Enum(PracticeLevel, native_enum=True),
        nullable=True,
    )
    break_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    expected_return_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_students_user_id", "user_id"),
        Index("idx_students_teacher_id", "teacher_id"),
        Index("idx_students_status", "status"),
        Index("idx_students_connection", "connection_status"),
    )
