"""AI lesson notes schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class AiNoteRequest(BaseModel):
    """Request to generate AI notes from a lesson recording."""

    lesson_id: str
    student_name: str | None = None
    instrument: str | None = None
    level: str | None = None
    pieces: list[str] = []


class SuggestedAssignment(BaseModel):
    """A suggested practice assignment."""

    title: str
    description: str


class AiNoteResponse(BaseModel):
    """Generated AI lesson notes."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_id: str
    feedback: str | None = None
    key_points: list[str] = []
    practice_tips: str | None = None
    suggested_assignments: list[SuggestedAssignment] = []
    transcription: str | None = None
    status: str = "completed"  # pending, processing, completed, failed
    error_message: str | None = None
    created_at: _dt.datetime | None = None


class AiNoteGenerateResponse(BaseModel):
    """Response when starting AI note generation."""

    job_id: str
    status: str = "processing"
    message: str = "AI 노트를 생성하고 있습니다..."
