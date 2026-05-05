"""Analytics service."""

from __future__ import annotations

import calendar
from datetime import datetime
from typing import Any

from dateutil.relativedelta import relativedelta
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.analytics import MonthlyTrendResponse, StudentPracticeRankResponse, TeacherMonthlyStatsResponse
from app.services.teacher_id_resolver import resolve_teacher_id


class AnalyticsService:
    """Aggregate teacher dashboard metrics."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_monthly_stats(self, current_user: Any, month: str) -> TeacherMonthlyStatsResponse:
        """Return teacher monthly analytics."""
        from app.models.lesson import Lesson
        from app.models.practice_log import PracticeLog
        from app.models.student import Student

        parsed_month = datetime.fromisoformat(f"{month}-01")
        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        next_month = (
            parsed_month.replace(year=parsed_month.year + 1, month=1)
            if parsed_month.month == 12
            else parsed_month.replace(month=parsed_month.month + 1)
        )

        lessons = (
            await self.db.scalars(
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

        def status_value(lesson: Any) -> str:
            return lesson.status.value if hasattr(lesson.status, "value") else str(lesson.status)

        completed_count = sum(1 for lesson in lessons if status_value(lesson) in completed_statuses)
        cancelled_count = sum(1 for lesson in lessons if status_value(lesson) in cancelled_statuses)
        no_show_count = sum(1 for lesson in lessons if status_value(lesson) in no_show_statuses)
        total_lessons = len(lessons)
        attendance_rate = completed_count / total_lessons if total_lessons else 0

        total_students = await self.db.scalar(
            select(func.count()).select_from(Student).where(
                Student.teacher_id == teacher_id,
                Student.is_active.is_(True),
            )
        )
        new_students = await self.db.scalar(
            select(func.count()).select_from(Student).where(
                Student.teacher_id == teacher_id,
                Student.created_at >= parsed_month,
                Student.created_at < next_month,
            )
        )
        churned_students = await self.db.scalar(
            select(func.count()).select_from(Student).where(
                Student.teacher_id == teacher_id,
                Student.status == "inactive",
                Student.updated_at >= parsed_month,
                Student.updated_at < next_month,
            )
        )

        _, days_in_month = calendar.monthrange(parsed_month.year, parsed_month.month)
        practice_rows = (
            await self.db.execute(
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

        total_revenue = await self._sum_confirmed_revenue(teacher_id, parsed_month, next_month)
        previous_month = parsed_month - relativedelta(months=1)
        previous_revenue = await self._sum_confirmed_revenue(teacher_id, previous_month, parsed_month)
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

    async def _sum_confirmed_revenue(self, teacher_id: str, start: datetime, end: datetime) -> int:
        from app.models.student import Student
        from app.models.subscription import Subscription

        revenue_date = func.coalesce(
            Subscription.payment_confirmed_at,
            Subscription.paid_at,
            Subscription.created_at,
        )
        result = await self.db.scalar(
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
