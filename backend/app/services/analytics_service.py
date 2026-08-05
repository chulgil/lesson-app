"""Analytics service."""

from __future__ import annotations

import calendar
import datetime as _dt
from datetime import datetime
from typing import Any

from dateutil.relativedelta import relativedelta
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.analytics import (
    AttendanceCalendarEntry,
    DailyPracticePoint,
    MonthlyTrendResponse,
    StudentPracticeRankResponse,
    StudentProgressResponse,
    TeacherMonthlyStatsResponse,
)
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

        lesson_trend = await self._build_lesson_trend(teacher_id, parsed_month)

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
            lesson_trend=lesson_trend,
            practice_ranking=practice_ranking,
        )

    async def _build_lesson_trend(self, teacher_id: str, parsed_month: datetime) -> list[MonthlyTrendResponse]:
        from app.models.lesson import Lesson
        from app.models.student import Student
        from app.models.subscription import Subscription

        trend_start = parsed_month - relativedelta(months=5)
        trend_end = parsed_month + relativedelta(months=1)
        trend_months = [trend_start + relativedelta(months=offset) for offset in range(6)]
        lesson_counts = {(month.year, month.month): 0 for month in trend_months}
        revenues = {(month.year, month.month): 0 for month in trend_months}

        lesson_rows = (
            await self.db.execute(
                select(Lesson.date, func.count())
                .where(
                    Lesson.teacher_id == teacher_id,
                    Lesson.date >= trend_start.date(),
                    Lesson.date < trend_end.date(),
                )
                .group_by(Lesson.date)
            )
        ).all()
        for lesson_date, lesson_count in lesson_rows:
            key = (lesson_date.year, lesson_date.month)
            if key in lesson_counts:
                lesson_counts[key] += lesson_count

        revenue_date = func.coalesce(
            Subscription.payment_confirmed_at,
            Subscription.paid_at,
            Subscription.created_at,
        ).label("revenue_date")
        revenue_rows = (
            await self.db.execute(
                select(Subscription.amount, revenue_date)
                .join(Student, Student.id == Subscription.student_id)
                .where(
                    Student.teacher_id == teacher_id,
                    Subscription.payment_confirmed.is_(True),
                    revenue_date >= trend_start,
                    revenue_date < trend_end,
                )
            )
        ).all()
        for amount, revenue_at in revenue_rows:
            if isinstance(revenue_at, str):
                revenue_at = datetime.fromisoformat(revenue_at)
            key = (revenue_at.year, revenue_at.month)
            if key in revenues:
                revenues[key] += amount or 0

        return [
            MonthlyTrendResponse(
                month=month,
                lesson_count=lesson_counts[(month.year, month.month)],
                revenue=revenues[(month.year, month.month)],
            )
            for month in trend_months
        ]

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

    async def get_student_progress(
        self,
        teacher_id: str,
        student_id: str,
        period_days: int = 30,
    ) -> StudentProgressResponse:
        """Return attendance and practice progress for a student over the given period."""
        from app.models.lesson import Lesson, LessonStatus
        from app.models.practice_log import PracticeLog
        from app.models.student import Student

        end = _dt.date.today()
        start = end - _dt.timedelta(days=period_days - 1)

        # Verify student belongs to teacher.
        student = await self.db.scalar(
            select(Student).where(
                Student.id == student_id,
                Student.teacher_id == teacher_id,
            )
        )
        if student is None:
            return StudentProgressResponse(
                student_id=student_id,
                student_name="",
                period_start=start,
                period_end=end,
                total_lessons=0,
                attended_lessons=0,
                attendance_rate=0.0,
                total_practice_minutes=0,
                practice_streak_days=0,
                practice_achievement_rate=0.0,
                weekly_practice=[],
                attendance_calendar=[],
            )

        # Lessons in the period.
        lessons = (
            await self.db.scalars(
                select(Lesson).where(
                    Lesson.student_id == student_id,
                    Lesson.date >= _dt.datetime.combine(start, _dt.time.min),
                    Lesson.date < _dt.datetime.combine(end + _dt.timedelta(days=1), _dt.time.min),
                )
            )
        ).all()

        total = len(lessons)
        attended = sum(1 for l in lessons if l.status == LessonStatus.completed)
        attendance_rate = attended / total if total > 0 else 0.0

        attendance_calendar = [
            AttendanceCalendarEntry(
                date=l.date.date() if isinstance(l.date, datetime) else l.date,
                status=l.status.value,
            )
            for l in lessons
        ]

        # Practice logs.
        logs = (
            await self.db.scalars(
                select(PracticeLog).where(
                    PracticeLog.student_id == student_id,
                    PracticeLog.date >= start,
                    PracticeLog.date <= end,
                )
            )
        ).all()

        total_minutes = sum(l.total_minutes for l in logs)
        log_by_date = {l.date: l.total_minutes for l in logs}
        weekly_practice = [
            DailyPracticePoint(
                date=start + _dt.timedelta(days=i),
                minutes=log_by_date.get(start + _dt.timedelta(days=i), 0),
            )
            for i in range(period_days)
        ]

        # Streak: authoritative full-history value (KST), window-independent (SSOT).
        from app.services.streak_service import compute_streak

        streak = (await compute_streak(self.db, student_id)).current

        # Achievement rate: fraction of days in period with any practice.
        days_with_practice = sum(1 for m in log_by_date.values() if m > 0)
        achievement_rate = days_with_practice / period_days

        return StudentProgressResponse(
            student_id=student_id,
            student_name=student.name,
            period_start=start,
            period_end=end,
            total_lessons=total,
            attended_lessons=attended,
            attendance_rate=attendance_rate,
            total_practice_minutes=total_minutes,
            practice_streak_days=streak,
            practice_achievement_rate=achievement_rate,
            weekly_practice=weekly_practice,
            attendance_calendar=attendance_calendar,
        )
