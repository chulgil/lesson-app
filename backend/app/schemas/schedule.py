"""Schedule and booking schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict


# ---------------------------------------------------------------------------
# Availability
# ---------------------------------------------------------------------------

class TimeSlotSchema(BaseModel):
    """A single time slot within a day."""

    start_time: str
    end_time: str


class DayAvailability(BaseModel):
    """Availability for a specific day of week."""

    day_of_week: int  # 0=Mon … 6=Sun
    time_slots: list[TimeSlotSchema] = []


class AvailabilityResponse(BaseModel):
    """Teacher's weekly availability."""

    model_config = ConfigDict(from_attributes=True)

    teacher_id: str
    availabilities: list[DayAvailability] = []


class AvailabilityCreate(BaseModel):
    """Set / replace weekly availability."""

    availabilities: list[DayAvailability]


# ---------------------------------------------------------------------------
# Schedule slots (read-only, computed)
# ---------------------------------------------------------------------------

class SlotStatus(BaseModel):
    """A single bookable slot."""

    start_time: str
    end_time: str
    status: str  # "available" | "booked"


class SlotsResponse(BaseModel):
    """Available slots for a given _dt.date."""

    date: _dt.date
    slots: list[SlotStatus] = []


# ---------------------------------------------------------------------------
# Weekly schedule (availability + bookings merged)
# ---------------------------------------------------------------------------

class WeeklyScheduleResponse(BaseModel):
    """Combined weekly schedule for a teacher."""

    model_config = ConfigDict(from_attributes=True)

    week_start: _dt.date
    days: dict  # day_of_week -> list of events


# ---------------------------------------------------------------------------
# Schedule exceptions
# ---------------------------------------------------------------------------

class ScheduleExceptionCreate(BaseModel):
    """Create a schedule exception (holiday, extra opening)."""

    date: _dt.date
    type: str  # "holiday" | "extra"
    reason: str | None = None


class ScheduleExceptionUpdate(BaseModel):
    """Update a schedule exception."""

    date: _dt.date | None = None
    type: str | None = None
    reason: str | None = None


class ScheduleExceptionResponse(BaseModel):
    """Schedule exception record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    date: _dt.date
    type: str
    reason: str | None = None
    created_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Bookings
# ---------------------------------------------------------------------------

class BookingResponse(BaseModel):
    """Lesson booking representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str | None = None
    user_id: str | None = None
    lesson_type: str | None = None
    scheduled_date: _dt.date | None = None
    scheduled_time: str | None = None
    duration: int | None = None
    instrument: str | None = None
    notes: str | None = None
    status: str | None = None
    reason: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class BookingCreate(BaseModel):
    """Request a new booking."""

    teacher_id: str
    lesson_type: str | None = None
    scheduled_date: _dt.date
    scheduled_time: str
    duration: int = 60
    instrument: str | None = None
    notes: str | None = None


class BookingRejectRequest(BaseModel):
    """Reject a booking."""

    reason: str | None = None


class BookingCancelRequest(BaseModel):
    """Cancel a booking."""

    reason: str | None = None


class BookingChangeRequest(BaseModel):
    """Request to change a booking's _dt.date/time."""

    new_date: _dt.date
    new_time: str
    reason: str | None = None


class MakeupBookingCreate(BaseModel):
    """Create a makeup lesson booking."""

    student_id: str
    original_lesson_id: str | None = None
    scheduled_date: _dt.date
    scheduled_time: str
    reason: str | None = None
