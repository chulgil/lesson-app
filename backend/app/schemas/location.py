"""Lesson location schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class LocationResponse(BaseModel):
    """Lesson location returned from the API."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_class_id: str | None = None
    owner_id: str | None = None
    name: str
    type: str
    address: str | None = None
    address_detail: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    online_platform: str | None = None
    online_link: str | None = None
    notes: str | None = None
    is_default: bool = False
    is_active: bool = True
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class LocationCreate(BaseModel):
    """Payload to create a lesson location."""

    lesson_class_id: str | None = None
    name: str
    type: str = "teacherStudio"
    address: str | None = None
    address_detail: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    online_platform: str | None = None
    online_link: str | None = None
    notes: str | None = None
    is_default: bool = False


class LocationUpdate(BaseModel):
    """Fields that can be updated on a location."""

    name: str | None = None
    type: str | None = None
    address: str | None = None
    address_detail: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    online_platform: str | None = None
    online_link: str | None = None
    notes: str | None = None
    is_default: bool | None = None
