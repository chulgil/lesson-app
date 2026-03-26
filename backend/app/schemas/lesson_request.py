"""Lesson request schemas — unified lesson request (trial + regular + returning)."""

import datetime as _dt
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class LessonRequestCreate(BaseModel):
    """Create a unified lesson request from student to teacher."""

    teacher_id: str
    # Unified fields
    request_type: Literal["trial", "regular"] | None = None
    instrument: str | None = Field(default=None, max_length=50)
    goal: Literal["hobby", "exam", "major", "other"] | None = None
    experience_level: Literal["beginner", "intermediate", "advanced"] | None = None
    preferred_day: int | None = Field(default=None, ge=0, le=6)  # 0=Mon...6=Sun
    preferred_time: str | None = Field(default=None, max_length=5)  # HH:MM
    preferred_duration: int | None = Field(default=None, ge=15, le=180)  # minutes
    message: str | None = Field(default=None, max_length=500)
    is_returning_student: bool = False
    # Legacy fields (backward compatibility)
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
    preferred_day: int | None = None
    preferred_time: str | None = None
    preferred_duration: int | None = None


class LessonRequestResponse(BaseModel):
    """Lesson request representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    # Unified fields
    request_type: str | None = None
    instrument: str | None = None
    goal: str | None = None
    experience_level: str | None = None
    preferred_day: int | None = None
    preferred_time: str | None = None
    preferred_duration: int | None = None
    is_returning_student: bool = False
    time_proposals: list | dict | None = None
    current_round: int = 0
    suggested_price: int | None = None
    message: str | None = None
    # Legacy fields
    preferred_timing: str | None = None
    keep_previous_schedule: bool = False
    previous_lesson_day: int | None = None
    previous_lesson_time: str | None = None
    previous_lesson_duration: int | None = None
    # Status
    status: str = "pending"
    expires_at: _dt.datetime | None = None
    proposal_id: str | None = None
    decline_reason: str | None = None
    status_updated_at: _dt.datetime | None = None
    confirmed_at: _dt.datetime | None = None
    cancelled_at: _dt.datetime | None = None
    created_at: _dt.datetime | None = None


class LessonRequestStatusUpdate(BaseModel):
    """Change lesson request status."""

    status: Literal[
        "approved", "rejected", "negotiating", "timeConfirmed",
        "proposalSent", "proposalAccepted", "paymentNotified",
        "completed", "cancelled", "expired",
    ]
    decline_reason: str | None = Field(default=None, max_length=500)
    proposal_id: str | None = None


class TimeSlotOptionSchema(BaseModel):
    """A single time slot option within a proposal."""

    day_of_week: int  # 0=Mon...6=Sun
    start_time: str  # HH:MM
    end_time: str  # HH:MM


class TimeProposalCreate(BaseModel):
    """Create a time proposal (teacher proposes alternatives or student counter-proposes)."""

    slots: list[TimeSlotOptionSchema] = Field(min_length=1, max_length=3)
    message: str | None = Field(default=None, max_length=500)


class AlternativeAccept(BaseModel):
    """Student accepts one of the teacher's proposed alternatives."""

    selected_slot_index: int = Field(ge=0, le=2)  # 0-based, max 3 slots
    message: str | None = Field(default=None, max_length=500)
