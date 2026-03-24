import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Index, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class CertificateType(str, enum.Enum):
    musicTeacher = "musicTeacher"
    cultureArtsEducator = "cultureArtsEducator"
    schoolTeacher = "schoolTeacher"
    conservatory = "conservatory"
    degree = "degree"
    performance = "performance"
    other = "other"


class CertificateStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class Teacher(UUIDMixin, TimestampMixin, Base):
    """Teacher profile linked to a user account."""

    __tablename__ = "teachers"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    instruments: Mapped[dict | list] = mapped_column(JSON, nullable=False, default=list)
    introduction: Mapped[str | None] = mapped_column(Text, nullable=True)
    experience_years: Mapped[int | None] = mapped_column(Integer, nullable=True)
    lesson_areas: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    lesson_types: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    fee_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fee_max: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fee_duration: Mapped[int | None] = mapped_column(Integer, nullable=True, default=60)
    teaching_style: Mapped[str | None] = mapped_column(Text, nullable=True)
    specialties: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)
    portfolio_video_urls: Mapped[dict | list | None] = mapped_column(JSON, nullable=True)

    # Banking info
    bank_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    account_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    account_holder: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # Phone verification
    is_phone_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    phone_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Images
    background_image: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Settings
    visibility_settings: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    __table_args__ = (
        Index("uk_teachers_user_id", "user_id", unique=True),
    )


class TeacherEducation(UUIDMixin, Base):
    """Teacher education history."""

    __tablename__ = "teacher_educations"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    school: Mapped[str] = mapped_column(String(200), nullable=False)
    major: Mapped[str | None] = mapped_column(String(100), nullable=True)
    degree: Mapped[str | None] = mapped_column(String(50), nullable=True)
    graduation_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("idx_education_teacher", "teacher_id"),
    )


class TeacherCareer(UUIDMixin, Base):
    """Teacher career / work experience."""

    __tablename__ = "teacher_careers"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    organization: Mapped[str] = mapped_column(String(200), nullable=False)
    position: Mapped[str | None] = mapped_column(String(100), nullable=True)
    start_year: Mapped[int] = mapped_column(Integer, nullable=False)
    end_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("idx_career_teacher", "teacher_id"),
    )


class TeacherCertificate(UUIDMixin, Base):
    """Teacher professional certificates."""

    __tablename__ = "teacher_certificates"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    type: Mapped[CertificateType] = mapped_column(
        Enum(CertificateType, native_enum=True),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    issuing_body: Mapped[str | None] = mapped_column(String(200), nullable=True)
    issue_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    certificate_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[CertificateStatus] = mapped_column(
        Enum(CertificateStatus, native_enum=True),
        nullable=False,
        default=CertificateStatus.pending,
    )
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_certificate_teacher", "teacher_id"),
        Index("idx_certificate_status", "status"),
    )
