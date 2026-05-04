"""Lesson booking schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class LessonBookingResponse(BaseModel):
    """Lesson booking representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str
    lesson_type: str | None = None
    scheduled_date: _dt.date
    scheduled_time: str
    duration: int = 60
    instrument: str | None = None
    location_id: str | None = None
    status: str | None = None
    notes: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class LessonBookingCreate(BaseModel):
    """Create a lesson booking."""

    teacher_id: str
    student_id: str
    lesson_type: str = "regular"
    scheduled_date: _dt.date
    scheduled_time: str
    duration: int = 60
    instrument: str | None = None
    location_id: str | None = None
    notes: str | None = None


class LessonBookingUpdate(BaseModel):
    """Update a lesson booking."""

    scheduled_date: _dt.date | None = None
    scheduled_time: str | None = None
    duration: int | None = None
    status: str | None = None
    notes: str | None = None
