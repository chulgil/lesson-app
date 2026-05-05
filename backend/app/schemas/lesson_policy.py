"""Lesson policy schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class LessonPolicyPayload(BaseModel):
    """Frontend LessonPolicy JSON shape."""

    teacher_id: str | None = None
    lesson_class_id: str | None = None
    min_cancel_hours: int | None = None
    max_changes_per_month: int | None = None
    allow_same_day_cancel: bool | None = None
    late_cancel_deadline: str | None = None
    deduct_lesson_on_no_show: bool | None = None
    grace_period_minutes: int | None = None
    allow_carryover: bool | None = None
    max_carryover_lessons: int | None = None
    carryover_period_months: int | None = None
    full_refund_days: int | None = None
    partial_refund_ratio: float | None = None
    halfway_refund_ratio: float | None = None
    no_show_refund_ratio: float | None = None


class LessonPolicyResponse(BaseModel):
    """Frontend-compatible lesson policy response."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_class_id: str | None = None
    teacher_id: str
    min_cancel_hours: int = 4
    max_changes_per_month: int = 2
    allow_same_day_cancel: bool = False
    late_cancel_deadline: str | None = None
    deduct_lesson_on_no_show: bool = True
    grace_period_minutes: int = 15
    allow_carryover: bool = True
    max_carryover_lessons: int = 1
    carryover_period_months: int = 1
    full_refund_days: int = 1
    partial_refund_ratio: float = 0.67
    halfway_refund_ratio: float = 0.0
    no_show_refund_ratio: float = 0.67
    created_at: datetime
    updated_at: datetime | None = None
