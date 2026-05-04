"""Lesson request schemas — unified lesson request (trial + regular + returning)."""

import datetime as _dt
from typing import Literal

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, computed_field


class LessonRequestCreate(BaseModel):
    """Create a unified lesson request from student to teacher."""

    model_config = ConfigDict(populate_by_name=True)

    teacher_id: str = Field(validation_alias=AliasChoices("teacher_id", "teacherId"))
    # Unified fields
    request_type: Literal["trial", "regular", "package"] | None = Field(
        default=None,
        validation_alias=AliasChoices("request_type", "type"),
    )
    instrument: str | None = Field(default=None, max_length=50)
    goal: Literal["hobby", "exam", "major", "other"] | None = None
    experience_level: Literal["beginner", "intermediate", "advanced"] | None = Field(
        default=None,
        validation_alias=AliasChoices("experience_level", "experience"),
    )
    preferred_day: int | None = Field(
        default=None,
        ge=0,
        le=6,
        validation_alias=AliasChoices("preferred_day", "preferredDay"),
    )  # 0=Mon...6=Sun
    preferred_time: str | None = Field(
        default=None,
        max_length=5,
        validation_alias=AliasChoices("preferred_time", "preferredTime"),
    )  # HH:MM
    preferred_duration: int | None = Field(
        default=None,
        ge=15,
        le=180,
        validation_alias=AliasChoices("preferred_duration", "preferredDuration"),
    )  # minutes
    preferred_slots: list["PreferredTimeSlotSchema"] = Field(
        default_factory=list,
        max_length=3,
        validation_alias=AliasChoices("preferred_slots", "preferredSlots"),
    )
    message: str | None = Field(default=None, max_length=500)
    is_returning_student: bool = Field(
        default=False,
        validation_alias=AliasChoices("is_returning_student", "isReturningStudent"),
    )
    # Legacy fields (backward compatibility)
    preferred_timing: str = "afterConsultation"  # nextWeek, nextMonth, afterConsultation
    keep_previous_schedule: bool = False
    previous_lesson_day: int | None = None  # 0=Mon … 6=Sun
    previous_lesson_time: str | None = None  # HH:MM
    previous_lesson_duration: int | None = None  # minutes


class LessonRequestUpdate(BaseModel):
    """Update a lesson request."""

    message: str | None = None
    preferred_timing: str | None = None
    keep_previous_schedule: bool | None = None
    preferred_day: int | None = None
    preferred_time: str | None = None
    preferred_duration: int | None = None
    preferred_slots: list["PreferredTimeSlotSchema"] | None = None


class LessonRequestResponse(BaseModel):
    """Lesson request representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    # Unified fields
    request_type: str | None = None
    type: str | None = None
    instrument: str | None = None
    goal: str | None = None
    experience_level: str | None = None
    experience: str | None = None
    preferred_day: int | None = None
    preferred_time: str | None = None
    preferred_duration: int | None = None
    preferred_slots: list["PreferredTimeSlotSchema"] = Field(default_factory=list)
    is_returning_student: bool = False
    time_proposals: list | dict | None = None
    current_round: int = 0
    suggested_price: int | None = None
    message: str | None = None
    # Legacy fields
    preferred_timing: str | None = None
    keep_previous_schedule: bool = False
    previous_lesson_day: int | None = None
    previous_lesson_time: str | None = None
    previous_lesson_duration: int | None = None
    # Status
    status: str = "pending"
    expires_at: _dt.datetime | None = None
    proposal_id: str | None = None
    decline_reason: str | None = None
    academy_id: str | None = None
    status_updated_at: _dt.datetime | None = None
    confirmed_at: _dt.datetime | None = None
    cancelled_at: _dt.datetime | None = None
    created_at: _dt.datetime | None = None
    events: list["RequestEventResponse"] = Field(default_factory=list)

    @computed_field
    @property
    def proposals(self) -> list[dict]:
        """Frontend TimeProposal list derived from stored time_proposals."""
        normalized: list[dict] = []
        for proposal_index, raw_proposal in enumerate(self.time_proposals or []):
            if not isinstance(raw_proposal, dict):
                continue
            proposal_id = raw_proposal.get("id") or f"{self.id}-proposal-{proposal_index}"
            slots = []
            for slot_index, raw_slot in enumerate(raw_proposal.get("slots") or []):
                if not isinstance(raw_slot, dict):
                    continue
                slot_id = raw_slot.get("id") or f"{proposal_id}-slot-{slot_index}"
                slots.append(
                    {
                        **raw_slot,
                        "id": slot_id,
                        "is_selected": raw_slot.get("is_selected", False),
                    }
                )
            normalized.append(
                {
                    **raw_proposal,
                    "id": proposal_id,
                    "slots": slots,
                }
            )
        return normalized


class RequestEventResponse(BaseModel):
    """Chat-history event for a lesson request."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    request_id: str
    actor_type: str
    actor_id: str
    event_type: str
    suggested_slots: list | None = Field(default_factory=list)
    selected_slot_index: int | None = None
    message: str | None = None
    created_at: _dt.datetime
    schedule_change_type: str | None = None
    proposed_day_of_week: int | None = None
    proposed_time: str | None = None
    subscription_id: str | None = None
    session_number: int | None = None
    change_credit_used: int | None = None
    change_credit_remaining_after: int | None = None
    keeps_session_number: bool | None = None


class LessonRequestCalendarItem(BaseModel):
    """Aggregated request count for a preferred day."""

    day_of_week: int
    count: int


class LessonRequestCalendarResponse(BaseModel):
    """Calendar markers for accessible lesson requests."""

    items: list[LessonRequestCalendarItem]


class LessonRequestStatusUpdate(BaseModel):
    """Change lesson request status."""

    status: Literal[
        "pending", "approved", "rejected", "negotiating", "timeConfirmed",
        "proposalSent", "proposalAccepted", "paymentNotified",
        "subscriptionIssued", "inProgress", "completed", "cancelled", "expired",
    ]
    decline_reason: str | None = Field(default=None, max_length=500)
    proposal_id: str | None = None


class TimeSlotOptionSchema(BaseModel):
    """A single time slot option within a proposal."""

    model_config = ConfigDict(populate_by_name=True)

    day_of_week: int = Field(validation_alias=AliasChoices("day_of_week", "dayOfWeek"))  # 0=Mon...6=Sun
    start_time: str = Field(validation_alias=AliasChoices("start_time", "startTime"))  # HH:MM
    end_time: str = Field(validation_alias=AliasChoices("end_time", "endTime"))  # HH:MM


class PreferredTimeSlotSchema(BaseModel):
    """Student preferred time slot with priority order."""

    model_config = ConfigDict(populate_by_name=True)

    priority: int = Field(ge=1, le=3)
    date: str | None = None
    day_of_week: int | None = Field(
        default=None,
        ge=0,
        le=6,
        validation_alias=AliasChoices("day_of_week", "dayOfWeek"),
    )
    start_time: str = Field(validation_alias=AliasChoices("start_time", "startTime"))
    end_time: str = Field(validation_alias=AliasChoices("end_time", "endTime"))


class TimeProposalCreate(BaseModel):
    """Create a time proposal (teacher proposes alternatives or student counter-proposes)."""

    slots: list[TimeSlotOptionSchema] = Field(min_length=1, max_length=3)
    message: str | None = Field(default=None, max_length=500)


class AlternativeAccept(BaseModel):
    """Student accepts one of the teacher's proposed alternatives."""

    model_config = ConfigDict(populate_by_name=True)

    selected_slot_index: int = Field(
        ge=0,
        le=2,
        validation_alias=AliasChoices("selected_slot_index", "selectedSlotIndex"),
    )  # 0-based, max 3 slots
    message: str | None = Field(default=None, max_length=500)


class LessonRequestAction(BaseModel):
    """Unified action endpoint payload for lesson request lifecycle."""

    model_config = ConfigDict(populate_by_name=True)

    action: Literal[
        "approve",
        "reject",
        "proposeAlternative",
        "acceptAlternative",
        "counterPropose",
        "cancel",
    ]
    slots: list[TimeSlotOptionSchema] | None = Field(
        default=None,
        max_length=3,
        validation_alias=AliasChoices("slots", "suggestedSlots"),
    )
    selected_slot_index: int | None = Field(
        default=None,
        ge=0,
        le=2,
        validation_alias=AliasChoices("selected_slot_index", "selectedSlotIndex"),
    )
    message: str | None = Field(default=None, max_length=500)
    decline_reason: str | None = Field(
        default=None,
        max_length=500,
        validation_alias=AliasChoices("decline_reason", "declineReason"),
    )
