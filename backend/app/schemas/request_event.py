"""Pydantic schemas for RequestEvent (Plan A Phase 1).

Mirrors frontend `RequestEvent.toJson()` / `fromJson()` shape.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.request_event import RequestEventType, ScheduleChangeType


class TimeSlotOptionSchema(BaseModel):
    """Time slot option proposed within an event."""

    start_time: str
    end_time: str
    is_selected: bool = False
    date: datetime | None = None


class RequestEventCreate(BaseModel):
    """Payload for POST /lesson-requests/{id}/events."""

    request_id: str
    actor_type: str
    actor_id: str
    event_type: RequestEventType
    suggested_slots: list[TimeSlotOptionSchema] = []
    selected_slot_index: int | None = None
    message: str | None = None
    schedule_change_type: ScheduleChangeType | None = None
    proposed_day_of_week: int | None = None
    proposed_time: str | None = None
    subscription_id: str | None = None
    session_number: int | None = None


class RequestEventResponse(BaseModel):
    """Response shape for events list / single fetch."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    request_id: str
    actor_type: str
    actor_id: str
    event_type: RequestEventType
    suggested_slots: list[TimeSlotOptionSchema] | None = None
    selected_slot_index: int | None = None
    message: str | None = None
    schedule_change_type: ScheduleChangeType | None = None
    proposed_day_of_week: int | None = None
    proposed_time: str | None = None
    subscription_id: str | None = None
    session_number: int | None = None
    created_at: datetime
    updated_at: datetime
