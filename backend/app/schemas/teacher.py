"""Teacher-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

from app.schemas.lesson import LessonResponse
from app.schemas.user import UserResponse


# ---------------------------------------------------------------------------
# Nested schemas for teacher sub-entities
# ---------------------------------------------------------------------------


class TeacherEducationResponse(BaseModel):
    """Teacher education entry."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    school: str
    major: str | None = None
    degree: str | None = None
    graduation_year: int | None = None
    sort_order: int = 0


class TeacherCareerResponse(BaseModel):
    """Teacher career entry."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    organization: str
    position: str | None = None
    start_year: int
    end_year: int | None = None
    description: str | None = None
    sort_order: int = 0


class TeacherCertificateResponse(BaseModel):
    """Teacher certificate entry."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    type: str
    name: str
    issuing_body: str | None = None
    issue_date: _dt.datetime | None = None
    certificate_number: str | None = None
    image_url: str | None = None
    status: str = "pending"
    rejection_reason: str | None = None
    submitted_at: _dt.datetime | None = None
    reviewed_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Main teacher schemas
# ---------------------------------------------------------------------------


class TeacherResponse(BaseModel):
    """Teacher profile response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    user: UserResponse | None = None
    instruments: list[str] = []
    introduction: str | None = None
    experience_years: int | None = None
    lesson_areas: list[str] | None = []
    lesson_types: list[str] | None = []
    fee_min: int | None = None
    fee_max: int | None = None
    fee_duration: int | None = 60
    teaching_style: str | None = None
    specialties: list[str] | None = []
    portfolio_video_urls: list[str] | None = []

    # Images
    background_image: str | None = None

    # Banking info
    bank_name: str | None = None
    account_number: str | None = None
    account_holder: str | None = None
    bank_accounts: list[dict] | None = None

    # Phone verification
    is_phone_verified: bool = False
    phone_number: str | None = None
    phone_verified_at: _dt.datetime | None = None

    # Visibility settings
    visibility_settings: dict | None = None

    # Sub-entities (populated via service layer)
    education: list[TeacherEducationResponse] = []
    career: list[TeacherCareerResponse] = []
    certificates: list[TeacherCertificateResponse] = []

    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class TeacherUpdate(BaseModel):
    """Fields a teacher can update on their profile."""

    instruments: list[str] | None = None
    introduction: str | None = None
    experience_years: int | None = None
    lesson_areas: list[str] | None = None
    lesson_types: list[str] | None = None
    fee_min: int | None = None
    fee_max: int | None = None
    fee_duration: int | None = None
    teaching_style: str | None = None
    specialties: list[str] | None = None
    portfolio_video_urls: list[str] | None = None

    # Banking info
    bank_name: str | None = None
    account_number: str | None = None
    account_holder: str | None = None
    bank_accounts: list[dict] | None = None

    # Phone verification
    is_phone_verified: bool | None = None
    phone_number: str | None = None

    # Visibility settings
    visibility_settings: dict | None = None


class TeacherDashboardResponse(BaseModel):
    """Aggregated dashboard data for a teacher."""

    model_config = ConfigDict(from_attributes=True)

    total_students: int = 0
    active_students: int = 0
    today_lessons: int = 0
    week_lessons: int = 0
    unpaid_count: int = 0
    upcoming_lessons: list[LessonResponse] = []
