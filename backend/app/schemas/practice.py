"""Practice-related schemas: repertoires, sections, goals, stats."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field


def _camel_alias(field_name: str) -> str:
    return "".join(word.capitalize() if index else word for index, word in enumerate(field_name.split("_")))


CAMEL_MODEL_CONFIG = ConfigDict(populate_by_name=True, alias_generator=_camel_alias)


# ---------------------------------------------------------------------------
# Practice piece library
# ---------------------------------------------------------------------------


class PracticePieceCreate(BaseModel):
    """Create a practice library piece."""

    title: str
    composer: str | None = None
    opus: str | None = None
    movement: str | None = None
    difficulty: str | None = None
    notes: str | None = None


class PracticePieceUpdate(BaseModel):
    """Update a practice library piece."""

    title: str | None = None
    composer: str | None = None
    opus: str | None = None
    movement: str | None = None
    difficulty: str | None = None
    notes: str | None = None


class PracticePieceResponse(BaseModel):
    """Practice piece response matching Flutter Piece fields."""

    model_config = CAMEL_MODEL_CONFIG

    id: str
    title: str
    composer: str | None = None
    opus: str | None = None
    movement: str | None = None
    difficulty: str | None = None
    progress: str = "notStarted"
    progress_percentage: float = 0.0
    notes: str | None = None
    started_at: _dt.datetime | None = None
    completed_at: _dt.datetime | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class StudentPieceProgressUpdate(BaseModel):
    """Update a student's assigned piece progress."""

    progress: str = Field(pattern="^(notStarted|inProgress|polishing|completed)$")


class StudentPieceRepertoireResponse(BaseModel):
    """Student repertoire response matching Flutter Repertoire fields."""

    model_config = CAMEL_MODEL_CONFIG

    student_id: str
    current_pieces: list[PracticePieceResponse] = []
    completed_pieces: list[PracticePieceResponse] = []


# ---------------------------------------------------------------------------
# Practice item
# ---------------------------------------------------------------------------


class PracticeItemCreate(BaseModel):
    """Create a teacher-assigned practice item."""

    model_config = CAMEL_MODEL_CONFIG

    lesson_id: str
    student_id: str
    type: str = "repertoire"
    title: str
    description: str | None = None
    repertoire_id: str | None = None
    section_id: str | None = None
    priority: str = "should"
    resource_ids: list[str] = []


class PracticeItemUpdate(BaseModel):
    """Update a teacher-assigned practice item."""

    model_config = CAMEL_MODEL_CONFIG

    type: str | None = None
    title: str | None = None
    description: str | None = None
    repertoire_id: str | None = None
    section_id: str | None = None
    priority: str | None = None
    resource_ids: list[str] | None = None
    is_completed: bool | None = None


class PracticeItemResponse(BaseModel):
    """Practice item response matching Flutter PracticeItem fields."""

    model_config = CAMEL_MODEL_CONFIG

    id: str
    lesson_id: str
    student_id: str
    teacher_id: str
    type: str
    title: str
    description: str | None = None
    repertoire_id: str | None = None
    section_id: str | None = None
    priority: str
    resource_ids: list[str] = []
    is_completed: bool
    practice_count: int
    completed_at: _dt.datetime | None = None
    has_like: bool
    liked_at: _dt.datetime | None = None
    teacher_reaction: str | None = None
    teacher_reaction_at: _dt.datetime | None = None
    student_response: str | None = None
    student_response_at: _dt.datetime | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None

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
    practice_count: int = 0
    total_practice_seconds: int = 0
    last_practiced_at: _dt.datetime | None = None
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


class SectionDailyCompletionUpdate(BaseModel):
    """Toggle section completion for a practice date."""

    date: _dt.date


class SectionNoteCreate(BaseModel):
    """Add a note to a section."""

    content: str


class SectionNoteResponse(BaseModel):
    """Practice note attached to a section."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    section_id: str
    content: str
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class SectionNoteUpdate(BaseModel):
    """Update a practice note."""

    content: str


class SectionPracticeCountUpdate(BaseModel):
    """Increment section practice counters."""

    practice_seconds: int = Field(ge=0)


class SectionOrderUpdate(BaseModel):
    """Update section ordering for a repertoire."""

    section_ids: list[str]


class RecordingMetadataCreate(BaseModel):
    """Create recording metadata without uploading a file."""

    section_id: str
    file_path: str
    duration_seconds: int = Field(default=0, ge=0)
    bpm: int | None = Field(default=None, ge=0)


class RepresentativeRecordingUpdate(BaseModel):
    """Set a section representative recording."""

    recording_id: str


class RecordingReassignUpdate(BaseModel):
    """Reassign a recording to a different section."""

    section_id: str


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
