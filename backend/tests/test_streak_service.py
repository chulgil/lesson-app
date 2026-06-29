"""Unit tests for the streak SSOT (docs/specs/practice/streak_ssot.md §1, §5).

Covers the canonical algorithm: KST day unit, strict consecutive-day counting
(no weekend bridge), the today/yesterday grace window, longest run, the
minutes>0 gate, and the UTC->KST day-boundary off-by-one.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime

import pytest

from app.models.practice_log import PracticeLog
from app.services.streak_service import (
    StreakSummary,
    _log_practice_date,
    compute_streak,
    streak_from_logs,
    summarize_practice_days,
    to_kst_date,
)

# Fixed reference: KST "today" = 2026-06-29 (Monday). UTC 03:00 +9h = 12:00 KST.
NOW = datetime(2026, 6, 29, 3, 0, tzinfo=UTC)
SID = "streak-student"


@dataclass
class _FakeLog:
    """Stand-in for a PracticeLog row (no DB needed for pure-function tests)."""

    total_minutes: int
    date: date | None = None
    created_at: datetime | None = None


async def _add_log(db, day: date, *, minutes: int = 30, student_id: str = SID) -> None:
    db.add(PracticeLog(student_id=student_id, date=day, total_minutes=minutes))
    await db.flush()


# ---------------------------------------------------------------------------
# Pure algorithm — summarize_practice_days
# ---------------------------------------------------------------------------


def test_empty_history_is_zero():
    assert summarize_practice_days([], today=date(2026, 6, 29)) == StreakSummary(0, 0, None, 0)


def test_case_a_consecutive_including_today():
    days = [date(2026, 6, 27), date(2026, 6, 28), date(2026, 6, 29)]
    assert summarize_practice_days(days, today=date(2026, 6, 29)) == StreakSummary(
        current=3, longest=3, last_date=date(2026, 6, 29), total_days=3
    )


def test_case_b_grace_ends_yesterday():
    days = [date(2026, 6, 26), date(2026, 6, 27), date(2026, 6, 28)]
    summary = summarize_practice_days(days, today=date(2026, 6, 29))
    assert summary.current == 3  # today empty but yesterday practiced -> grace
    assert summary.last_date == date(2026, 6, 28)


def test_case_c_ends_two_days_ago_is_zero():
    days = [date(2026, 6, 25), date(2026, 6, 26), date(2026, 6, 27)]
    summary = summarize_practice_days(days, today=date(2026, 6, 29))
    assert summary.current == 0
    assert summary.longest == 3


def test_case_d_weekend_gap_does_not_bridge():
    # Mon..Fri (22-26) then today Mon (29); Sat 27 / Sun 28 skipped.
    days = [date(2026, 6, d) for d in (22, 23, 24, 25, 26, 29)]
    summary = summarize_practice_days(days, today=date(2026, 6, 29))
    assert summary.current == 1  # 29 only; weekend gap breaks the run
    assert summary.longest == 5  # the Mon-Fri block, NOT bridged to 6
    assert summary.total_days == 6


def test_case_e_longest_greater_than_current():
    days = [date(2026, 6, d) for d in (1, 2, 3, 4, 5)] + [date(2026, 6, 29)]
    summary = summarize_practice_days(days, today=date(2026, 6, 29))
    assert summary.longest == 5
    assert summary.current == 1
    assert summary.longest > summary.current


# ---------------------------------------------------------------------------
# Minutes gate + KST boundary — streak_from_logs / helpers
# ---------------------------------------------------------------------------


def test_case_f_zero_minute_logs_only():
    logs = [_FakeLog(total_minutes=0, date=date(2026, 6, d)) for d in (27, 28, 29)]
    assert streak_from_logs(logs, now=NOW) == StreakSummary(0, 0, None, 0)


def test_case_g_kst_boundary_to_kst_date():
    # UTC 23:30 belongs to the NEXT KST day (08:30).
    assert to_kst_date(datetime(2026, 6, 28, 23, 30, tzinfo=UTC)) == date(2026, 6, 29)


def test_case_g_log_without_date_falls_back_to_created_at_in_kst():
    log = _FakeLog(total_minutes=30, date=None, created_at=datetime(2026, 6, 28, 23, 30, tzinfo=UTC))
    assert _log_practice_date(log) == date(2026, 6, 29)
    summary = streak_from_logs([log], now=NOW)
    assert summary.last_date == date(2026, 6, 29)
    assert summary.current == 1  # counts as yesterday (grace) relative to 2026-06-29


# ---------------------------------------------------------------------------
# DB-backed compute_streak (async, SQLite)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_compute_streak_db_consecutive_including_today(db_session):
    for day in (date(2026, 6, 27), date(2026, 6, 28), date(2026, 6, 29)):
        await _add_log(db_session, day)
    summary = await compute_streak(db_session, SID, now=NOW)
    assert summary == StreakSummary(current=3, longest=3, last_date=date(2026, 6, 29), total_days=3)


@pytest.mark.asyncio
async def test_compute_streak_db_grace_window(db_session):
    for day in (date(2026, 6, 26), date(2026, 6, 27), date(2026, 6, 28)):
        await _add_log(db_session, day)
    summary = await compute_streak(db_session, SID, now=NOW)
    assert summary.current == 3
    assert summary.last_date == date(2026, 6, 28)


@pytest.mark.asyncio
async def test_compute_streak_db_only_other_students_isolated(db_session):
    await _add_log(db_session, date(2026, 6, 29), student_id="someone-else")
    summary = await compute_streak(db_session, SID, now=NOW)
    assert summary == StreakSummary(0, 0, None, 0)


@pytest.mark.asyncio
async def test_compute_streak_today_boundary_uses_kst_not_utc(db_session):
    # now = 2026-06-28 16:00 UTC -> KST 2026-06-29 01:00 -> today_kst = 2026-06-29.
    # Last practice 2026-06-27 is then TWO days before KST today -> current = 0.
    # A naive UTC implementation (today = 2026-06-28) would wrongly grace it to 1.
    await _add_log(db_session, date(2026, 6, 27))
    now_utc = datetime(2026, 6, 28, 16, 0, tzinfo=UTC)
    summary = await compute_streak(db_session, SID, now=now_utc)
    assert summary.current == 0
    assert summary.longest == 1
    assert summary.last_date == date(2026, 6, 27)
