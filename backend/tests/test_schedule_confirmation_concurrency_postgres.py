"""Postgres concurrency gate: double-booking race in schedule confirmation.

``ScheduleConfirmationService.check_time_conflict`` is a read-only overlap scan
run before the booking-creating paths (``confirm_card`` /
``update_card_status`` -> ``_create_bookings_for_subscription`` and
``create_standalone_regular_lessons``) INSERT ``LessonBooking``/``Lesson``
rows. Without a lock, two concurrent requests for the same teacher/slot can
both pass the conflict check (neither sees the other's uncommitted INSERT)
and both create a booking for the identical slot — a double booking, most
likely on 선착순 즉시확정 (first-come-first-served) slots.

The default test suite runs on SQLite (conftest.py), where two truly
concurrent transactions aren't meaningfully reproducible (single-writer, no
real MVCC snapshot isolation across connections) — so this race is invisible
there. This module drives two independent connections against a real
Postgres and asserts no slot ends up with more than one booking.

Runs against ``ALEMBIC_TEST_DATABASE_URL`` (a Postgres DSN) or testcontainers,
mirroring ``test_date_filter_postgres.py``. Skipped when neither is available.
"""

from __future__ import annotations

import asyncio
import contextlib
import datetime as dt
import os
import uuid
from collections import Counter
from types import SimpleNamespace

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.base import Base

pytestmark = pytest.mark.migration  # group with the docker/Postgres-gated tests

_ENV_DSN = os.environ.get("ALEMBIC_TEST_DATABASE_URL")

try:
    from testcontainers.postgres import PostgresContainer

    _HAS_TC = True
except Exception:  # pragma: no cover - dependency/platform unsupported
    _HAS_TC = False


def _to_async(url: str) -> str:
    """Swap a sync psycopg/libpq DSN to the asyncpg driver."""
    for sync_driver in ("postgresql+psycopg2://", "postgresql+psycopg://", "postgresql://"):
        if url.startswith(sync_driver):
            return "postgresql+asyncpg://" + url[len(sync_driver) :]
    return url


@contextlib.asynccontextmanager
async def _pg_engine():
    if _ENV_DSN:
        engine = create_async_engine(_to_async(_ENV_DSN))
        try:
            yield engine
        finally:
            await engine.dispose()
    elif _HAS_TC:
        with PostgresContainer("postgres:16-alpine") as pg:
            engine = create_async_engine(_to_async(pg.get_connection_url()))
            try:
                yield engine
            finally:
                await engine.dispose()
    else:  # pragma: no cover - gated out
        pytest.skip("set ALEMBIC_TEST_DATABASE_URL or install testcontainers")


class _FakeUser:
    def __init__(self, uid: str):
        self.id = uid
        self.role = "teacher"


def _standalone_data(
    *, teacher_id: str, student_id: str, student_name: str, day_of_week: int, start_time: str, duration: int
):
    """Minimal stand-in for the ``BookingCreate``-shaped schema object that
    ``create_standalone_regular_lessons`` reads (see its call site in
    ``schedule_service.py``): teacher_id, student_id, student_name,
    fixed_time_slots, duration, subscription_id, instrument, lesson_type,
    scheduled_date.
    """
    return SimpleNamespace(
        teacher_id=teacher_id,
        student_id=student_id,
        student_name=student_name,
        fixed_time_slots=[{"day_of_week": day_of_week, "start_time": start_time, "duration_minutes": duration}],
        duration=duration,
        subscription_id=None,
        instrument=None,
        lesson_type="regular",
        scheduled_date=None,
    )


@pytest.mark.asyncio
@pytest.mark.skipif(
    not (_ENV_DSN or _HAS_TC),
    reason="set ALEMBIC_TEST_DATABASE_URL (Postgres DSN) or install testcontainers",
)
async def test_concurrent_standalone_registration_does_not_double_book():
    """Two concurrent ``create_standalone_regular_lessons`` calls for the same
    teacher + identical single slot must not both land a booking on that slot.

    RED (no lock): both sessions run ``check_time_conflict`` before either
    commits -> neither sees the other's row -> both INSERT -> the raced slot
    ends up with 2 bookings.

    GREEN (with ``_acquire_teacher_booking_lock``): the second caller blocks on
    ``pg_advisory_xact_lock`` until the first commits, then re-checks and sees
    the conflict -> its occurrence is pushed to the next free week's slot
    instead (existing `_generate_recurring_lessons` push-forward behavior) ->
    the raced slot keeps exactly 1 booking.
    """
    import app.models  # noqa: F401  # populate Base.metadata
    from app.models.schedule import LessonBooking
    from app.services.schedule_confirmation_service import ScheduleConfirmationService

    async with _pg_engine() as engine:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        session_maker = async_sessionmaker(engine, expire_on_commit=False)

        # teacher_id/student_id are String(36) columns — plain uuid4 str is
        # exactly 36 chars, leaving no room for a descriptive prefix.
        teacher_id = str(uuid.uuid4())
        student_a = str(uuid.uuid4())
        student_b = str(uuid.uuid4())

        today = dt.date.today()
        day_of_week = today.weekday()
        start_time = "14:00"
        duration = 60

        data_a = _standalone_data(
            teacher_id=teacher_id,
            student_id=student_a,
            student_name="Race Student A",
            day_of_week=day_of_week,
            start_time=start_time,
            duration=duration,
        )
        data_b = _standalone_data(
            teacher_id=teacher_id,
            student_id=student_b,
            student_name="Race Student B",
            day_of_week=day_of_week,
            start_time=start_time,
            duration=duration,
        )

        async def _confirm(data: SimpleNamespace, actor_id: str) -> list:
            async with session_maker() as session:
                service = ScheduleConfirmationService(session)
                created, _requested = await service.create_standalone_regular_lessons(data, _FakeUser(actor_id))
                await session.commit()
                return created

        # Fire both requests concurrently — this is the actual race, not a
        # simulation: two independent AsyncSession/connections, two independent
        # transactions, scheduled onto the event loop together.
        await asyncio.gather(_confirm(data_a, student_a), _confirm(data_b, student_b))

        async with session_maker() as verify_session:
            rows = (
                await verify_session.scalars(select(LessonBooking).where(LessonBooking.teacher_id == teacher_id))
            ).all()

        assert rows, "expected at least one booking to be created"

        slot_counts = Counter((booking.scheduled_date, booking.scheduled_time) for booking in rows)
        duplicated = {slot: n for slot, n in slot_counts.items() if n > 1}
        assert not duplicated, f"double-booking race reproduced — slot(s) with >1 booking: {duplicated}"

        # The raced slot (day_of_week today, start_time) must have exactly one
        # booking — one of the two students, not both.
        days_ahead = day_of_week - today.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        raced_date = today + dt.timedelta(days=days_ahead)
        raced_slot_bookings = [b for b in rows if b.scheduled_date == raced_date and b.scheduled_time == start_time]
        assert len(raced_slot_bookings) == 1, (
            f"expected exactly 1 booking on the raced slot {raced_date} {start_time}, got {len(raced_slot_bookings)}"
        )
