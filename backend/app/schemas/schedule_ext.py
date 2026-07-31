"""Extended schedule schemas (exceptions, group schedules, no-show, changes)."""

import datetime as _dt
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, field_validator, model_validator

GroupClassTypeLiteral = Literal["regular", "dropIn"]
# #239 SSOT 4값 — 1:1 과 그룹이 같은 정책 enum 을 공유한다.
NoShowPolicyLiteral = Literal["deductCredit", "halfCredit", "noDeduction", "reschedule"]

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
    teacher_id: str | None = None
    teacher_availability_id: str | None = None
    type: str
    start_date: _dt.date
    end_date: _dt.date
    start_time: str | None = None
    end_time: str | None = None
    reason: str | None = None
    created_at: _dt.datetime


# ---------------------------------------------------------------------------
# Group Class (definition)
#
# Wire keys mirror the FE entity `features/schedule/domain/entities/group_class.dart`
# one-for-one. ``repeat_days_of_week`` / ``repeat_time_of_day`` are the consumer
# contract; the ORM columns behind them are ``repeat_days`` / ``repeat_time``.
# ---------------------------------------------------------------------------


def _validate_repeat_days(value: list[int] | None) -> list[int] | None:
    """1=Mon … 7=Sun (FE contract). Reject anything outside that range."""
    if value is None:
        return None
    for day in value:
        if day < 1 or day > 7:
            raise ValueError("repeat_days_of_week must be between 1 (Mon) and 7 (Sun)")
    return sorted(set(value))


def _validate_repeat_time(value: str | None) -> str | None:
    """ "HH:MM" 24h wall clock (KST)."""
    if value is None:
        return None
    try:
        _dt.time.fromisoformat(value)
    except ValueError as exc:
        raise ValueError("repeat_time_of_day must be HH:MM") from exc
    return value


class GroupClassCreate(BaseModel):
    name: str
    type: GroupClassTypeLiteral = "regular"
    description: str | None = None
    organization_id: str | None = None
    max_capacity: int = 10
    waitlist_capacity: int | None = None
    duration_minutes: int = 60
    booking_deadline_minutes: int = 60
    cancel_deadline_minutes: int = 1440
    no_show_policy: NoShowPolicyLiteral = "deductCredit"
    max_no_show_count: int | None = None
    repeat_days_of_week: list[int] | None = None
    repeat_time_of_day: str | None = None
    instrument: str | None = None
    price_per_session: int | None = None
    # 반복 회차 생성의 기준일. 저장하지 않고 생성에만 쓴다 (생략 시 오늘, KST).
    start_date: _dt.date | None = None

    _check_days = field_validator("repeat_days_of_week")(_validate_repeat_days)
    _check_time = field_validator("repeat_time_of_day")(_validate_repeat_time)


class GroupClassUpdate(BaseModel):
    name: str | None = None
    type: GroupClassTypeLiteral | None = None
    description: str | None = None
    max_capacity: int | None = None
    waitlist_capacity: int | None = None
    duration_minutes: int | None = None
    booking_deadline_minutes: int | None = None
    cancel_deadline_minutes: int | None = None
    no_show_policy: NoShowPolicyLiteral | None = None
    max_no_show_count: int | None = None
    repeat_days_of_week: list[int] | None = None
    repeat_time_of_day: str | None = None
    instrument: str | None = None
    price_per_session: int | None = None
    is_active: bool | None = None

    _check_days = field_validator("repeat_days_of_week")(_validate_repeat_days)
    _check_time = field_validator("repeat_time_of_day")(_validate_repeat_time)


class GroupClassResponse(BaseModel):
    id: str
    teacher_id: str
    organization_id: str | None = None
    name: str
    description: str | None = None
    type: str
    max_capacity: int
    waitlist_capacity: int | None = None
    duration_minutes: int
    booking_deadline_minutes: int
    cancel_deadline_minutes: int
    no_show_policy: str
    max_no_show_count: int | None = None
    repeat_days_of_week: list[int] | None = None
    repeat_time_of_day: str | None = None
    instrument: str | None = None
    price_per_session: int | None = None
    is_active: bool
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Group Class Schedule
# ---------------------------------------------------------------------------


class GroupClassScheduleCreate(BaseModel):
    group_class_id: str
    start_time: _dt.datetime
    end_time: _dt.datetime
    # None 이면 GroupClass 의 정원을 상속 (정원 SSOT). 회차별 예외만 명시.
    max_capacity: int | None = None
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
