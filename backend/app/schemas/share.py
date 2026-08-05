"""Schemas for public sharing endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class LessonSummaryItem(BaseModel):
    """Summary of a single lesson for public sharing."""

    date: str = Field(..., description="Lesson date in YYYY-MM-DD format")
    status: str = Field(..., description="Lesson status (e.g., completed, scheduled)")
    duration_minutes: int = Field(..., description="Lesson duration in minutes")
    notes_excerpt: str = Field(..., description="Brief excerpt from lesson notes")


class StudentSummaryResponse(BaseModel):
    """Response containing student summary for public access."""

    student_name: str = Field(..., description="Student display name (initials masked)")
    instrument: str = Field(..., description="Instrument name")
    level: str = Field(..., description="Student level")
    lesson_count_total: int = Field(..., description="Total number of lessons")
    recent_lessons: list[LessonSummaryItem] = Field(
        ...,
        description="Recent completed lessons (up to 10)",
    )
    generated_at: datetime = Field(..., description="Timestamp of response generation")


class LessonSummaryShareRequest(BaseModel):
    """Request to issue a lesson summary share token."""

    expires_in_hours: int = Field(24, ge=1, le=24 * 30)


class LessonSummaryShareResponse(BaseModel):
    """Response returned after issuing a lesson summary share token."""

    token: str
    url: str
    app_deep_link: str
    expires_at: datetime
    share_text: str


class PublicLessonSummaryLesson(BaseModel):
    """Public lesson summary lesson payload."""

    id: str
    date: str
    start_time: str
    duration_minutes: int
    session_number: int | None = None


class PublicLessonSummaryTeacher(BaseModel):
    """Public lesson summary teacher payload."""

    name: str | None = None


class PublicLessonSummaryStudent(BaseModel):
    """Public lesson summary student payload."""

    name: str
    instrument: str


class PublicLessonSummaryBody(BaseModel):
    """Public lesson summary content."""

    feedback: str | None = None
    student_note: str | None = None
    practice_tips: str | None = None
    key_points: dict | list | None = None


class PublicLessonSummaryResponse(BaseModel):
    """Token-gated public lesson summary response."""

    lesson: PublicLessonSummaryLesson
    teacher: PublicLessonSummaryTeacher
    student: PublicLessonSummaryStudent
    summary: PublicLessonSummaryBody
    generated_at: datetime


class GrowthReportShareRequest(BaseModel):
    """Request to issue a child growth-report share token (#1217)."""

    expires_in_hours: int = Field(24, ge=1, le=24 * 30)


class GrowthReportShareResponse(BaseModel):
    """Response returned after issuing a growth-report share token (#1217)."""

    token: str
    url: str
    app_deep_link: str
    expires_at: datetime


class PublicGrowthReportChild(BaseModel):
    """Minimal, non-identifying child info for a public growth report.

    Data minimality (#1217): given name only (no full legal name, no
    contact info, no address) — this is minor data on a no-auth endpoint.
    """

    given_name: str = Field(..., description="Child given name only (surname stripped)")
    instrument: str


class PublicGrowthReportMetrics(BaseModel):
    """Read-only growth metrics — no detailed lesson notes, no PII."""

    practice_streak_days: int = Field(..., description="Current consecutive practice-day streak")
    recent_lesson_count: int = Field(..., description="Completed lessons in the last 30 days")
    progress_summary: str = Field(..., description="Short generated progress sentence")


class PublicGrowthReportResponse(BaseModel):
    """Token-gated, read-only public child growth report (#1217, minor-safe).

    Excludes contact/address/payment fields and detailed lesson notes by
    construction — see :class:`PublicGrowthReportChild` and
    :class:`PublicGrowthReportMetrics`.
    """

    child: PublicGrowthReportChild
    metrics: PublicGrowthReportMetrics
    generated_at: datetime
