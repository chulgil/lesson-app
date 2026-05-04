"""Pydantic schemas for RequestEvent (Plan A Phase 1).

Mirrors frontend `RequestEvent.toJson()` / `fromJson()` shape.
"""

from datetime import datetime

from pydantic import AliasChoices, BaseModel, ConfigDict, Field

from app.models.request_event import RequestEventType, ScheduleChangeType


class TimeSlotOptionSchema(BaseModel):
    """Time slot option proposed within an event."""

    model_config = ConfigDict(populate_by_name=True)

    id: str | None = None
    day_of_week: int | None = Field(default=None, validation_alias=AliasChoices("day_of_week", "dayOfWeek"))
    start_time: str = Field(validation_alias=AliasChoices("start_time", "startTime"))
    end_time: str = Field(validation_alias=AliasChoices("end_time", "endTime"))
    is_selected: bool = False
    date: datetime | None = None


class RequestEventCreate(BaseModel):
    """Payload for POST /lesson-requests/{id}/events."""

    model_config = ConfigDict(populate_by_name=True)

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
    change_credit_used: int | None = Field(
        default=None,
        validation_alias=AliasChoices("change_credit_used", "changeCreditUsed"),
    )
    change_credit_remaining_after: int | None = Field(
        default=None,
        validation_alias=AliasChoices("change_credit_remaining_after", "changeCreditRemainingAfter"),
    )
    keeps_session_number: bool | None = Field(
        default=None,
        validation_alias=AliasChoices("keeps_session_number", "keepsSessionNumber"),
    )


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
    change_credit_used: int | None = None
    change_credit_remaining_after: int | None = None
    keeps_session_number: bool | None = None
    created_at: datetime
    updated_at: datetime | None = None
