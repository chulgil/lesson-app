"""Practice log service."""

from __future__ import annotations

import calendar
from datetime import UTC, date, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import LastWriteWinsConflictException


class PracticeLogService:
    """Handle daily practice logs."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_logs(
        self,
        student_id: str,
        current_user: Any,
        *,
        year: int | None = None,
        month: int | None = None,
        log_date: date | None = None,
    ) -> list[Any]:
        """Get practice logs with optional date/month filters."""
        from app.models.practice_log import PracticeLog

        await self._assert_can_read_student(student_id, current_user)
        query = select(PracticeLog).where(PracticeLog.student_id == student_id)
        if log_date is not None:
            query = query.where(PracticeLog.date == log_date)
        elif year is not None and month is not None:
            start = date(year, month, 1)
            _, last_day = calendar.monthrange(year, month)
            end = date(year, month, last_day)
            query = query.where(PracticeLog.date >= start, PracticeLog.date <= end)

        result = await self.db.scalars(query.order_by(PracticeLog.date))
        return list(result.all())

    async def get_log_by_date(self, student_id: str, log_date: date, current_user: Any) -> Any | None:
        """Get practice log for a specific date."""
        from app.models.practice_log import PracticeLog

        await self._assert_can_read_student(student_id, current_user)
        return await self.db.scalar(
            select(PracticeLog).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date == log_date,
            )
        )

    async def get_log_by_id(self, log_id: str, current_user: Any) -> Any:
        """Get practice log by ID."""
        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        await self._assert_can_read_student(log.student_id, current_user)
        return log

    async def create_log(self, student_id: str, data: dict, current_user: Any) -> Any:
        """Create a practice log."""
        from app.models.practice_log import PracticeLog

        await self._assert_can_manage_student(student_id, current_user)
        existing = await self.get_log_by_date(student_id, data["date"], current_user)
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

    async def update_log(
        self,
        log_id: str,
        data: dict,
        current_user: Any,
        if_unmodified_since: datetime | None = None,
    ) -> Any:
        """Update a practice log.

        #1119 (D4): when ``if_unmodified_since`` is given (the client's base
        version), reject with 412 ``CONFLICT_LWW_REJECTED`` if the row was
        modified after it — a Last-Write-Wins conflict. Checked against the
        loaded row BEFORE any change, so ``onupdate`` does not mask it.
        """
        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        await self._assert_can_manage_student(log.student_id, current_user)

        if if_unmodified_since is not None and log.updated_at is not None:
            server_updated = log.updated_at
            # SQLite loses tzinfo; normalize both sides to aware UTC to compare.
            if server_updated.tzinfo is None:
                server_updated = server_updated.replace(tzinfo=UTC)
            if server_updated > if_unmodified_since:
                raise LastWriteWinsConflictException()

        for key, value in data.items():
            if value is not None:
                setattr(log, key, value)
        await self.db.flush()
        await self.db.refresh(log)
        return log

    async def delete_log(self, log_id: str, current_user: Any) -> None:
        """Delete a practice log."""
        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        await self._assert_can_manage_student(log.student_id, current_user)
        await self.db.delete(log)
        await self.db.flush()

    async def toggle_task(self, log_id: str, task_id: str, current_user: Any) -> Any:
        """Toggle task completion in a practice log."""
        from sqlalchemy.orm.attributes import flag_modified

        from app.models.practice_log import PracticeLog

        log = await self.db.get(PracticeLog, log_id)
        if log is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
        await self._assert_can_manage_student(log.student_id, current_user)
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

    async def get_weekly_practice(self, student_id: str, week_start: date, current_user: Any) -> list[bool]:
        """Get 7-day practice status (Mon-Sun)."""
        from datetime import timedelta

        from app.models.practice_log import PracticeLog

        await self._assert_can_read_student(student_id, current_user)
        week_end = week_start + timedelta(days=6)
        result = await self.db.scalars(
            select(PracticeLog.date).where(
                PracticeLog.student_id == student_id,
                PracticeLog.date >= week_start,
                PracticeLog.date <= week_end,
            )
        )
        practiced_dates = set(result.all())
        return [(week_start + timedelta(days=i)) in practiced_dates for i in range(7)]

    async def get_monthly_stats(self, student_id: str, year: int, month: int, current_user: Any) -> dict:
        """Get monthly practice statistics."""
        from app.models.practice_log import PracticeLog

        await self._assert_can_read_student(student_id, current_user)
        start = date(year, month, 1)
        _, last_day = calendar.monthrange(year, month)
        end = date(year, month, last_day)

        count = (
            await self.db.scalar(
                select(func.count()).where(
                    PracticeLog.student_id == student_id,
                    PracticeLog.date >= start,
                    PracticeLog.date <= end,
                )
            )
            or 0
        )

        total_minutes = (
            await self.db.scalar(
                select(func.coalesce(func.sum(PracticeLog.total_minutes), 0)).where(
                    PracticeLog.student_id == student_id,
                    PracticeLog.date >= start,
                    PracticeLog.date <= end,
                )
            )
            or 0
        )

        return {
            "year": year,
            "month": month,
            "total_days": last_day,
            "practiced_days": count,
            "total_minutes": total_minutes,
            "average_minutes_per_day": round(total_minutes / max(count, 1), 1),
        }

    async def _assert_can_read_student(self, student_id: str, current_user: Any) -> None:
        role = self._role(current_user)
        if role == "teacher":
            await self._assert_teacher_owns_student_if_present(student_id, current_user)
            return
        if role == "student" and await self._student_matches_user(student_id, current_user):
            return
        if role == "parent" and student_id in await self._parent_child_student_ids(current_user):
            return
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_can_manage_student(self, student_id: str, current_user: Any) -> None:
        role = self._role(current_user)
        if role == "teacher":
            await self._assert_teacher_owns_student_if_present(student_id, current_user)
            return
        if role == "student" and await self._student_matches_user(student_id, current_user):
            return
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_teacher_owns_student_if_present(self, student_id: str, current_user: Any) -> None:
        from app.models.student import Student
        from app.services.teacher_id_resolver import resolve_teacher_id

        student = await self.db.get(Student, student_id)
        if student is None:
            return
        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if student.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _student_matches_user(self, student_id: str, current_user: Any) -> bool:
        from app.models.student import Student

        if student_id == current_user.id:
            return True
        linked_id = await self.db.scalar(
            select(Student.id).where(
                Student.id == student_id,
                Student.user_id == current_user.id,
            )
        )
        return linked_id is not None

    async def _parent_child_student_ids(self, current_user: Any) -> list[str]:
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
        if parent_id is None:
            return []
        result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        return list(result.all())

    def _role(self, current_user: Any) -> str | None:
        return getattr(getattr(current_user, "role", None), "value", None)
