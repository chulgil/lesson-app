"""Practice Loop Stats schemas — #512.

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4 (선생님 통계) + §5 (동기화).

Three flows:
- Student sync (POST): client uploads one or more (section, count, last_played)
  rows. Idempotent — server keeps max(stored, incoming).
- Teacher list (GET): query a single student's per-section repeats with an
  optional time window (`weekly` / `monthly`).
- Teacher list (GET aggregate per teacher): all students summarised — used
  for the dashboard entry card on the home screen.
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field


class StatsWindow(str, enum.Enum):
    """Time window toggle exposed in the teacher UI (spec §4.3)."""

    weekly = "weekly"
    monthly = "monthly"


# ---------------------------------------------------------------------------
# Student sync — POST /api/v1/practice-loop-stats/sync
# ---------------------------------------------------------------------------


class PracticeLoopStatsSyncEntry(BaseModel):
    """One (section, count) pair the client wants to persist."""

    section_id: str = Field(..., min_length=1, max_length=64)
    repeat_count: int = Field(..., ge=0)
    last_played_at: _dt.datetime


class PracticeLoopStatsSyncRequest(BaseModel):
    """Batched upload from the client. Sent at session end / scheduled flush."""

    entries: list[PracticeLoopStatsSyncEntry] = Field(default_factory=list)


class PracticeLoopStatsSyncResult(BaseModel):
    """Sync outcome — server reports how many rows were upserted vs skipped."""

    upserted: int = 0
    skipped: int = 0
    rejected: int = 0


# ---------------------------------------------------------------------------
# Teacher list — GET /api/v1/practice-loop-stats/students/{student_id}
# ---------------------------------------------------------------------------


class PracticeLoopStatsRow(BaseModel):
    """One section row for the teacher view."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    section_id: str
    repeat_count: int
    last_played_at: _dt.datetime
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None
    # Convenience labels (populated by the service when joinable).
    piece_name: str | None = None
    section_name: str | None = None


class PracticeLoopStatsListResponse(BaseModel):
    """Per-student response for the teacher UI."""

    student_id: str
    window: StatsWindow
    total_repeats: int = 0
    rows: list[PracticeLoopStatsRow] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Teacher dashboard summary — GET /api/v1/practice-loop-stats/summary
# ---------------------------------------------------------------------------


class PracticeLoopStatsStudentSummary(BaseModel):
    """One student's roll-up for the teacher dashboard card."""

    student_id: str
    student_name: str | None = None
    total_repeats: int = 0
    last_played_at: _dt.datetime | None = None


class PracticeLoopStatsSummaryResponse(BaseModel):
    """Per-teacher roll-up across all linked students."""

    teacher_id: str
    window: StatsWindow
    students: list[PracticeLoopStatsStudentSummary] = Field(default_factory=list)
