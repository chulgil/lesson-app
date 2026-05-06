"""Schedule confirmation card schemas."""

import datetime as _dt
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, computed_field


class ScheduleConfirmationCardCreate(BaseModel):
    """Create a schedule confirmation card from teacher to student."""

    student_id: str
    subscription_id: str | None = None
    lesson_request_id: str | None = None
    card_type: str = "afterTrial"
    instrument: str | None = None
    title: str = Field(max_length=200)
    message: str | None = None
    proposed_day: str | None = Field(default=None, max_length=10)
    proposed_time: str | None = Field(default=None, max_length=5)
    proposed_duration: int | None = Field(default=None, ge=15, le=180)
    proposed_slots: list[dict[str, Any]] | None = None
    total_lessons: int | None = None
    expires_at: _dt.datetime | None = None


class ScheduleConfirmationCardResponse(BaseModel):
    """Schedule confirmation card representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    teacher_name: str = ""
    subscription_id: str | None = None
    lesson_request_id: str | None = None
    card_type: str = "afterTrial"
    instrument: str | None = None
    title: str
    message: str | None = None
    status: str
    proposed_day: str | None = None
    proposed_time: str | None = None
    proposed_duration: int | None = None
    proposed_slots: list[dict[str, Any]] | None = None
    total_lessons: int | None = None
    response_message: str | None = None
    responded_at: _dt.datetime | None = None
    expires_at: _dt.datetime | None = None
    created_at: _dt.datetime

    @computed_field(alias="suggestedDay")
    @property
    def suggested_day(self) -> int | None:
        """Flutter card field alias for the primary suggested day."""
        if self.proposed_slots:
            slot_day = self.proposed_slots[0].get("day")
            return int(slot_day) if slot_day is not None else None
        return int(self.proposed_day) if self.proposed_day is not None else None

    @computed_field(alias="suggestedTime")
    @property
    def suggested_time(self) -> str | None:
        """Flutter card field alias for the primary suggested time."""
        if self.proposed_slots:
            slot_time = self.proposed_slots[0].get("time")
            return str(slot_time) if slot_time is not None else None
        return self.proposed_time

    @computed_field(alias="lessonDuration")
    @property
    def lesson_duration(self) -> int | None:
        """Flutter card field alias for proposed lesson duration."""
        return self.proposed_duration

    @computed_field(alias="suggested_day")
    @property
    def suggested_day_snake(self) -> int | None:
        """Flutter generated JSON field for the primary suggested day."""
        return self.suggested_day

    @computed_field(alias="suggested_time")
    @property
    def suggested_time_snake(self) -> str | None:
        """Flutter generated JSON field for the primary suggested time."""
        return self.suggested_time

    @computed_field(alias="lesson_duration")
    @property
    def lesson_duration_snake(self) -> int | None:
        """Flutter generated JSON field for proposed lesson duration."""
        return self.lesson_duration

    @computed_field(alias="suggestedDay2")
    @property
    def suggested_day2(self) -> int | None:
        """Flutter card field alias for the second suggested day."""
        return self._slot_day(1)

    @computed_field(alias="suggestedTime2")
    @property
    def suggested_time2(self) -> str | None:
        """Flutter card field alias for the second suggested time."""
        return self._slot_time(1)

    @computed_field(alias="suggested_day2")
    @property
    def suggested_day2_snake(self) -> int | None:
        """Flutter generated JSON field for the second suggested day."""
        return self.suggested_day2

    @computed_field(alias="suggested_time2")
    @property
    def suggested_time2_snake(self) -> str | None:
        """Flutter generated JSON field for the second suggested time."""
        return self.suggested_time2

    @computed_field(alias="suggestedDay3")
    @property
    def suggested_day3(self) -> int | None:
        """Flutter card field alias for the third suggested day."""
        return self._slot_day(2)

    @computed_field(alias="suggestedTime3")
    @property
    def suggested_time3(self) -> str | None:
        """Flutter card field alias for the third suggested time."""
        return self._slot_time(2)

    @computed_field(alias="suggested_day3")
    @property
    def suggested_day3_snake(self) -> int | None:
        """Flutter generated JSON field for the third suggested day."""
        return self.suggested_day3

    @computed_field(alias="suggested_time3")
    @property
    def suggested_time3_snake(self) -> str | None:
        """Flutter generated JSON field for the third suggested time."""
        return self.suggested_time3

    def _slot_day(self, index: int) -> int | None:
        if not self.proposed_slots or len(self.proposed_slots) <= index:
            return None
        day = self.proposed_slots[index].get("day")
        return int(day) if day is not None else None

    def _slot_time(self, index: int) -> str | None:
        if not self.proposed_slots or len(self.proposed_slots) <= index:
            return None
        time = self.proposed_slots[index].get("time")
        return str(time) if time is not None else None


class ScheduleConfirmationCardConfirm(BaseModel):
    """Student confirms or rejects a schedule confirmation card."""

    action: str = Field(pattern="^(confirmed|changedTime|rejected|dismissed)$")
    response_message: str | None = Field(default=None, max_length=500)


class ScheduleConfirmationCardStatusUpdate(BaseModel):
    """Update card status from Flutter repository actions."""

    status: str = Field(pattern="^(confirmed|changedTime|rejected|dismissed)$")
    responded_at: _dt.datetime | None = None
    response_message: str | None = Field(default=None, max_length=500)


class ScheduleConfirmationCardDismissAll(BaseModel):
    """Dismiss all pending cards for a student."""

    student_id: str


class ScheduleConfirmationCardDismissAllResponse(BaseModel):
    """Dismiss-all mutation result."""

    success: bool = True
    message: str
