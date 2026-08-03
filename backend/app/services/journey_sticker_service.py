"""Journey sticker catalog service (P3b, doc 46 §5).

Pure computed aggregation over existing log tables — deliberately NOT a new
accrual table. Every read re-derives the catalog from practice_logs,
practice_journal_volumes (BoundVolume — 곡 제본), practice_recordings, and the
streak SSOT (``streak_service.compute_streak``). This mirrors the ESL app's
achievement model (realtime aggregation, retroactive — a student who already
practiced before this shipped sees correct progress immediately) but the
catalog itself is repertoire-based (user-created pieces), not a fixed
content-consumption curriculum.

Tier ladders and target thresholds are the ones enumerated in the harness
brief (doc 46 §5.1). Metrics with no server-observable signal or no assigned
tier target (예: 도장 반복 횟수, 첫 발표) are intentionally omitted — see the
service module docstring in the PR description for the drop list.
"""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.streak_service import compute_streak
from app.services.teacher_id_resolver import resolve_teacher_id

# (tier, key suffix, target) ladders — tier is the 1-based position FE uses
# for ring styling; key suffix keeps sticker keys human-readable (hours for
# the minutes ladder) instead of raw minute counts.
_PRACTICE_MINUTES_TIERS: list[tuple[int, str, int]] = [
    (1, "10h", 10 * 60),
    (2, "50h", 50 * 60),
    (3, "200h", 200 * 60),
    (4, "1000h", 1000 * 60),
]
_PRACTICE_DAYS_TIERS: list[tuple[int, str, int]] = [(1, "30", 30), (2, "100", 100), (3, "365", 365)]
_JOURNEY_BOUND_TIERS: list[tuple[int, str, int]] = [(1, "1", 1), (2, "5", 5), (3, "20", 20), (4, "50", 50)]
_STREAK_TIERS: list[tuple[int, str, int]] = [(1, "7", 7), (2, "30", 30), (3, "100", 100), (4, "365", 365)]
_GROWTH_RECORDINGS_TIERS: list[tuple[int, str, int]] = [(1, "10", 10), (2, "50", 50), (3, "200", 200)]


class JourneyStickerService:
    """Compute the journey sticker catalog for a student (no persistence)."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_catalog(self, student_id: str, current_user: Any) -> dict[str, Any]:
        """Return the full computed sticker catalog for a student."""
        student = await self._assert_student_access(student_id, current_user)

        total_minutes, practiced_days = await self._practice_totals(student_id)
        bound_count = await self._bound_volume_count(student_id)
        registered_piece_count = await self._registered_piece_count(student_id)
        streak = await compute_streak(self.db, student_id)
        recording_count = await self._recording_count(student)

        stickers: list[dict[str, Any]] = [
            *self._ladder(
                key_prefix="practice_minutes",
                family="practice",
                metric="practice_minutes",
                tiers=_PRACTICE_MINUTES_TIERS,
                current=total_minutes,
                unit="minutes",
            ),
            *self._ladder(
                key_prefix="practice_days",
                family="practice",
                metric="practice_days",
                tiers=_PRACTICE_DAYS_TIERS,
                current=practiced_days,
                unit="days",
            ),
            self._entry(
                key="journey_first_piece",
                family="journey",
                metric="journey_first_piece",
                tier=1,
                target=1,
                current=registered_piece_count,
                unit="count",
            ),
            *self._ladder(
                key_prefix="journey_bound",
                family="journey",
                metric="journey_bound_volumes",
                tiers=_JOURNEY_BOUND_TIERS,
                current=bound_count,
                unit="count",
            ),
            *self._ladder(
                key_prefix="streak",
                family="streak",
                metric="streak_days",
                tiers=_STREAK_TIERS,
                current=streak.longest,
                unit="days",
            ),
            *self._ladder(
                key_prefix="growth_recordings",
                family="growth",
                metric="growth_recordings",
                tiers=_GROWTH_RECORDINGS_TIERS,
                current=recording_count,
                unit="count",
            ),
        ]

        return {"student_id": student_id, "stickers": stickers}

    # ------------------------------------------------------------------
    # Aggregation queries
    # ------------------------------------------------------------------

    async def _practice_totals(self, student_id: str) -> tuple[int, int]:
        """Return (total accumulated minutes, distinct practiced days)."""
        from app.models.practice_log import PracticeLog

        rows = await self.db.scalars(select(PracticeLog).where(PracticeLog.student_id == student_id))
        total_minutes = 0
        practiced_days: set[Any] = set()
        for log in rows.all():
            minutes = log.total_minutes or 0
            total_minutes += minutes
            if minutes > 0:
                practiced_days.add(log.date)
        return total_minutes, len(practiced_days)

    async def _bound_volume_count(self, student_id: str) -> int:
        """Count 제본 volumes (completed pieces) for the student."""
        from app.models.practice_journal import BoundVolume

        count = await self.db.scalar(select(func.count()).where(BoundVolume.child_profile_id == student_id))
        return count or 0

    async def _registered_piece_count(self, student_id: str) -> int:
        """Count distinct pieces the student has ever registered into a repertoire."""
        from app.models.practice import PracticeRepertoire, PracticeSection

        count = await self.db.scalar(
            select(func.count(func.distinct(PracticeSection.piece_name)))
            .select_from(PracticeSection)
            .join(PracticeRepertoire, PracticeSection.repertoire_id == PracticeRepertoire.id)
            .where(PracticeRepertoire.student_id == student_id)
        )
        return count or 0

    async def _recording_count(self, student: Any) -> int:
        """Count practice recordings uploaded by the student.

        WIRE GOTCHA: ``PracticeRecording.student_id`` actually stores the
        uploader's ``User.id`` (see ``RecordingService.upload`` —
        ``student_id=user.id``), not ``Student.id``. Every other table this
        service reads (practice_logs, practice_journal_volumes,
        practice_repertoires) keys on ``Student.id``. A student with no
        linked user account (``Student.user_id is None``) cannot have
        uploaded any recordings, so the count is 0 in that case.
        """
        from app.models.practice import PracticeRecording

        user_id = getattr(student, "user_id", None)
        if user_id is None:
            return 0
        count = await self.db.scalar(select(func.count()).where(PracticeRecording.student_id == user_id))
        return count or 0

    # ------------------------------------------------------------------
    # Catalog entry helpers
    # ------------------------------------------------------------------

    def _ladder(
        self,
        *,
        key_prefix: str,
        family: str,
        metric: str,
        tiers: list[tuple[int, str, int]],
        current: int,
        unit: str,
    ) -> list[dict[str, Any]]:
        return [
            self._entry(
                key=f"{key_prefix}_{suffix}",
                family=family,
                metric=metric,
                tier=tier,
                target=target,
                current=current,
                unit=unit,
            )
            for tier, suffix, target in tiers
        ]

    def _entry(
        self,
        *,
        key: str,
        family: str,
        metric: str,
        tier: int,
        target: int,
        current: int,
        unit: str,
    ) -> dict[str, Any]:
        return {
            "key": key,
            "family": family,
            "metric": metric,
            "tier": tier,
            "target": target,
            "current": current,
            "achieved": current >= target,
            "unit": unit,
        }

    # ------------------------------------------------------------------
    # Access control (mirrors GamificationService._assert_student_access)
    # ------------------------------------------------------------------

    async def _assert_student_access(self, student_id: str, current_user: Any) -> Any:
        """Enforce ownership; reject access to a non-existent student."""
        from app.models.student import Student

        student = await self.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        role = getattr(current_user, "role", None)
        role_value = getattr(role, "value", role)
        if role_value == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if student.teacher_id == teacher_id:
                return student
        elif role_value == "student" and student.user_id == current_user.id:
            return student

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Student access denied")
