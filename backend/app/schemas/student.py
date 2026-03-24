"""Student-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict


class StudentResponse(BaseModel):
    """Student representation returned from the API."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
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
    notes: str | None = None
    is_active: bool = True
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class StudentCreate(BaseModel):
    """Payload to create a new student."""

    name: str
    instrument: str | None = None
    level: str = "beginner"
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
    birth_date: _dt.date | None = None
    age_group: str | None = None
    notes: str | None = None


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
    birth_date: _dt.date | None = None
    age_group: str | None = None
    connection_status: str | None = None
    practice_level: str | None = None
    break_reason: str | None = None
    expected_return_date: _dt.date | None = None
    notes: str | None = None
    is_active: bool | None = None


class StudentStatsResponse(BaseModel):
    """Aggregated statistics for a student."""

    model_config = ConfigDict(from_attributes=True)

    total_lessons: int = 0
    completed_lessons: int = 0
    attendance_rate: float = 0.0
    practice_streak: int = 0
    total_practice_minutes: int = 0
    repertoire_count: int = 0
