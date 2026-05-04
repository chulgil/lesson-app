"""Extended schedule schemas (exceptions, group schedules, no-show, changes)."""

import datetime as _dt
from typing import Any

from pydantic import BaseModel, ConfigDict, model_validator

# ---------------------------------------------------------------------------
# Schedule Exceptions
# ---------------------------------------------------------------------------

class ScheduleExceptionCreate(BaseModel):
    type: str  # holiday, vacation, additionalSlot
    start_date: _dt.date
    end_date: _dt.date
    start_time: str | None = None
    end_time: str | None = None
    reason: str | None = None


class ScheduleExceptionUpdate(BaseModel):
    type: str | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    start_time: str | None = None
    end_time: str | None = None
    reason: str | None = None


class ScheduleExceptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_availability_id: str
    type: str
    start_date: _dt.date
    end_date: _dt.date
    start_time: str | None = None
    end_time: str | None = None
    reason: str | None = None
    created_at: _dt.datetime


# ---------------------------------------------------------------------------
# Group Class Schedule
# ---------------------------------------------------------------------------

class GroupClassScheduleCreate(BaseModel):
    group_class_id: str
    start_time: _dt.datetime
    end_time: _dt.datetime
    max_capacity: int
    waitlist_capacity: int | None = None
    notes: str | None = None


class GroupClassScheduleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    group_class_id: str
    start_time: _dt.datetime
    end_time: _dt.datetime
    status: str
    current_bookings: int
    waitlist_count: int
    max_capacity: int
    waitlist_capacity: int | None = None
    notes: str | None = None
    cancel_reason: str | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Group Class Booking
# ---------------------------------------------------------------------------

class GroupClassBookingCreate(BaseModel):
    schedule_id: str
    student_id: str
    subscription_id: str | None = None


class GroupClassBookingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    schedule_id: str
    student_id: str
    subscription_id: str | None = None
    status: str
    waitlist_position: int | None = None
    attended_at: _dt.datetime | None = None
    subscription_deducted: bool
    cancel_reason: str | None = None
    cancelled_at: _dt.datetime | None = None
    promoted_at: _dt.datetime | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class AttendanceMarkRequest(BaseModel):
    attended: bool = True


class BatchAttendanceRequest(BaseModel):
    bookings: list[dict[str, Any]] = []  # [{booking_id: str, attended: bool}]
    attendance: list[dict[str, Any]] | None = None

    @model_validator(mode="after")
    def normalize_frontend_payload(self) -> "BatchAttendanceRequest":
        """Accept frontend key 'attendance' as the batch list."""
        if self.attendance is not None and not self.bookings:
            self.bookings = self.attendance
        return self


class GroupBookingActionRequest(BaseModel):
    schedule_id: str


# ---------------------------------------------------------------------------
# No-Show Records
# ---------------------------------------------------------------------------

class NoShowRecordCreate(BaseModel):
    lesson_id: str
    student_id: str
    lesson_date: _dt.date
    applied_policy: str  # deductCredit, halfCredit, noDeduction, reschedule
    deducted_credits: int = 0
    makeup_lesson_id: str | None = None
    note: str | None = None


class NoShowRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_id: str
    student_id: str
    teacher_id: str
    lesson_date: _dt.date
    applied_policy: str
    deducted_credits: int
    makeup_lesson_id: str | None = None
    note: str | None = None
    processed_by: str | None = None
    created_at: _dt.datetime


# ---------------------------------------------------------------------------
# Lesson Schedule Changes
# ---------------------------------------------------------------------------

class LessonScheduleChangeCreate(BaseModel):
    student_id: str
    change_type: str  # singleLesson, bulkChange
    previous_day_of_week: int | None = None
    previous_time: str | None = None
    new_day_of_week: int | None = None
    new_time: str | None = None
    effective_from: _dt.date
    request_reason: str | None = None


class LessonScheduleChangeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    change_type: str
    previous_day_of_week: int | None = None
    previous_time: str | None = None
    new_day_of_week: int | None = None
    new_time: str | None = None
    effective_from: _dt.date
    status: str
    requested_at: _dt.datetime
    processed_at: _dt.datetime | None = None
    request_reason: str | None = None
    response_message: str | None = None
    requested_by: str | None = None


class LessonScheduleChangeRespondRequest(BaseModel):
    action: str  # approved, rejected, alternativeProposed
    response_message: str | None = None
    alternative_day: int | None = None
    alternative_time: str | None = None
