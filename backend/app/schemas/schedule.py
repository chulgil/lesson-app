"""Schedule and booking schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, model_validator

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
    """Teacher's weekly availability with settings."""

    model_config = ConfigDict(from_attributes=True)

    teacher_id: str
    availabilities: list[DayAvailability] = []
    # Settings (stored in TeacherSettings, returned for convenience)
    slot_duration_minutes: int = 30
    break_time_between_lessons: int = 10
    min_booking_hours: int = 24
    auto_generate_weeks: int = 4
    slot_start_interval: int = 30


class AvailabilityCreate(BaseModel):
    """Set / replace weekly availability.

    Accepts both:
    - Backend format: {availabilities: [{day_of_week, time_slots}]}
    - Frontend format: {weekly_schedules: [{day_of_week, start_time, end_time}], ...}
    """

    availabilities: list[DayAvailability] = []
    # Frontend fields (converted to availabilities if provided)
    weekly_schedules: list[dict] | None = None
    slot_duration_minutes: int | None = None
    break_time_between_lessons: int | None = None
    min_booking_hours: int | None = None
    auto_generate_weeks: int | None = None
    slot_start_interval: int | None = None

    @model_validator(mode="after")
    def convert_weekly_schedules(self) -> "AvailabilityCreate":
        """Convert frontend weekly_schedules to backend availabilities format."""
        if self.weekly_schedules and not self.availabilities:
            converted = []
            for ws in self.weekly_schedules:
                day = ws.get("day_of_week", ws.get("dayOfWeek", 0))
                start = ws.get("start_time", ws.get("startTime", "09:00"))
                end = ws.get("end_time", ws.get("endTime", "18:00"))
                converted.append(
                    DayAvailability(
                        day_of_week=day,
                        time_slots=[TimeSlotSchema(start_time=start, end_time=end)],
                    )
                )
            self.availabilities = converted
        return self


# ---------------------------------------------------------------------------
# Schedule slots (read-only, computed)
# ---------------------------------------------------------------------------


class SlotStatus(BaseModel):
    """A single bookable slot."""

    start_time: str
    end_time: str
    status: str  # "available" | "booked"
    is_recommended: bool = False


class SlotsResponse(BaseModel):
    """Available slots for a given date."""

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
    """Create a schedule exception.

    Accepts both:
    - Simple format: {date, type, reason}
    - Rich format: {start_date, end_date, start_time, end_time, type, reason}
    """

    # Rich format (frontend)
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    start_time: str | None = None
    end_time: str | None = None
    type: str  # "holiday" | "vacation" | "additionalSlot"
    reason: str | None = None

    # Simple format (backward compatible)
    date: _dt.date | None = None

    @model_validator(mode="after")
    def normalize_dates(self) -> "ScheduleExceptionCreate":
        """If only 'date' is provided, use it as both start_date and end_date."""
        if self.date and not self.start_date:
            self.start_date = self.date
            self.end_date = self.date
        if self.start_date and not self.end_date:
            self.end_date = self.start_date
        return self


class ScheduleExceptionUpdate(BaseModel):
    """Update a schedule exception."""

    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    start_time: str | None = None
    end_time: str | None = None
    type: str | None = None
    reason: str | None = None


class ScheduleExceptionResponse(BaseModel):
    """Schedule exception record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_availability_id: str | None = None
    start_date: _dt.date
    end_date: _dt.date
    start_time: str | None = None
    end_time: str | None = None
    type: str
    reason: str | None = None
    created_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Bookings
# ---------------------------------------------------------------------------


class BookingResponse(BaseModel):
    """Lesson booking representation.

    Provides both backend field names and frontend aliases for compatibility.
    """

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str | None = None
    lesson_type: str | None = None
    scheduled_date: _dt.date | None = None
    scheduled_time: str | None = None
    duration: int | None = None
    instrument: str | None = None
    location_id: str | None = None
    notes: str | None = None
    status: str | None = None
    reason: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None

    # Frontend-compatible aliases (computed from backend fields)
    @property
    def lesson_date(self) -> _dt.date | None:
        return self.scheduled_date

    @property
    def start_time(self) -> str | None:
        return self.scheduled_time

    def model_post_init(self, __context: object) -> None:
        """Map status values for frontend compatibility — Plan B (#238): SSOT 'confirmed'."""
        pass


class BookingCreate(BaseModel):
    """Request a new booking.

    Accepts both backend (scheduled_date/scheduled_time) and
    frontend (lesson_date/start_time) field names.
    """

    teacher_id: str
    lesson_type: str | None = None

    # Accept both naming conventions
    scheduled_date: _dt.date | None = None
    scheduled_time: str | None = None
    lesson_date: _dt.date | None = None
    start_time: str | None = None

    duration: int = 60
    instrument: str | None = None
    location_id: str | None = None
    notes: str | None = None

    # Frontend-specific fields (stored in notes or ignored)
    student_name: str | None = None
    student_phone: str | None = None
    lesson_goal: str | None = None
    experience_level: str | None = None
    fee: int | None = None

    @model_validator(mode="after")
    def normalize_fields(self) -> "BookingCreate":
        """Accept both frontend and backend field names."""
        if self.lesson_date and not self.scheduled_date:
            self.scheduled_date = self.lesson_date
        if self.start_time and not self.scheduled_time:
            self.scheduled_time = self.start_time
        return self


class BookingRejectRequest(BaseModel):
    """Reject a booking."""

    reason: str | None = None


class BookingCancelRequest(BaseModel):
    """Cancel a booking."""

    reason: str | None = None


class BookingChangeRequest(BaseModel):
    """Request to change a booking's date/time."""

    new_date: _dt.date
    new_time: str
    reason: str | None = None


class MakeupBookingCreate(BaseModel):
    """Create a makeup lesson booking."""

    student_id: str
    original_lesson_id: str | None = None
    scheduled_date: _dt.date
    scheduled_time: str
    duration: int = 60
    instrument: str | None = None
    reason: str | None = None
