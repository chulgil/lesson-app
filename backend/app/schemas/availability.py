"""Teacher availability schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


# ---------------------------------------------------------------------------
# Time Slots
# ---------------------------------------------------------------------------


class TimeSlotCreate(BaseModel):
    start_time: str  # HH:MM
    end_time: str  # HH:MM
    is_available: bool = True


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


class TeacherAvailabilityUpdate(BaseModel):
    day_of_week: int | None = None
    time_slots: list[TimeSlotCreate] | None = None


class TeacherAvailabilityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    day_of_week: int
    time_slots: list[TimeSlotResponse] = []
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None
