"""Practice streak — single source of truth (PR-A).

Recomputes the practice streak from ``practice_logs`` on every read
(self-healing), per ``docs/specs/practice/streak_ssot.md`` §1. The day unit is
the KST (UTC+9) calendar date — never the server's naive ``date.today()``. The
legacy ``practice_streaks`` counter table is no longer read by any output.
"""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# KST is a fixed UTC+9 offset (no DST), so a static timezone is sufficient.
from app.core.timezones import KST


@dataclass(frozen=True)
class StreakSummary:
    """Authoritative streak values for a student."""

    current: int
    longest: int
    last_date: date | None
    total_days: int


def to_kst_date(value: datetime) -> date:
    """Return the KST calendar date for a UTC-aware (or naive-UTC) datetime.

    A timestamp at ``UTC 23:30`` falls on the *next* KST day (08:30) — this is
    the off-by-one that the legacy UTC day-boundary code got wrong.
    """
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(KST).date()


def _log_practice_date(log: Any) -> date | None:
    """Resolve the KST practice day for a log row.

    The ``date`` column is the authoritative practice day (user-selected, also
    used for backfill). When absent, fall back to the creation timestamp
    converted to KST.
    """
    log_date = getattr(log, "date", None)
    if log_date is not None:
        return log_date
    created = getattr(log, "created_at", None)
    if created is not None:
        return to_kst_date(created)
    return None


def summarize_practice_days(days: Iterable[date], *, today: date) -> StreakSummary:
    """Compute streak values from a set of practiced KST dates (spec §1).

    - ``current``: consecutive days counted backward from the most recent
      practiced day; broken by a single gap (no weekend bridge). Grace: if the
      most recent day is today or yesterday it counts, otherwise ``current`` is 0.
    - ``longest``: longest run of consecutive days over all history.
    """
    unique = sorted(set(days))
    if not unique:
        return StreakSummary(current=0, longest=0, last_date=None, total_days=0)

    last = unique[-1]
    if last < today - timedelta(days=1):
        current = 0
    else:
        present = set(unique)
        current = 0
        cursor = last
        while cursor in present:
            current += 1
            cursor -= timedelta(days=1)

    longest = run = 1
    for previous, current_day in zip(unique, unique[1:]):
        run = run + 1 if (current_day - previous) == timedelta(days=1) else 1
        longest = max(longest, run)

    return StreakSummary(current=current, longest=longest, last_date=last, total_days=len(unique))


def streak_from_logs(logs: Iterable[Any], *, now: datetime | None = None) -> StreakSummary:
    """Compute a streak from log rows (minutes-gated, KST day bucketing)."""
    today = to_kst_date(now or datetime.now(UTC))
    days: set[date] = set()
    for log in logs:
        minutes = getattr(log, "total_minutes", 0) or 0
        if minutes <= 0:
            continue
        day = _log_practice_date(log)
        if day is not None:
            days.add(day)
    return summarize_practice_days(days, today=today)


async def compute_streak(
    db: AsyncSession,
    student_id: str,
    *,
    now: datetime | None = None,
) -> StreakSummary:
    """Recompute the authoritative streak for a student from ``practice_logs``."""
    from app.models.practice_log import PracticeLog

    rows = await db.scalars(select(PracticeLog).where(PracticeLog.student_id == student_id))
    return streak_from_logs(rows.all(), now=now)
