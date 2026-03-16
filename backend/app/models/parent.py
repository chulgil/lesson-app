import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ParentStatus(str, enum.Enum):
    pending = "pending"
    active = "active"
    inactive = "inactive"


class ParentPermission(str, enum.Enum):
    viewOnly = "viewOnly"
    managePayments = "managePayments"
    manageLessons = "manageLessons"
    fullAccess = "fullAccess"


class Parent(UUIDMixin, TimestampMixin, Base):
    """Parent profile linked to a user account."""

    __tablename__ = "parents"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    profile_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    profile_color: Mapped[str | None] = mapped_column(String(7), nullable=True, default="#6B5B95")
    status: Mapped[ParentStatus] = mapped_column(
        Enum(ParentStatus, native_enum=True),
        nullable=False,
        default=ParentStatus.pending,
    )

    __table_args__ = (
        Index("uk_parent_user_id", "user_id", unique=True),
    )


class ParentChildRelation(UUIDMixin, Base):
    """Relationship between parent and student (child)."""

    __tablename__ = "parent_child_relations"

    parent_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    permission: Mapped[ParentPermission] = mapped_column(
        Enum(ParentPermission, native_enum=True),
        nullable=False,
        default=ParentPermission.viewOnly,
    )
    connected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("uk_parent_child", "parent_id", "student_id", unique=True),
    )


class ParentTeacherConnection(UUIDMixin, Base):
    """Connection between parent and teacher (via a student)."""

    __tablename__ = "parent_teacher_connections"

    parent_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    permission: Mapped[ParentPermission] = mapped_column(
        Enum(ParentPermission, native_enum=True),
        nullable=False,
        default=ParentPermission.viewOnly,
    )
    connected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("uk_parent_teacher", "parent_id", "teacher_id", unique=True),
        Index("idx_ptc_teacher", "teacher_id"),
    )
