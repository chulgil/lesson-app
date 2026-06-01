import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class InviteStatus(str, enum.Enum):
    active = "active"
    used = "used"
    expired = "expired"
    revoked = "revoked"


class InviteUserRole(str, enum.Enum):
    teacher = "teacher"
    student = "student"


class InviteMethod(str, enum.Enum):
    qrCode = "qrCode"
    urlLink = "urlLink"
    inviteCode = "inviteCode"
    inAppSearch = "inAppSearch"


class ConnectionRequestStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    cancelled = "cancelled"
    expired = "expired"


class Invite(UUIDMixin, Base):
    """Invite code for teacher-student or teacher-parent connection."""

    __tablename__ = "invites"

    creator_id: Mapped[str] = mapped_column(String(36), nullable=False)
    creator_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    creator_role: Mapped[InviteUserRole] = mapped_column(
        Enum(InviteUserRole, native_enum=True),
        nullable=False,
    )
    invite_code: Mapped[str] = mapped_column(String(10), nullable=False, unique=True)
    invite_url: Mapped[str] = mapped_column(Text, nullable=False)
    qr_code_data: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[InviteStatus] = mapped_column(
        Enum(InviteStatus, native_enum=True),
        nullable=False,
        default=InviteStatus.active,
    )
    is_single_use: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    max_uses: Mapped[int | None] = mapped_column(Integer, nullable=True)
    use_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    # #5 D-G3 — 재발송 추적: count + 마지막 발송 시각 (10분 쿨다운 + 운영 메트릭)
    resent_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_resent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_invite_creator", "creator_id"),
        Index("idx_invite_status", "status"),
    )


class ConnectionRequest(UUIDMixin, Base):
    """Request to connect teacher and student."""

    __tablename__ = "connection_requests"

    requester_id: Mapped[str] = mapped_column(String(36), nullable=False)
    requester_role: Mapped[InviteUserRole] = mapped_column(
        Enum(InviteUserRole, native_enum=True),
        nullable=False,
    )
    requester_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    requester_profile_image: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_id: Mapped[str] = mapped_column(String(36), nullable=False)
    target_role: Mapped[InviteUserRole] = mapped_column(
        Enum(InviteUserRole, native_enum=True),
        nullable=False,
    )
    target_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    target_profile_image: Mapped[str | None] = mapped_column(Text, nullable=True)
    method: Mapped[InviteMethod] = mapped_column(
        Enum(InviteMethod, native_enum=True),
        nullable=False,
    )
    invite_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[ConnectionRequestStatus] = mapped_column(
        Enum(ConnectionRequestStatus, native_enum=True),
        nullable=False,
        default=ConnectionRequestStatus.pending,
    )
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_connreq_requester", "requester_id"),
        Index("idx_connreq_target", "target_id"),
        Index("idx_connreq_status", "status"),
    )


class Connection(UUIDMixin, Base):
    """Established connection between teacher and student."""

    __tablename__ = "connections"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    teacher_name: Mapped[str] = mapped_column(String(100), nullable=False)
    teacher_profile_image: Mapped[str | None] = mapped_column(Text, nullable=True)
    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    student_name: Mapped[str] = mapped_column(String(100), nullable=False)
    student_profile_image: Mapped[str | None] = mapped_column(Text, nullable=True)
    connection_request_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    deactivated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    connected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_connection", "teacher_id", "student_id", unique=True),
        Index("idx_connection_active", "is_active"),
    )
