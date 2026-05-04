"""Practice log schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class PracticeTaskSchema(BaseModel):
    """A single task within a practice log."""

    id: str | None = None
    title: str
    description: str | None = None
    target_minutes: int = 0
    is_completed: bool = False
    completed_at: _dt.datetime | None = None
    piece_id: str | None = None


class PracticeLogResponse(BaseModel):
    """Daily practice log."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    date: _dt.date
    total_minutes: int
    tasks: list[PracticeTaskSchema] = []
    notes: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class PracticeLogCreate(BaseModel):
    """Create a practice log."""

    student_id: str | None = None
    date: _dt.date
    total_minutes: int = 0
    tasks: list[PracticeTaskSchema] = []
    notes: str | None = None


class PracticeLogUpdate(BaseModel):
    """Update a practice log."""

    total_minutes: int | None = None
    tasks: list[PracticeTaskSchema] | None = None
    notes: str | None = None


class PracticeStatsResponse(BaseModel):
    """Monthly practice statistics."""

    year: int
    month: int
    total_days: int
    practiced_days: int
    total_minutes: int
    average_minutes_per_day: float
