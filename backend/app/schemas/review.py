"""Teacher review schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field


class TeacherReviewResponse(BaseModel):
    """Teacher review record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    teacher_name: str
    student_id: str
    student_name: str
    author_type: str
    author_id: str
    author_name: str
    rating: int
    content: str | None = None
    tags: list[str] = []
    visibility: str
    is_anonymous: bool
    is_verified: bool
    is_active: bool
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class TeacherReviewCreate(BaseModel):
    """Create a teacher review."""

    teacher_id: str
    rating: int = Field(ge=1, le=5)
    content: str | None = None
    tags: list[str] = []
    visibility: str = "public"
    is_anonymous: bool = False


class TeacherReviewUpdate(BaseModel):
    """Update a teacher review."""

    rating: int | None = Field(default=None, ge=1, le=5)
    content: str | None = None
    tags: list[str] | None = None
    visibility: str | None = None


class TeacherReviewSummary(BaseModel):
    """Aggregated review stats for a teacher."""

    teacher_id: str
    average_rating: float
    total_reviews: int
    student_reviews: int
    parent_reviews: int
    rating_distribution: dict[int, int] = {}
