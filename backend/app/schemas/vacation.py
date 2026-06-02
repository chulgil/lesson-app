"""Teacher vacation period schemas (#431).

Spec: docs/specs/schedule/teacher_vacation_mode.md §3.
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field, model_validator


class VacationDisposition(str, enum.Enum):
    """Mirrors backend.app.models.schedule.VacationDisposition for API I/O."""

    makeupCredit = "makeupCredit"
    freeCancel = "freeCancel"
    rollForward = "rollForward"


class VacationPeriodCreate(BaseModel):
    """Request body for POST /api/teacher/vacation.

    Spec §9.1: 휴가 등록 — start/end 기간 + 기본 처리 옵션.
    §4.2 — `per_student_disposition` overrides per-student handling.
    """

    start_date: _dt.date
    end_date: _dt.date
    reason: str | None = Field(default=None, max_length=200)
    default_disposition: VacationDisposition = VacationDisposition.rollForward
    # student_id → disposition. Omitted/empty means "use default for everyone".
    per_student_disposition: dict[str, VacationDisposition] | None = None

    @model_validator(mode="after")
    def validate_date_range(self) -> VacationPeriodCreate:
        if self.end_date < self.start_date:
            raise ValueError("end_date must be >= start_date")
        return self


class VacationPeriodResponse(BaseModel):
    """Response body for vacation period CRUD."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    start_date: _dt.date
    end_date: _dt.date
    reason: str | None = None
    default_disposition: VacationDisposition
    per_student_disposition: dict[str, VacationDisposition] | None = None
    cancelled_at: _dt.datetime | None = None
    created_at: _dt.datetime
    updated_at: _dt.datetime | None = None


class VacationListResponse(BaseModel):
    """Response body for GET /api/teacher/vacation — list of periods."""

    vacations: list[VacationPeriodResponse] = []
    total_count: int


class VacationImpactedStudent(BaseModel):
    """Per-student impact summary (spec §4.1 step 2)."""

    student_id: str
    student_name: str | None = None
    lesson_count: int


class VacationImpactPreview(BaseModel):
    """Response body for GET /api/teacher/vacation/impact.

    Spec §4.1 step 2: 기간 입력 → 영향 받는 레슨/학생 미리보기.
    """

    start_date: _dt.date
    end_date: _dt.date
    impacted_lesson_count: int
    impacted_student_count: int
    impacted_students: list[VacationImpactedStudent] = []
