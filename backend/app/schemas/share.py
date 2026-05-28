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
