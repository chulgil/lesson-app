"""Practice Loop Stats service — #512.

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4/§5.

Responsibilities:
- Student sync: upsert per (student, section). Server keeps max(stored, incoming)
  on the cumulative ``repeat_count`` so duplicate or out-of-order uploads stay
  idempotent.
- Teacher reads:
    * per-student rows scoped by an optional time window (1주 / 1개월)
    * per-teacher roll-up across all of the teacher's students

The service is stateless (constructor takes ``AsyncSession``) to match the
existing make-up credit / vacation service shape.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.practice import PracticeSection
from app.models.practice_loop_stats import PracticeLoopStats
from app.models.student import Student
from app.schemas.practice_loop_stats import (
    PracticeLoopStatsListResponse,
    PracticeLoopStatsRow,
    PracticeLoopStatsStudentSummary,
    PracticeLoopStatsSummaryResponse,
    PracticeLoopStatsSyncEntry,
    PracticeLoopStatsSyncResult,
    StatsWindow,
)


def _utcnow() -> datetime:
    return datetime.now(UTC)


def _window_start(window: StatsWindow, now: datetime | None = None) -> datetime:
    """Translate the UI window toggle into a cutoff timestamp.

    Spec §4.3 — 1주 / 1개월 토글.
    """
    base = now or _utcnow()
    if window is StatsWindow.weekly:
        return base - timedelta(days=7)
    # monthly
    return base - timedelta(days=30)


class PracticeLoopStatsService:
    """CRUD + sync for ``PracticeLoopStats``."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Student sync
    # ------------------------------------------------------------------

    async def sync(
        self,
        *,
        student_id: str,
        teacher_id: str,
        entries: list[PracticeLoopStatsSyncEntry],
    ) -> PracticeLoopStatsSyncResult:
        """Apply a batch of (section, count) updates for one student.

        Behaviour (spec §5):
        - Reject entries pointing at sections that do not exist.
        - Upsert by (student_id, section_id) — server stores
          ``max(stored, incoming)`` on ``repeat_count``.
        - ``last_played_at`` is advanced to the latest known timestamp.
        - Idempotent: the same payload can be retried safely.
        """
        result = PracticeLoopStatsSyncResult()

        for entry in entries:
            section_row = await self.db.scalar(select(PracticeSection).where(PracticeSection.id == entry.section_id))
            if section_row is None:
                result.rejected += 1
                continue

            existing = await self.db.scalar(
                select(PracticeLoopStats).where(
                    PracticeLoopStats.student_id == student_id,
                    PracticeLoopStats.section_id == entry.section_id,
                )
            )

            if existing is None:
                self.db.add(
                    PracticeLoopStats(
                        student_id=student_id,
                        teacher_id=teacher_id,
                        section_id=entry.section_id,
                        repeat_count=entry.repeat_count,
                        last_played_at=entry.last_played_at,
                    )
                )
                result.upserted += 1
                continue

            # Idempotent merge — never decrement, never go back in time.
            # Normalise both sides to UTC-aware so SQLite (naive) and
            # PostgreSQL (aware) behave identically.
            stored_played = existing.last_played_at
            if stored_played.tzinfo is None:
                stored_played = stored_played.replace(tzinfo=UTC)
            entry_played = entry.last_played_at
            if entry_played.tzinfo is None:
                entry_played = entry_played.replace(tzinfo=UTC)

            incoming_count = max(existing.repeat_count, entry.repeat_count)
            incoming_played = max(stored_played, entry_played)

            if incoming_count == existing.repeat_count and incoming_played == stored_played:
                result.skipped += 1
                continue

            existing.repeat_count = incoming_count
            existing.last_played_at = incoming_played
            # ``teacher_id`` may legitimately change if a student moves between
            # teachers; honour whatever the most recent sync says.
            existing.teacher_id = teacher_id
            result.upserted += 1

        await self.db.flush()
        return result

    # ------------------------------------------------------------------
    # Teacher reads — per-student rows
    # ------------------------------------------------------------------

    async def list_for_student(
        self,
        *,
        teacher_id: str,
        student_id: str,
        window: StatsWindow,
    ) -> PracticeLoopStatsListResponse:
        """All section rows for one student inside the chosen time window.

        Spec §4 (선생님 통계). Caller is expected to have already verified the
        teacher actually owns the student (see api layer).
        """
        cutoff = _window_start(window)

        stmt = (
            select(PracticeLoopStats)
            .where(
                PracticeLoopStats.student_id == student_id,
                PracticeLoopStats.teacher_id == teacher_id,
                PracticeLoopStats.last_played_at >= cutoff,
            )
            .order_by(PracticeLoopStats.repeat_count.desc())
        )
        rows_db = (await self.db.execute(stmt)).scalars().all()

        # Hydrate piece/section labels in one round-trip per section id so the
        # UI does not need an additional /sections lookup.
        section_ids = [r.section_id for r in rows_db]
        sections_by_id: dict[str, PracticeSection] = {}
        if section_ids:
            section_rows = (
                (await self.db.execute(select(PracticeSection).where(PracticeSection.id.in_(section_ids))))
                .scalars()
                .all()
            )
            sections_by_id = {s.id: s for s in section_rows}

        rows: list[PracticeLoopStatsRow] = []
        total = 0
        for row in rows_db:
            section = sections_by_id.get(row.section_id)
            rows.append(
                PracticeLoopStatsRow(
                    id=row.id,
                    student_id=row.student_id,
                    teacher_id=row.teacher_id,
                    section_id=row.section_id,
                    repeat_count=row.repeat_count,
                    last_played_at=row.last_played_at,
                    created_at=row.created_at,
                    updated_at=row.updated_at,
                    piece_name=section.piece_name if section is not None else None,
                    section_name=section.section_name if section is not None else None,
                )
            )
            total += row.repeat_count

        return PracticeLoopStatsListResponse(
            student_id=student_id,
            window=window,
            total_repeats=total,
            rows=rows,
        )

    # ------------------------------------------------------------------
    # Teacher reads — per-teacher dashboard roll-up
    # ------------------------------------------------------------------

    async def summary_for_teacher(
        self,
        *,
        teacher_id: str,
        window: StatsWindow,
    ) -> PracticeLoopStatsSummaryResponse:
        """Roll-up across all linked students for the dashboard entry card.

        Spec §4.4 — 학생별 진척도 카드 (총 반복 횟수 + 최근 연습).
        """
        cutoff = _window_start(window)

        stmt = select(PracticeLoopStats).where(
            PracticeLoopStats.teacher_id == teacher_id,
            PracticeLoopStats.last_played_at >= cutoff,
        )
        rows = (await self.db.execute(stmt)).scalars().all()

        # Group by student.
        by_student: dict[str, list[PracticeLoopStats]] = {}
        for row in rows:
            by_student.setdefault(row.student_id, []).append(row)

        # Pull student display names (avoid N+1 by batching).
        student_ids = list(by_student.keys())
        students_by_id: dict[str, Student] = {}
        if student_ids:
            student_rows = (await self.db.execute(select(Student).where(Student.id.in_(student_ids)))).scalars().all()
            students_by_id = {s.id: s for s in student_rows}

        summaries: list[PracticeLoopStatsStudentSummary] = []
        for sid, items in by_student.items():
            total = sum(item.repeat_count for item in items)
            last = max(item.last_played_at for item in items)
            student = students_by_id.get(sid)
            summaries.append(
                PracticeLoopStatsStudentSummary(
                    student_id=sid,
                    student_name=student.name if student is not None else None,
                    total_repeats=total,
                    last_played_at=last,
                )
            )

        # Stable ordering — most active first, ties broken by student id.
        summaries.sort(key=lambda s: (-s.total_repeats, s.student_id))

        return PracticeLoopStatsSummaryResponse(
            teacher_id=teacher_id,
            window=window,
            students=summaries,
        )
