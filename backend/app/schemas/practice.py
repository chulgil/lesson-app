"""Practice-related schemas: repertoires, sections, goals, stats."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict

# ---------------------------------------------------------------------------
# Practice section
# ---------------------------------------------------------------------------

class SectionResponse(BaseModel):
    """A practice section within a repertoire."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    repertoire_id: str
    piece_name: str | None = None
    range_type: str | None = None
    start_measure: int | None = None
    end_measure: int | None = None
    is_repeat: bool = False
    is_completed: bool = False
    order: int = 0
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class SectionCreate(BaseModel):
    """Create a section."""

    repertoire_id: str
    piece_name: str | None = None
    range_type: str | None = None
    start_measure: int | None = None
    end_measure: int | None = None
    is_repeat: bool = False


class SectionUpdate(BaseModel):
    """Update a section."""

    piece_name: str | None = None
    range_type: str | None = None
    start_measure: int | None = None
    end_measure: int | None = None
    is_repeat: bool | None = None


class SectionCompleteRequest(BaseModel):
    """Toggle section completion for a specific _dt.date."""

    date: _dt.date
    is_completed: bool


class SectionNoteCreate(BaseModel):
    """Add a note to a section."""

    content: str


# ---------------------------------------------------------------------------
# Repertoire
# ---------------------------------------------------------------------------

class RepertoireResponse(BaseModel):
    """Full repertoire representation with sections."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    name: str
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    is_archived: bool = False
    sections: list[SectionResponse] = []
    created_at: _dt.datetime | None = None
    updated_at: _dt.datetime | None = None


class RepertoireCreate(BaseModel):
    """Create a repertoire, optionally with inline sections."""

    student_id: str
    name: str
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None
    sections: list[SectionCreate] = []


class RepertoireUpdate(BaseModel):
    """Update a repertoire."""

    name: str | None = None
    start_date: _dt.date | None = None
    end_date: _dt.date | None = None


# ---------------------------------------------------------------------------
# Recording (associated with sections)
# ---------------------------------------------------------------------------

class RecordingResponse(BaseModel):
    """Recording metadata."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    section_id: str | None = None
    student_id: str | None = None
    file_url: str | None = None
    duration_seconds: int | None = None
    bpm: int | None = None
    is_representative: bool = False
    created_at: _dt.datetime | None = None


class RecordingUploadResponse(BaseModel):
    """Response after a successful recording upload."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    section_id: str | None = None
    file_url: str
    duration_seconds: int | None = None
    bpm: int | None = None
    created_at: _dt.datetime


# ---------------------------------------------------------------------------
# Practice goals & stats
# ---------------------------------------------------------------------------

class PracticeGoalResponse(BaseModel):
    """Practice goal settings for a student."""

    model_config = ConfigDict(from_attributes=True)

    student_id: str
    daily_time_minutes: int | None = None
    daily_section_count: int | None = None
    weekly_time_minutes: int | None = None
    weekly_day_count: int | None = None


class PracticeGoalUpdate(BaseModel):
    """Update practice goals."""

    student_id: str
    daily_time_minutes: int | None = None
    daily_section_count: int | None = None
    weekly_time_minutes: int | None = None
    weekly_day_count: int | None = None


class PracticeStreakResponse(BaseModel):
    """Current practice streak data."""

    model_config = ConfigDict(from_attributes=True)

    id: str = ""
    student_id: str = ""
    current_streak: int = 0
    longest_streak: int = 0
    last_practice_date: _dt.date | None = None
    updated_at: _dt.datetime | None = None


class DailyStat(BaseModel):
    """Stats for a single day."""

    minutes: int = 0
    sections_completed: int = 0


class PracticeStatsResponse(BaseModel):
    """Monthly practice statistics."""

    model_config = ConfigDict(from_attributes=True)

    total_practice_minutes: int = 0
    total_practice_days: int = 0
    completed_sections: int = 0
    current_streak: int = 0
    longest_streak: int = 0
    daily_stats: dict[str, DailyStat] = {}
