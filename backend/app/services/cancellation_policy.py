"""Cancellation deadline policy — server-side timing verdict (#1241).

``LessonPolicy.cancellation_deadline_hours`` used to be a setting with no
enforcement: whether a cancellation counted as "late" was whatever status the
client sent, so the deadline had no effect and a client could always avoid the
penalty. The server owns the timing verdict now; the client shows the same
numbers as a hint before the teacher acts (``GET /lessons/{id}/cancellation-policy``).

Only the *timing* classification is server-owned. Who cancelled and why
(no-show, teacher cancel, mutual) stays the teacher's judgement.
"""

from __future__ import annotations

from datetime import date as _date
from datetime import datetime, time, timedelta

from app.core.timezones import KST

DEFAULT_CANCEL_DEADLINE_HOURS = 24

#: Student-cancel statuses whose split is purely a timing question.
ADVANCE_CANCEL_STATUS = "cancelledByStudentAdvance"
LATE_CANCEL_STATUS = "cancelledByStudentLate"
TIMING_DECIDED_STATUSES = frozenset({ADVANCE_CANCEL_STATUS, LATE_CANCEL_STATUS})


def lesson_start_kst(lesson_date: _date, start_time: str | None) -> datetime | None:
    """Lesson start as a KST-aware datetime, or None if unparseable.

    ``date`` + ``start_time`` are stored as local wall-clock (project timezone
    rule: DB stores UTC timestamps, but lesson schedule fields are KST-local).
    """
    if start_time is None:
        return None
    try:
        hh, mm = (int(part) for part in start_time.split(":"))
        return datetime.combine(lesson_date, time(hour=hh, minute=mm), tzinfo=KST)
    except (ValueError, TypeError):
        return None


def cancel_deadline_at(lesson_date: _date, start_time: str | None, deadline_hours: int) -> datetime | None:
    """The moment after which a cancellation counts as late."""
    start = lesson_start_kst(lesson_date, start_time)
    if start is None:
        return None
    return start - timedelta(hours=max(0, deadline_hours))


def resolve_cancel_timing(
    *,
    lesson_date: _date,
    start_time: str | None,
    deadline_hours: int,
    at: datetime,
) -> bool:
    """True when cancelling at ``at`` is past the deadline (= late).

    The boundary itself is safe (cancelling exactly at the deadline is advance),
    and an unparseable schedule yields False — an ambiguous case must not create
    a penalty the teacher never configured.
    """
    deadline = cancel_deadline_at(lesson_date, start_time, deadline_hours)
    if deadline is None:
        return False
    return at.astimezone(KST) > deadline
