from datetime import datetime
from enum import StrEnum

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ParentStatus(StrEnum):
    pending = "pending"
    active = "active"
    inactive = "inactive"


class ParentPermission(StrEnum):
    viewOnly = "viewOnly"  # noqa: N815
    managePayments = "managePayments"  # noqa: N815
    manageLessons = "manageLessons"  # noqa: N815
    fullAccess = "fullAccess"  # noqa: N815


class ParentChildRelationStatus(StrEnum):
    pending = "pending"
    active = "active"
    inactive = "inactive"


class ParentInvitationSource(StrEnum):
    student = "student"
    teacher = "teacher"


class Parent(UUIDMixin, TimestampMixin, Base):
    """Parent profile linked to a user account."""

    __tablename__ = "parents"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
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
    is_primary_guardian: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_billing_target: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    status: Mapped[ParentChildRelationStatus] = mapped_column(
        Enum(ParentChildRelationStatus, native_enum=True),
        nullable=False,
        default=ParentChildRelationStatus.active,
    )
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
    unlinked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("uk_parent_child", "parent_id", "student_id", unique=True),
    )


class ParentInvitation(UUIDMixin, Base):
    """Invitation for linking a parent to a student."""

    __tablename__ = "parent_invitations"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    source: Mapped[ParentInvitationSource] = mapped_column(
        Enum(ParentInvitationSource, native_enum=True),
        nullable=False,
    )
    parent_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    parent_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    invitation_code: Mapped[str] = mapped_column(String(20), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_parent_invitation_code", "invitation_code", unique=True),
        Index("idx_parent_invitation_student", "student_id"),
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


class ParentVisibilitySettings(UUIDMixin, TimestampMixin, Base):
    """Teacher-controlled parent visibility settings for a student."""

    __tablename__ = "parent_visibility_settings"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    can_view_schedule: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_view_assignments: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_view_practice: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_view_lesson_notes: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_view_recordings: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    can_view_detailed_feedback: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    can_view_chat: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index("uk_parent_visibility_teacher_student", "teacher_id", "student_id", unique=True),
        Index("idx_parent_visibility_student", "student_id"),
    )
