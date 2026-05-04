"""Schedule confirmation card schemas."""

import datetime as _dt
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ScheduleConfirmationCardCreate(BaseModel):
    """Create a schedule confirmation card from teacher to student."""

    student_id: str
    subscription_id: str | None = None
    lesson_request_id: str | None = None
    card_type: str = "afterTrial"
    instrument: str | None = None
    title: str = Field(max_length=200)
    message: str | None = None
    proposed_day: str | None = Field(default=None, max_length=10)
    proposed_time: str | None = Field(default=None, max_length=5)
    proposed_duration: int | None = Field(default=None, ge=15, le=180)
    proposed_slots: list[dict[str, Any]] | None = None
    total_lessons: int | None = None
    expires_at: _dt.datetime | None = None


class ScheduleConfirmationCardResponse(BaseModel):
    """Schedule confirmation card representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    subscription_id: str | None = None
    lesson_request_id: str | None = None
    card_type: str = "afterTrial"
    instrument: str | None = None
    title: str
    message: str | None = None
    status: str
    proposed_day: str | None = None
    proposed_time: str | None = None
    proposed_duration: int | None = None
    proposed_slots: list[dict[str, Any]] | None = None
    total_lessons: int | None = None
    response_message: str | None = None
    responded_at: _dt.datetime | None = None
    expires_at: _dt.datetime | None = None
    created_at: _dt.datetime


class ScheduleConfirmationCardConfirm(BaseModel):
    """Student confirms or rejects a schedule confirmation card."""

    action: str = Field(pattern="^(confirmed|changedTime|rejected|dismissed)$")
    response_message: str | None = Field(default=None, max_length=500)
