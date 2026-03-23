"""Lesson request schemas — student requests to reconnect with a teacher."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class LessonRequestCreate(BaseModel):
    """Create a lesson request from student to teacher."""

    teacher_id: str
    message: str | None = None
    preferred_timing: str = "afterConsultation"  # nextWeek, nextMonth, afterConsultation
    keep_previous_schedule: bool = False
    previous_lesson_day: int | None = None  # 0=Mon … 6=Sun
    previous_lesson_time: str | None = None  # HH:MM
    previous_lesson_duration: int | None = None  # minutes


class LessonRequestUpdate(BaseModel):
    """Update a lesson request."""

    message: str | None = None
    preferred_timing: str | None = None
    keep_previous_schedule: bool | None = None


class LessonRequestResponse(BaseModel):
    """Lesson request representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    message: str | None = None
    preferred_timing: str | None = None
    keep_previous_schedule: bool = False
    previous_lesson_day: int | None = None
    previous_lesson_time: str | None = None
    previous_lesson_duration: int | None = None
    status: str = "pending"  # pending, proposalSent, accepted, declined, expired, cancelled
    expires_at: _dt.datetime | None = None
    proposal_id: str | None = None
    decline_reason: str | None = None
    status_updated_at: _dt.datetime | None = None
    created_at: _dt.datetime | None = None


class LessonRequestStatusUpdate(BaseModel):
    """Change lesson request status."""

    status: str  # proposalSent, accepted, declined, cancelled
    decline_reason: str | None = None
    proposal_id: str | None = None
