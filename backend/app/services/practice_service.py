"""Practice service – repertoires, sections, goals, stats."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.practice import (
    DailyStat,
    PracticeGoalResponse,
    PracticeGoalUpdate,
    PracticeStatsResponse,
    PracticeStreakResponse,
    RepertoireCreate,
    RepertoireResponse,
    RepertoireUpdate,
    SectionCompleteRequest,
    SectionCreate,
    SectionNoteCreate,
    SectionResponse,
    SectionUpdate,
)


class PracticeService:
    """Handle practice repertoires, sections, goals, and statistics."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Repertoires
    # ------------------------------------------------------------------

    async def get_all_repertoires(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        include_archived: bool = False,
        date: str | None = None,
    ) -> PaginatedResponse[RepertoireResponse]:
        """List repertoires with filters."""
        from app.models.practice import PracticeRepertoire

        query = select(PracticeRepertoire)
        if student_id:
            query = query.where(PracticeRepertoire.student_id == student_id)
        if not include_archived:
            query = query.where(PracticeRepertoire.is_archived == False)  # noqa: E712

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [RepertoireResponse.model_validate(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_repertoire(self, data: RepertoireCreate, current_user: Any) -> RepertoireResponse:
        """Create a repertoire with optional inline sections."""
        from app.models.practice import PracticeRepertoire, PracticeSection

        repertoire = PracticeRepertoire(
            student_id=data.student_id,
            name=data.name,
            start_date=data.start_date or date.today(),
            end_date=data.end_date,
        )
        self.db.add(repertoire)
        await self.db.flush()

        # Create inline sections
        for i, sec_data in enumerate(data.sections):
            section = PracticeSection(
                repertoire_id=repertoire.id,
                piece_name=sec_data.piece_name or "Untitled",
                range_type=sec_data.range_type or "full",
                start_measure=sec_data.start_measure or 1,
                end_measure=sec_data.end_measure or 1,
                is_repeat=sec_data.is_repeat,
                sort_order=i,
            )
            self.db.add(section)

        await self.db.flush()
        await self.db.refresh(repertoire)
        return RepertoireResponse.model_validate(repertoire)

    async def get_repertoires_by_date(
        self, target_date: date, student_id: str | None, current_user: Any
    ) -> list[RepertoireResponse]:
        """Return repertoires active on a specific date."""
        from app.models.practice import PracticeRepertoire

        query = select(PracticeRepertoire).where(
            PracticeRepertoire.is_archived == False,  # noqa: E712
            PracticeRepertoire.start_date <= target_date,
        )
        if student_id:
            query = query.where(PracticeRepertoire.student_id == student_id)

        # end_date can be null (ongoing)
        query = query.where(
            (PracticeRepertoire.end_date >= target_date) | (PracticeRepertoire.end_date == None)  # noqa: E711
        )

        result = await self.db.scalars(query)
        return [RepertoireResponse.model_validate(r) for r in result.all()]

    async def get_repertoire_by_id(self, repertoire_id: str, current_user: Any) -> RepertoireResponse:
        """Return a single repertoire with sections."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        return RepertoireResponse.model_validate(rep)

    async def update_repertoire(
        self, repertoire_id: str, data: RepertoireUpdate, current_user: Any
    ) -> RepertoireResponse:
        """Update repertoire fields."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(rep, key, value)
        await self.db.flush()
        await self.db.refresh(rep)
        return RepertoireResponse.model_validate(rep)

    async def delete_repertoire(self, repertoire_id: str, current_user: Any) -> None:
        """Archive a repertoire."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        rep.is_archived = True
        await self.db.flush()

    # ------------------------------------------------------------------
    # Sections
    # ------------------------------------------------------------------

    async def create_section(self, data: SectionCreate, current_user: Any) -> SectionResponse:
        """Add a section to a repertoire."""
        from app.models.practice import PracticeSection

        section = PracticeSection(
            repertoire_id=data.repertoire_id,
            piece_name=data.piece_name or "Untitled",
            range_type=data.range_type or "full",
            start_measure=data.start_measure or 1,
            end_measure=data.end_measure or 1,
            is_repeat=data.is_repeat,
        )
        self.db.add(section)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def update_section(
        self, section_id: str, data: SectionUpdate, current_user: Any
    ) -> SectionResponse:
        """Update a section."""
        from app.models.practice import PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(section, key, value)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def delete_section(self, section_id: str, current_user: Any) -> None:
        """Delete a section."""
        from app.models.practice import PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")
        await self.db.delete(section)
        await self.db.flush()

    async def toggle_section_complete(
        self, section_id: str, data: SectionCompleteRequest, current_user: Any
    ) -> SectionResponse:
        """Toggle section completion for a given date."""
        from app.models.practice import DailyPracticeStatus, PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")

        # Update or create daily status
        existing = await self.db.scalar(
            select(DailyPracticeStatus).where(
                DailyPracticeStatus.section_id == section_id,
                DailyPracticeStatus.date == data.date,
            )
        )
        if existing:
            existing.is_completed = data.is_completed
        else:
            daily = DailyPracticeStatus(
                section_id=section_id,
                date=data.date,
                is_completed=data.is_completed,
            )
            self.db.add(daily)

        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def add_section_note(
        self, section_id: str, data: SectionNoteCreate, current_user: Any
    ) -> None:
        """Add a practice note to a section."""
        from app.models.practice import PracticeNote

        note = PracticeNote(
            section_id=section_id,
            content=data.content,
        )
        self.db.add(note)
        await self.db.flush()

    # ------------------------------------------------------------------
    # Goals
    # ------------------------------------------------------------------

    async def get_goals(self, student_id: str | None, current_user: Any) -> PracticeGoalResponse:
        """Get practice goals for a student."""
        from app.models.practice import PracticeGoal

        sid = student_id or current_user.id
        goal = await self.db.scalar(
            select(PracticeGoal).where(PracticeGoal.student_id == sid)
        )
        if goal is None:
            return PracticeGoalResponse(student_id=sid)
        return PracticeGoalResponse.model_validate(goal)

    async def set_goals(self, data: PracticeGoalUpdate, current_user: Any) -> PracticeGoalResponse:
        """Create or update practice goals."""
        from app.models.practice import PracticeGoal

        existing = await self.db.scalar(
            select(PracticeGoal).where(PracticeGoal.student_id == data.student_id)
        )
        if existing:
            update_data = data.model_dump(exclude_unset=True, exclude={"student_id"})
            for key, value in update_data.items():
                setattr(existing, key, value)
        else:
            existing = PracticeGoal(
                student_id=data.student_id,
                daily_time_minutes=data.daily_time_minutes,
                daily_section_count=data.daily_section_count,
                weekly_time_minutes=data.weekly_time_minutes,
                weekly_day_count=data.weekly_day_count,
            )
            self.db.add(existing)

        await self.db.flush()
        await self.db.refresh(existing)
        return PracticeGoalResponse.model_validate(existing)

    # ------------------------------------------------------------------
    # Streak & Stats
    # ------------------------------------------------------------------

    async def get_streak(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Get current and longest streak."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            return PracticeStreakResponse()
        return PracticeStreakResponse.model_validate(streak)

    async def update_streak(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Ensure a streak row exists and return it."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            streak = PracticeStreak(student_id=sid)
            self.db.add(streak)
            await self.db.flush()
            await self.db.refresh(streak)
        return PracticeStreakResponse.model_validate(streak)

    async def record_practice(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Record today's practice and update the streak counters."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            streak = PracticeStreak(student_id=sid)
            self.db.add(streak)

        today = date.today()
        if streak.last_practice_date == today:
            await self.db.flush()
            await self.db.refresh(streak)
            return PracticeStreakResponse.model_validate(streak)

        if streak.last_practice_date == today - timedelta(days=1):
            streak.current_streak += 1
        else:
            streak.current_streak = 1

        streak.longest_streak = max(streak.longest_streak, streak.current_streak)
        streak.last_practice_date = today
        streak.total_practice_days += 1
        await self.db.flush()
        await self.db.refresh(streak)
        return PracticeStreakResponse.model_validate(streak)

    async def get_stats(
        self, student_id: str | None, year: int | None, month: int | None, current_user: Any
    ) -> PracticeStatsResponse:
        """Get monthly practice statistics from DailyPracticeStatus."""
        from datetime import date as date_cls

        from app.models.practice import DailyPracticeStatus, PracticeRepertoire, PracticeSection, PracticeStreak

        sid = student_id or current_user.id
        today = date_cls.today()
        target_year = year or today.year
        target_month = month or today.month

        first_day = date_cls(target_year, target_month, 1)
        if target_month == 12:
            last_day = date_cls(target_year + 1, 1, 1)
        else:
            last_day = date_cls(target_year, target_month + 1, 1)

        section_ids_query = (
            select(PracticeSection.id)
            .join(PracticeRepertoire, PracticeSection.repertoire_id == PracticeRepertoire.id)
            .where(PracticeRepertoire.student_id == sid)
        )

        statuses = await self.db.scalars(
            select(DailyPracticeStatus).where(
                DailyPracticeStatus.section_id.in_(section_ids_query),
                DailyPracticeStatus.date >= first_day,
                DailyPracticeStatus.date < last_day,
            )
        )
        all_statuses = statuses.all()

        daily_map: dict[str, DailyStat] = {}
        completed_sections = 0
        for s in all_statuses:
            day_key = s.date.isoformat()
            if day_key not in daily_map:
                daily_map[day_key] = DailyStat()
            if s.is_completed:
                daily_map[day_key].sections_completed += 1
                completed_sections += 1

        total_minutes_result = await self.db.scalar(
            select(func.coalesce(func.sum(PracticeSection.total_practice_seconds), 0))
            .where(
                PracticeSection.repertoire_id.in_(
                    select(PracticeRepertoire.id).where(PracticeRepertoire.student_id == sid)
                )
            )
        )
        total_minutes = (total_minutes_result or 0) // 60

        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )

        return PracticeStatsResponse(
            total_practice_minutes=total_minutes,
            total_practice_days=len(daily_map),
            completed_sections=completed_sections,
            current_streak=streak.current_streak if streak else 0,
            longest_streak=streak.longest_streak if streak else 0,
            daily_stats=daily_map,
        )
