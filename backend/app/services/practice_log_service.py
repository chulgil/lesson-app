"""Practice log service."""

from __future__ import annotations

import calendar
from datetime import date
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession


class PracticeLogService:
    """Handle daily practice logs."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_logs(self, student_id: str, *, year: int, month: int) -> list[Any]:
        """Get practice logs for a month."""
        from app.models.practice_log import PracticeLog

        start = date(year, month, 1)
        _, last_day = calendar.monthrange(year, month)
        end = date(year, month, last_day)

        result = await self.db.scalars(
            select(PracticeLog)
            .where(
                PracticeLog.student_id == student_id,
                PracticeLog.date >= start,
                PracticeLog.date <= end,
            )
            .order_by(PracticeLog.date)
        )
        return list(result.all())

    async def get_log_by_date(self, student_id: str, log_date: date) -> Any | None:
        """Get practice log for a specific date."""
        from app.models.practice_log import PracticeLog

        return await self.db.scalar(
            select(PracticeLog).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date == log_date,
            )
        )

    async def create_log(self, student_id: str, data: dict) -> Any:
        """Create a practice log."""
        from app.models.practice_log import PracticeLog

        existing = await self.get_log_by_date(student_id, data["date"])
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Log already exists for this date",
            )

        log = PracticeLog(student_id=student_id, **data)
        self.db.add(log)
        await self.db.flush()
        await self.db.refresh(log)
        return log

    async def update_log(self, log_id: str, data: dict) -> Any:
        """Update a practice log."""
        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        for key, value in data.items():
            if value is not None:
                setattr(log, key, value)
        await self.db.flush()
        await self.db.refresh(log)
        return log

    async def delete_log(self, log_id: str) -> None:
        """Delete a practice log."""
        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        await self.db.delete(log)
        await self.db.flush()

    async def toggle_task(self, log_id: str, task_id: str) -> Any:
        """Toggle task completion in a practice log."""
        from sqlalchemy.orm.attributes import flag_modified

        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        tasks = list(log.tasks or [])
        for task in tasks:
            if task.get("id") == task_id:
                task["is_completed"] = not task.get("is_completed", False)
                break
        log.tasks = tasks
        flag_modified(log, "tasks")
        await self.db.flush()
        await self.db.refresh(log)
        return log

    async def get_weekly_practice(self, student_id: str, week_start: date) -> list[bool]:
        """Get 7-day practice status (Mon-Sun)."""
        from datetime import timedelta

        from app.models.practice_log import PracticeLog

        week_end = week_start + timedelta(days=6)
        result = await self.db.scalars(
            select(PracticeLog.date).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date >= week_start,
                PracticeLog.date <= week_end,
            )
        )
        practiced_dates = set(result.all())
        return [
            (week_start + timedelta(days=i)) in practiced_dates
            for i in range(7)
        ]

    async def get_monthly_stats(self, student_id: str, year: int, month: int) -> dict:
        """Get monthly practice statistics."""
        from app.models.practice_log import PracticeLog

        start = date(year, month, 1)
        _, last_day = calendar.monthrange(year, month)
        end = date(year, month, last_day)

        count = await self.db.scalar(
            select(func.count()).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date >= start,
                PracticeLog.date <= end,
            )
        ) or 0

        total_minutes = await self.db.scalar(
            select(func.coalesce(func.sum(PracticeLog.total_minutes), 0)).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date >= start,
                PracticeLog.date <= end,
            )
        ) or 0

        return {
            "year": year,
            "month": month,
            "total_days": last_day,
            "practiced_days": count,
            "total_minutes": total_minutes,
            "average_minutes_per_day": round(total_minutes / max(count, 1), 1),
        }
