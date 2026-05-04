"""Analytics endpoints."""

from __future__ import annotations

import calendar
from datetime import datetime
from typing import Annotated

from dateutil.relativedelta import relativedelta
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.lesson import Lesson
from app.models.practice_log import PracticeLog
from app.models.student import Student
from app.models.subscription import Subscription
from app.models.user import User
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


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


@router.get("/monthly-stats", response_model=TeacherMonthlyStatsResponse)
async def get_monthly_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    month: str,
) -> TeacherMonthlyStatsResponse:
    parsed_month = datetime.fromisoformat(f"{month}-01")
    teacher_id = await resolve_teacher_id(db, current_user.id)
    if parsed_month.month == 12:
        next_month = parsed_month.replace(year=parsed_month.year + 1, month=1)
    else:
        next_month = parsed_month.replace(month=parsed_month.month + 1)

    lessons = (
        await db.scalars(
            select(Lesson).where(
                Lesson.teacher_id == teacher_id,
                Lesson.date >= parsed_month.date(),
                Lesson.date < next_month.date(),
            )
        )
    ).all()

    completed_statuses = {"completed"}
    cancelled_statuses = {
        "cancelled",
        "cancelledByStudentAdvance",
        "cancelledByStudentLate",
        "cancelledByTeacher",
        "cancelledMutual",
    }
    no_show_statuses = {"noShow", "studentAbsent"}

    def status_value(lesson: Lesson) -> str:
        return lesson.status.value if hasattr(lesson.status, "value") else str(lesson.status)

    completed_count = sum(1 for lesson in lessons if status_value(lesson) in completed_statuses)
    cancelled_count = sum(1 for lesson in lessons if status_value(lesson) in cancelled_statuses)
    no_show_count = sum(1 for lesson in lessons if status_value(lesson) in no_show_statuses)
    total_lessons = len(lessons)
    attendance_rate = completed_count / total_lessons if total_lessons else 0

    total_students = await db.scalar(
        select(func.count()).select_from(Student).where(
            Student.teacher_id == teacher_id,
            Student.is_active.is_(True),
        )
    )
    new_students = await db.scalar(
        select(func.count()).select_from(Student).where(
            Student.teacher_id == teacher_id,
            Student.created_at >= parsed_month,
            Student.created_at < next_month,
        )
    )
    churned_students = await db.scalar(
        select(func.count()).select_from(Student).where(
            Student.teacher_id == teacher_id,
            Student.status == "inactive",
            Student.updated_at >= parsed_month,
            Student.updated_at < next_month,
        )
    )
    _, days_in_month = calendar.monthrange(parsed_month.year, parsed_month.month)
    practice_rows = (
        await db.execute(
            select(
                Student.id,
                Student.name,
                Student.instrument,
                func.coalesce(func.sum(PracticeLog.total_minutes), 0).label("practice_minutes"),
                func.count(PracticeLog.id).label("practice_days"),
            )
            .join(PracticeLog, PracticeLog.student_id == Student.id)
            .where(
                Student.teacher_id == teacher_id,
                PracticeLog.date >= parsed_month.date(),
                PracticeLog.date < next_month.date(),
            )
            .group_by(Student.id, Student.name, Student.instrument)
            .order_by(func.coalesce(func.sum(PracticeLog.total_minutes), 0).desc())
            .limit(5)
        )
    ).all()
    practice_ranking = [
        StudentPracticeRankResponse(
            student_id=row.id,
            student_name=row.name,
            instrument=row.instrument,
            practice_rate=row.practice_days / days_in_month if days_in_month else 0,
            practice_minutes=row.practice_minutes,
        )
        for row in practice_rows
    ]
    async def sum_confirmed_revenue(start: datetime, end: datetime) -> int:
        revenue_date = func.coalesce(
            Subscription.payment_confirmed_at,
            Subscription.paid_at,
            Subscription.created_at,
        )
        result = await db.scalar(
            select(func.coalesce(func.sum(Subscription.amount), 0))
            .join(Student, Student.id == Subscription.student_id)
            .where(
                Student.teacher_id == teacher_id,
                Subscription.payment_confirmed.is_(True),
                revenue_date >= start,
                revenue_date < end,
            )
        )
        return result or 0

    total_revenue = await sum_confirmed_revenue(parsed_month, next_month)
    previous_month = parsed_month - relativedelta(months=1)
    previous_revenue = await sum_confirmed_revenue(previous_month, parsed_month)
    revenue_change_percent = (
        (total_revenue - previous_revenue) / previous_revenue if previous_revenue else 0
    )

    return TeacherMonthlyStatsResponse(
        month=parsed_month,
        total_lessons=total_lessons,
        completed_lessons=completed_count,
        cancelled_lessons=cancelled_count,
        no_show_lessons=no_show_count,
        total_revenue=total_revenue or 0,
        revenue_change_percent=revenue_change_percent,
        total_students=total_students or 0,
        new_students=new_students or 0,
        churned_students=churned_students or 0,
        attendance_rate=attendance_rate,
        lesson_trend=[
            MonthlyTrendResponse(
                month=parsed_month,
                lesson_count=total_lessons,
                revenue=total_revenue or 0,
            )
        ]
        if total_lessons or total_revenue
        else [],
        practice_ranking=practice_ranking,
    )
