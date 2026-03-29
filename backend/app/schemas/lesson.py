"""Lesson and lesson-class schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


# ---------------------------------------------------------------------------
# Lesson class (group / academy)
# ---------------------------------------------------------------------------

class LessonClassResponse(BaseModel):
    """Lesson class (e.g. academy, private group)."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    name: str
    type: str | None = None
    payment_type: str | None = None
    contact_person: str | None = None
    contact_phone: str | None = None
    address: str | None = None
    sort_order: int = 0
    is_archived: bool = False
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class LessonClassCreate(BaseModel):
    """Create a lesson class."""

    name: str
    type: str | None = None
    payment_type: str | None = None
    contact_person: str | None = None
    contact_phone: str | None = None
    address: str | None = None


class LessonClassUpdate(BaseModel):
    """Update a lesson class."""

    name: str | None = None
    type: str | None = None
    payment_type: str | None = None
    contact_person: str | None = None
    contact_phone: str | None = None
    address: str | None = None


class MembershipCreate(BaseModel):
    """Add a student membership to a lesson class."""

    student_id: str
    instrument: str | None = None
    level: str | None = None
    status: str = "active"
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int = 60
    notes: str | None = None


class MembershipUpdate(BaseModel):
    """Update a membership."""

    instrument: str | None = None
    level: str | None = None
    status: str | None = None
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int | None = None
    notes: str | None = None


class MembershipResponse(BaseModel):
    """Class membership representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_class_id: str
    student_id: str
    instrument: str | None = None
    level: str | None = None
    status: str | None = None
    monthly_fee: int | None = None
    lessons_per_week: int | None = None
    lesson_day: str | None = None
    lesson_time: str | None = None
    lesson_duration: int = 60
    notes: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


# ---------------------------------------------------------------------------
# Lesson piece (embedded in lesson)
# ---------------------------------------------------------------------------

class LessonPieceCreate(BaseModel):
    """A musical piece covered in a lesson."""

    name: str
    composer: str | None = None
    movement: str | None = None


class LessonPieceResponse(BaseModel):
    """Piece within a lesson."""

    model_config = ConfigDict(from_attributes=True)

    name: str
    composer: str | None = None
    movement: str | None = None


# ---------------------------------------------------------------------------
# Lesson
# ---------------------------------------------------------------------------

class LessonResponse(BaseModel):
    """Full lesson representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    student_id: str
    student_name: str | None = None
    teacher_name: str | None = None
    instrument: str | None = None
    date: _dt.date | None = None
    start_time: str | None = None
    duration: int | None = None
    status: str | None = None
    pieces: list[LessonPieceResponse] | None = None
    feedback: str | None = None
    key_points: list[str] | None = None
    practice_tips: str | None = None
    location_name: str | None = None
    location_address: str | None = None
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class LessonCreate(BaseModel):
    """Payload to create a lesson."""

    student_id: str
    instrument: str | None = None
    date: _dt.date
    start_time: str | None = None
    duration: int = 60
    pieces: list[LessonPieceCreate] = []
    location_name: str | None = None


class LessonUpdate(BaseModel):
    """Fields that can be updated on a lesson."""

    instrument: str | None = None
    date: _dt.date | None = None
    start_time: str | None = None
    duration: int | None = None
    pieces: list["LessonPieceCreate"] | None = None
    location_name: str | None = None


class LessonStatusUpdate(BaseModel):
    """Change the status of a lesson."""

    status: str


class LessonFeedbackUpdate(BaseModel):
    """Write / update feedback on a completed lesson."""

    feedback: str | None = None
    key_points: list[str] = []
    practice_tips: str | None = None
