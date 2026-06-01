from datetime import datetime
from enum import StrEnum
from typing import ClassVar

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class RelationStatus(StrEnum):
    pending = "pending"
    trialBooked = "trialBooked"  # noqa: N815
    active = "active"
    inactive = "inactive"
    expired = "expired"
    past = "past"
    disconnected = "disconnected"


class FollowTargetType(StrEnum):
    teacher = "teacher"
    academy = "academy"


class TeacherStudentRelation(UUIDMixin, Base):
    """Relationship between a teacher and student."""

    __tablename__ = "teacher_student_relations"

    teacher_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teachers.id", ondelete="RESTRICT"),
        nullable=False,
    )
    student_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    invite_code: Mapped[str | None] = mapped_column(String(10), nullable=True)
    status: Mapped[RelationStatus] = mapped_column(
        Enum(RelationStatus, native_enum=True),
        nullable=False,
        default=RelationStatus.pending,
    )
    # 입금 확인 직전 status 백업 — Undo 시 복원용 (#426). Undo 후엔 None 으로 클리어.
    previous_status: Mapped[RelationStatus | None] = mapped_column(
        Enum(RelationStatus, native_enum=True),
        nullable=True,
    )
    connected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    disconnected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Subscription tracking
    active_subscription_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    last_subscription_expired_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expired_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Trial tracking
    trial_booking_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    # Lesson tracking
    total_lesson_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_lesson_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Registration type
    is_manually_registered: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_app_connected: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    app_connected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Practice visibility permissions (CoachConnection-compatible)
    can_view_practice: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_comment: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_suggest_assignments: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # Schedule restoration
    last_lesson_day: Mapped[str | None] = mapped_column(String(10), nullable=True)
    last_lesson_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    last_lesson_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)
    schedule_recorded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Termination
    terminated_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    termination_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_relation_teacher_student", "teacher_id", "student_id", unique=True),
        Index("idx_relation_status", "status"),
    )


class Follow(UUIDMixin, Base):
    """User follow relationship (e.g., student follows teacher)."""

    __tablename__ = "follows"

    follower_id: Mapped[str] = mapped_column(String(36), nullable=False)
    following_id: Mapped[str] = mapped_column(String(36), nullable=False)

    # Non-column attribute, populated by service layer via User JOIN
    following_name: ClassVar[str | None] = None
    target_type: Mapped[FollowTargetType] = mapped_column(
        Enum(FollowTargetType, native_enum=True),
        nullable=False,
        default=FollowTargetType.teacher,
    )
    notification_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_follow", "follower_id", "following_id", unique=True),
        Index("idx_follow_following", "following_id"),
    )
