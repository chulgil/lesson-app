"""Analytics schemas."""

from __future__ import annotations

import datetime as _dt

from pydantic import BaseModel


class MonthlyTrendResponse(BaseModel):
    month: _dt.datetime
    lesson_count: int
    revenue: int


class StudentPracticeRankResponse(BaseModel):
    student_id: str
    student_name: str
    instrument: str
    practice_rate: float
    practice_minutes: int


class DailyPracticePoint(BaseModel):
    date: _dt.date
    minutes: int


class AttendanceCalendarEntry(BaseModel):
    date: _dt.date
    status: str  # "completed" | "cancelled" | "no_show"


class StudentProgressResponse(BaseModel):
    """학생 성장 분석 — 출석률·연습 달성률·최근 레슨 기록."""

    student_id: str
    student_name: str
    period_start: _dt.date
    period_end: _dt.date
    # 레슨 출석
    total_lessons: int
    attended_lessons: int
    attendance_rate: float  # 0.0 ~ 1.0
    # 연습
    total_practice_minutes: int
    practice_streak_days: int
    practice_achievement_rate: float  # 0.0 ~ 1.0 (일 목표 달성율)
    weekly_practice: list[DailyPracticePoint]
    attendance_calendar: list[AttendanceCalendarEntry]


class TeacherMonthlyStatsResponse(BaseModel):
    month: _dt.datetime
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
