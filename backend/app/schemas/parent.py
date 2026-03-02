"""Parent-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

from app.schemas.student import StudentResponse


class ParentResponse(BaseModel):
    """Parent profile."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: str | None = None
    phone: str | None = None
    created_at: _dt.datetime | None = None


class ParentUpdate(BaseModel):
    """Update parent profile."""

    name: str | None = None
    phone: str | None = None


class ParentChildResponse(BaseModel):
    """A child linked to a parent."""

    model_config = ConfigDict(from_attributes=True)

    student: StudentResponse
    linked_at: _dt.datetime | None = None


class ParentConnectChildRequest(BaseModel):
    """Link a child via invite code."""

    invite_code: str
