"""Teacher-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

from app.schemas.lesson import LessonResponse
from app.schemas.user import UserResponse


class TeacherResponse(BaseModel):
    """Teacher profile response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    user: UserResponse | None = None
    instruments: list[str] = []
    introduction: str | None = None
    experience_years: int | None = None
    lesson_types: list[str] = []
    fee_min: int | None = None
    fee_max: int | None = None
    teaching_style: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class TeacherUpdate(BaseModel):
    """Fields a teacher can update on their profile."""

    instruments: list[str] | None = None
    introduction: str | None = None
    experience_years: int | None = None
    lesson_types: list[str] | None = None
    fee_min: int | None = None
    fee_max: int | None = None
    teaching_style: str | None = None


class TeacherDashboardResponse(BaseModel):
    """Aggregated dashboard data for a teacher."""

    model_config = ConfigDict(from_attributes=True)

    total_students: int = 0
    active_students: int = 0
    today_lessons: int = 0
    week_lessons: int = 0
    unpaid_count: int = 0
    upcoming_lessons: list[LessonResponse] = []
