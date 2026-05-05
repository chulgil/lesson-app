"""Analytics schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class MonthlyTrendResponse(BaseModel):
    month: datetime
    lesson_count: int
    revenue: int


class StudentPracticeRankResponse(BaseModel):
    student_id: str
    student_name: str
    instrument: str
    practice_rate: float
    practice_minutes: int


class TeacherMonthlyStatsResponse(BaseModel):
    month: datetime
    total_lessons: int
    completed_lessons: int
    cancelled_lessons: int
    no_show_lessons: int
    total_revenue: int
    revenue_change_percent: float
    total_students: int
    new_students: int
    churned_students: int
    attendance_rate: float
    lesson_trend: list[MonthlyTrendResponse]
    practice_ranking: list[StudentPracticeRankResponse]
