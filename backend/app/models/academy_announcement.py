"""Academy announcement persistence models — AC-M3.

Spec: docs/specs/web/academy/announcements_spec.md §2.

학원장(R-AO) 단방향 공지 — 전체/강사/학부모/학생/특정 강사 학생 단위 일괄 발송.
채널: lesson-app 인앱 + 카톡 알림톡 (사전 등록 템플릿만).
"""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class AcademyAnnouncementAudience(str, enum.Enum):
    """공지 대상 분기."""

    all = "all"  # 전체 (강사 + 학생 + 학부모)
    teachers = "teachers"
    parents = "parents"
    students = "students"
    teacher_students = "teacher_students"  # 특정 강사의 학생/학부모


class AcademyAnnouncementStatus(str, enum.Enum):
    """공지 상태 — draft → scheduled → sending → sent / cancelled."""

    draft = "draft"
    scheduled = "scheduled"
    sending = "sending"
    sent = "sent"
    cancelled = "cancelled"


class AcademyAnnouncementRecipientRole(str, enum.Enum):
    """수신자 역할 — 통계 분리용."""

    teacher = "teacher"
    parent = "parent"
    student = "student"


class AcademyAnnouncement(UUIDMixin, TimestampMixin, Base):
    """학원장 → 일괄 공지 (단방향). 작성 권한: 학원장 1인.

    audience 가 ``teacher_students`` 이면 ``audience_filter`` 에
    ``{"teacher_member_id": "..."}`` 형태로 대상 강사 지정.

    channels JSON 배열은 ``["inapp"]`` 또는 ``["inapp", "kakao"]``.
    카톡 알림톡은 사전 등록 ``kakao_template_id`` 필수 (커스텀 메시지는 인앱만).

    ``scheduled_at`` NULL = 즉시 발송, 값 있으면 예약 (AC-M5 보강).
    ``target_count`` 는 발송 시점에 대상 수 캡처 (snapshot — 사후 멤버십 변동 무관).
    """

    __tablename__ = "academy_announcements"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    author_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body_markdown: Mapped[str] = mapped_column(Text, nullable=False)
    audience: Mapped[AcademyAnnouncementAudience] = mapped_column(
        Enum(AcademyAnnouncementAudience, native_enum=True),
        nullable=False,
    )
    audience_filter: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    channels: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    kakao_template_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[AcademyAnnouncementStatus] = mapped_column(
        Enum(AcademyAnnouncementStatus, native_enum=True),
        nullable=False,
        default=AcademyAnnouncementStatus.draft,
    )
    target_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    delivered_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    read_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("idx_acad_ann_academy_created", "academy_id", "created_at"),
        Index("idx_acad_ann_academy_status", "academy_id", "status"),
        Index("idx_acad_ann_scheduled", "scheduled_at"),
    )


class AcademyAnnouncementRecipient(UUIDMixin, Base):
    """공지 1건 × 수신자 1명 = 1행. 읽음/배달 통계 + 채널별 상태 추적.

    UNIQUE (announcement_id, user_id) — 같은 user 에게 같은 공지 중복 발송 방지.
    """

    __tablename__ = "academy_announcement_recipients"

    announcement_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_announcements.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    role: Mapped[AcademyAnnouncementRecipientRole] = mapped_column(
        Enum(AcademyAnnouncementRecipientRole, native_enum=True),
        nullable=False,
    )
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    kakao_delivered: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    inapp_delivered: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index(
            "uq_acad_ann_recipient_per_user",
            "announcement_id",
            "user_id",
            unique=True,
        ),
        Index("idx_acad_ann_recipient_user_role", "user_id", "role"),
        Index("idx_acad_ann_recipient_read", "announcement_id", "read_at"),
    )


__all__ = [
    "AcademyAnnouncement",
    "AcademyAnnouncementAudience",
    "AcademyAnnouncementRecipient",
    "AcademyAnnouncementRecipientRole",
    "AcademyAnnouncementStatus",
]
