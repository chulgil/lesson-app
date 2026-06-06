"""Academy announcement API schemas — AC-M3.

Spec: docs/specs/web/academy/announcements_spec.md §2-§3.
"""

from __future__ import annotations

import datetime as _dt
import enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class AcademyAnnouncementAudience(str, enum.Enum):
    all = "all"
    teachers = "teachers"
    parents = "parents"
    students = "students"
    teacher_students = "teacher_students"


class AcademyAnnouncementStatus(str, enum.Enum):
    draft = "draft"
    scheduled = "scheduled"
    sending = "sending"
    sent = "sent"
    cancelled = "cancelled"


class AcademyAnnouncementChannel(str, enum.Enum):
    inapp = "inapp"
    kakao = "kakao"


class AcademyAnnouncementCreate(BaseModel):
    """학원장 단방향 공지 작성 (draft 으로 시작).

    audience=teacher_students 이면 audience_filter 에
    ``{"teacher_member_id": "..."}`` 형태로 대상 강사 지정.
    """

    title: str = Field(..., min_length=1, max_length=200)
    body_markdown: str = Field(..., min_length=1)
    audience: AcademyAnnouncementAudience
    audience_filter: dict[str, Any] | None = None
    channels: list[AcademyAnnouncementChannel] = Field(default_factory=lambda: [AcademyAnnouncementChannel.inapp])
    kakao_template_id: str | None = Field(None, max_length=100)
    scheduled_at: _dt.datetime | None = None


class AcademyAnnouncementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    author_user_id: str
    title: str
    body_markdown: str
    audience: AcademyAnnouncementAudience
    audience_filter: dict[str, Any] | None = None
    channels: list[str] = Field(default_factory=list)
    kakao_template_id: str | None = None
    scheduled_at: _dt.datetime | None = None
    sent_at: _dt.datetime | None = None
    status: AcademyAnnouncementStatus
    target_count: int = 0
    delivered_count: int = 0
    read_count: int = 0
    # Per-recipient read flag for the requesting user (recipient row read_at set).
    # Defaults False; aggregate read_count stays separate for the owner view.
    read_by_me: bool = False
    created_at: _dt.datetime


class AcademyAnnouncementListResponse(BaseModel):
    announcements: list[AcademyAnnouncementResponse] = Field(default_factory=list)
    total_count: int


class AudienceCountByRole(BaseModel):
    teacher: int = 0
    parent: int = 0
    student: int = 0


class AcademyAnnouncementAudiencePreviewResponse(BaseModel):
    """공지 작성 화면 미리보기 — spec §3.1 "대상 수: 124명 (강사 8, 학부모 87, 학생 29)"."""

    target_count: int
    by_role: AudienceCountByRole


class AcademyAnnouncementStatsRoleBreakdown(BaseModel):
    """역할별 target/read/rate — spec §7."""

    target: int = 0
    read: int = 0
    rate: float = 0.0


class AcademyAnnouncementUnreadUserItem(BaseModel):
    """미열람 수신자 1명 — 학원장 1:1 재발송 후보."""

    user_id: str
    name: str
    role: str  # teacher / parent / student


class AcademyAnnouncementStatsResponse(BaseModel):
    """발송 공지 통계 — spec §7. 학원장 전용."""

    target_count: int = 0
    delivered_count: int = 0
    read_count: int = 0
    read_rate: float = 0.0
    by_role: dict[str, AcademyAnnouncementStatsRoleBreakdown] = Field(default_factory=dict)
    unread_users: list[AcademyAnnouncementUnreadUserItem] = Field(default_factory=list)
