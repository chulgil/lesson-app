"""Teacher announcement persistence models."""

from __future__ import annotations

import enum
from datetime import date

from sqlalchemy import Date, Enum, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class TeacherAnnouncementType(str, enum.Enum):
    """선생님 공지 타입."""

    day_off = "dayOff"
    general = "general"


class TeacherAnnouncement(UUIDMixin, TimestampMixin, Base):
    """공지 헤더 엔티티."""

    __tablename__ = "teacher_announcements"

    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id"), nullable=False)
    type: Mapped[TeacherAnnouncementType] = mapped_column(
        Enum(TeacherAnnouncementType, native_enum=True),
        nullable=False,
    )
    message: Mapped[str] = mapped_column(Text, nullable=False)
    notified_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    __table_args__ = (
        Index("idx_teacher_announcements_teacher_created", "teacher_id", "created_at"),
        Index("idx_teacher_announcements_type", "teacher_id", "type"),
    )


class TeacherAnnouncementDate(UUIDMixin, Base):
    """휴강일(announcement-date) 정규화 조인 테이블."""

    __tablename__ = "teacher_announcement_dates"

    teacher_announcement_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("teacher_announcements.id"),
        nullable=False,
    )
    announcement_date: Mapped[date] = mapped_column(Date, nullable=False)

    __table_args__ = (
        Index("idx_teacher_announcement_dates_announcement", "teacher_announcement_id"),
        Index("idx_teacher_announcement_dates_teacher", "announcement_date"),
        # 동일 공지 내 동일 날짜 중복 저장 방지
        Index(
            "uq_teacher_announcement_dates_per_announcement_date",
            "teacher_announcement_id",
            "announcement_date",
            unique=True,
        ),
    )
