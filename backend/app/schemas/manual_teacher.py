"""Manual teacher schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class ManualTeacherResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    instrument: str | None = None
    phone: str | None = None
    notes: str | None = None
    created_at: _dt.datetime
    profile_color_value: int | None = None


class ManualTeacherCreate(BaseModel):
    id: str | None = None
    name: str
    instrument: str | None = None
    phone: str | None = None
    notes: str | None = None
    created_at: _dt.datetime | None = None
    profile_color_value: int | None = None


class ManualTeacherUpdate(BaseModel):
    name: str | None = None
    instrument: str | None = None
    phone: str | None = None
    notes: str | None = None
    profile_color_value: int | None = None
