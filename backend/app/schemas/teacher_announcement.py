"""Teacher announcement API schemas."""

from __future__ import annotations

from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field, model_validator


class AffectedLesson(BaseModel):
    """휴강 공지 영향 수업 단위."""

    student_id: str
    student_name: str
    instrument: str
    start_time: str
    session_number: int | None = None
    subscription_id: str | None = None


class TeacherAnnouncementCreate(BaseModel):
    """선생님 공지 생성 요청."""

    teacher_id: str
    type: Literal["dayOff", "general"]
    dates: list[date] = Field(default_factory=list)
    message: str

    @model_validator(mode="after")
    def _validate_dayoff_dates(self) -> "TeacherAnnouncementCreate":
        if self.type == "dayOff" and not self.dates:
            raise ValueError("dates required for dayOff type")
        if self.type == "general" and self.dates:
            raise ValueError("dates must be empty for general type")
        return self


class TeacherAnnouncementResponse(BaseModel):
    """선생님 공지 생성/목록 응답."""

    id: str
    teacher_id: str
    type: Literal["dayOff", "general"]
    dates: list[date]
    message: str
    created_at: datetime
    notified_count: int
    affected_lessons: list[AffectedLesson] = Field(default_factory=list)


class TeacherAnnouncementDayOffsResponse(BaseModel):
    """기간별 휴강일 목록 응답."""

    dates: list[date]
