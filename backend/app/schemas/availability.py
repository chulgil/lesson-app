"""Teacher availability schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


def _parse_slot_minute(time_value: str) -> int:
    """Parse HH:MM string and return minute-of-day."""
    parts = time_value.split(":")
    if len(parts) != 2:
        raise ValueError("time must be HH:MM")
    hour = int(parts[0])
    minute = int(parts[1])
    if not (0 <= hour <= 23 and 0 <= minute <= 59):
        raise ValueError("invalid HH:MM value")
    return hour * 60 + minute


# ---------------------------------------------------------------------------
# Time Slots
# ---------------------------------------------------------------------------


class TimeSlotCreate(BaseModel):
    start_time: str = Field(pattern=r"^\d{2}:\d{2}$")  # HH:MM
    end_time: str = Field(pattern=r"^\d{2}:\d{2}$")  # HH:MM
    is_available: bool = True

    @field_validator("start_time", "end_time")
    @classmethod
    def validate_hhmm(cls, value: str) -> str:
        """Reject malformed times up front."""
        _parse_slot_minute(value)
        return value

    @model_validator(mode="after")
    def validate_range(self) -> "TimeSlotCreate":
        """Reject slot where end_time is not after start_time."""
        if _parse_slot_minute(self.start_time) >= _parse_slot_minute(self.end_time):
            raise ValueError("end_time must be after start_time")
        return self


class TimeSlotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    start_time: str
    end_time: str
    is_available: bool


# ---------------------------------------------------------------------------
# Teacher Availability
# ---------------------------------------------------------------------------


class TeacherAvailabilityCreate(BaseModel):
    day_of_week: int  # 0=Mon … 6=Sun
    time_slots: list[TimeSlotCreate] = []

    @field_validator("day_of_week")
    @classmethod
    def validate_day_of_week(cls, value: int) -> int:
        if value < 0 or value > 6:
            raise ValueError("day_of_week must be 0..6")
        return value

    @model_validator(mode="after")
    def validate_no_overlap(self) -> "TeacherAvailabilityCreate":
        slots = sorted(
            (_parse_slot_minute(slot.start_time), _parse_slot_minute(slot.end_time)) for slot in self.time_slots
        )
        for previous, current in zip(slots, slots[1:]):
            if previous[1] > current[0]:
                raise ValueError("time_slots for a day must not overlap")
        return self


class TeacherAvailabilityUpdate(BaseModel):
    day_of_week: int | None = None
    time_slots: list[TimeSlotCreate] | None = None

    @field_validator("day_of_week")
    @classmethod
    def validate_day_of_week(cls, value: int | None) -> int | None:
        if value is None:
            return value
        if value < 0 or value > 6:
            raise ValueError("day_of_week must be 0..6")
        return value

    @model_validator(mode="after")
    def validate_no_overlap(self) -> "TeacherAvailabilityUpdate":
        if self.time_slots is None or len(self.time_slots) <= 1:
            return self
        slots = sorted(
            (_parse_slot_minute(slot.start_time), _parse_slot_minute(slot.end_time))
            for slot in self.time_slots
        )
        for previous, current in zip(slots, slots[1:]):
            if previous[1] > current[0]:
                raise ValueError("time_slots for a day must not overlap")
        return self


class TeacherAvailabilityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    day_of_week: int
    time_slots: list[TimeSlotResponse] = []
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None
