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
