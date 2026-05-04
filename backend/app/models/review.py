import enum

from sqlalchemy import Boolean, Enum, Index, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ReviewAuthorType(str, enum.Enum):
    student = "student"
    parent = "parent"


class ReviewVisibility(str, enum.Enum):
    public = "public"
    teacherOnly = "teacherOnly"


class TeacherReview(UUIDMixin, TimestampMixin, Base):
    """Review of a teacher by a student or parent."""

    __tablename__ = "teacher_reviews"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_name: Mapped[str] = mapped_column(String(100), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_name: Mapped[str] = mapped_column(String(100), nullable=False)
    author_type: Mapped[ReviewAuthorType] = mapped_column(
        Enum(ReviewAuthorType, native_enum=True),
        nullable=False,
    )
    author_id: Mapped[str] = mapped_column(String(36), nullable=False)
    author_name: Mapped[str] = mapped_column(String(100), nullable=False)
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    tags: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    visibility: Mapped[ReviewVisibility] = mapped_column(
        Enum(ReviewVisibility, native_enum=True),
        nullable=False,
        default=ReviewVisibility.public,
    )
    is_anonymous: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("idx_review_teacher", "teacher_id"),
        Index("idx_review_student", "student_id"),
        Index("idx_review_active", "is_active"),
    )
