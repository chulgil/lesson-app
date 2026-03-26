"""Lesson request schemas — unified lesson request (trial + regular + returning)."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class LessonRequestCreate(BaseModel):
    """Create a unified lesson request from student to teacher."""

    teacher_id: str
    # Unified fields
    request_type: str | None = None  # trial, regular
    instrument: str | None = None
    goal: str | None = None  # hobby, exam, major, other
    experience_level: str | None = None  # beginner, intermediate, advanced
    preferred_day: int | None = None  # 0=Mon...6=Sun
    preferred_time: str | None = None  # HH:MM
    preferred_duration: int | None = None  # minutes
    message: str | None = None
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

    status: str  # approved, rejected, negotiating, timeConfirmed, proposalSent, etc.
    decline_reason: str | None = None
    proposal_id: str | None = None


class TimeSlotOptionSchema(BaseModel):
    """A single time slot option within a proposal."""

    day_of_week: int  # 0=Mon...6=Sun
    start_time: str  # HH:MM
    end_time: str  # HH:MM


class TimeProposalCreate(BaseModel):
    """Create a time proposal (teacher proposes alternatives or student counter-proposes)."""

    slots: list[TimeSlotOptionSchema]  # teacher: max 3, student: 1
    message: str | None = None


class AlternativeAccept(BaseModel):
    """Student accepts one of the teacher's proposed alternatives."""

    selected_slot_index: int  # 0-based index into the proposal's slots list
    message: str | None = None
