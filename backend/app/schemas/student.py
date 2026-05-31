"""Student-related schemas."""

import datetime as _dt
from typing import Any

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, computed_field, model_validator


class StudentResponse(BaseModel):
    """Student representation returned from the API."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str | None = None
    user_id: str | None = None
    name: str
    instrument: str | None = None
    level: str | None = None
    status: str | None = None
    phone: str | None = None
    parent_phone: str | None = None
    parent_name: str | None = None
    email: str | None = None
    lesson_class_id: str | None = None
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int = 60
    profile_image_url: str | None = None
    background_image_url: str | None = None
    profile_color: str | None = None
    birth_date: _dt.date | None = None
    age_group: str | None = None
    connection_status: str | None = None
    connected_at: _dt.datetime | None = None
    practice_level: str | None = None
    break_reason: str | None = None
    expected_return_date: _dt.date | None = None
    postal_code: str | None = None
    address: str | None = None
    address_detail: str | None = None
    district: str | None = None
    notes: str | None = None
    is_active: bool = True
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None

    @computed_field
    @property
    def is_archived(self) -> bool:
        """Frontend archive flag backed by inactive enrollment status."""
        return self.status == "inactive"

    @computed_field
    @property
    def archived_at(self) -> _dt.datetime | None:
        """Archive timestamp fallback for frontend compatibility."""
        return self.updated_at if self.is_archived else None

    @computed_field
    @property
    def manual_age_group(self) -> str | None:
        """Frontend field name for manually selected age group."""
        return self.age_group


class StudentCreate(BaseModel):
    """Payload to create a new student."""

    name: str
    instrument: str | None = None
    level: str = "beginner"
    status: str | None = None
    phone: str | None = None
    parent_phone: str | None = None
    parent_name: str | None = None
    email: str | None = None
    lesson_class_id: str | None = None
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int = 60
    profile_image_url: str | None = None
    background_image_url: str | None = None
    birth_date: _dt.date | None = None
    age_group: str | None = Field(
        default=None,
        validation_alias=AliasChoices("age_group", "manual_age_group"),
    )
    connection_status: str | None = None
    practice_level: str | None = None
    break_reason: str | None = None
    expected_return_date: _dt.date | None = None
    postal_code: str | None = None
    address: str | None = None
    address_detail: str | None = None
    district: str | None = None
    notes: str | None = None

    @model_validator(mode="before")
    @classmethod
    def normalize_frontend_aliases(cls, values: Any) -> Any:
        if isinstance(values, dict) and values.get("manual_age_group") is not None:
            values = {**values, "age_group": values["manual_age_group"]}
        return values


class StudentUpdate(BaseModel):
    """Fields that can be updated on a student."""

    name: str | None = None
    instrument: str | None = None
    level: str | None = None
    status: str | None = None
    phone: str | None = None
    parent_phone: str | None = None
    parent_name: str | None = None
    email: str | None = None
    lesson_class_id: str | None = None
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int | None = None
    profile_image_url: str | None = None
    background_image_url: str | None = None
    birth_date: _dt.date | None = None
    age_group: str | None = Field(
        default=None,
        validation_alias=AliasChoices("age_group", "manual_age_group"),
    )
    connection_status: str | None = None
    practice_level: str | None = None
    break_reason: str | None = None
    expected_return_date: _dt.date | None = None
    postal_code: str | None = None
    address: str | None = None
    address_detail: str | None = None
    district: str | None = None
    notes: str | None = None
    is_active: bool | None = None

    @model_validator(mode="before")
    @classmethod
    def normalize_frontend_aliases(cls, values: Any) -> Any:
        if isinstance(values, dict) and values.get("manual_age_group") is not None:
            values = {**values, "age_group": values["manual_age_group"]}
        return values


class StudentStatsResponse(BaseModel):
    """Aggregated statistics for a student."""

    model_config = ConfigDict(from_attributes=True)

    total_lessons: int = 0
    completed_lessons: int = 0
    attendance_rate: float = 0.0
    practice_streak: int = 0
    total_practice_minutes: int = 0
    repertoire_count: int = 0


class StudentSummaryResponse(BaseModel):
    """Summary statistics for a teacher's students."""

    total_count: int = 0
    active_count: int = 0
    by_instrument: dict[str, int] = {}
