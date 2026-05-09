"""Public web landing schemas consumed by the Ghost theme."""

from __future__ import annotations

import datetime as _dt
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PublicTeacherSummary(BaseModel):
    """Minimal public teacher identity for invite and summary pages."""

    id: str
    name: str | None = None
    instrument: str | None = None
    profile_image_url: str | None = None


class PublicShareMeta(BaseModel):
    """Share metadata for web URL, app deep link, and Open Graph content."""

    title: str
    description: str
    url: str
    app_deep_link: str


class PublicInviteLandingResponse(BaseModel):
    """Public invite landing response."""

    model_config = ConfigDict(from_attributes=True)

    code: str
    status: str
    teacher: PublicTeacherSummary
    share: PublicShareMeta
    expires_at: datetime


class PublicLessonSummaryLesson(BaseModel):
    """Minimal public lesson metadata."""

    id: str
    date: _dt.date
    start_time: str
    duration_minutes: int
    session_number: int | None = None
    status: str


class PublicStudentSummaryIdentity(BaseModel):
    """Minimal public student identity."""

    name: str | None = None


class PublicLessonSummaryTeacher(BaseModel):
    """Minimal teacher identity for token-protected lesson summaries."""

    name: str | None = None
    instrument: str | None = None
    profile_image_url: str | None = None


class PublicLessonSummaryContent(BaseModel):
    """Read-only lesson summary content exposed through a share token."""

    title: str
    lesson_note: str | None = None
    homework: str | None = None
    next_lesson_at: datetime | None = None


class PublicStudentSummaryResponse(BaseModel):
    """Public student lesson summary response."""

    lesson: PublicLessonSummaryLesson
    teacher: PublicLessonSummaryTeacher
    student: PublicStudentSummaryIdentity
    summary: PublicLessonSummaryContent
    share: PublicShareMeta
