"""Postgres regression gate: Date column vs string query-param comparison.

The SQLite suite (conftest) is loosely typed and silently accepts
``Date >= 'string'``, so it never caught that Postgres has no
``date >= character varying`` operator. Comparing a ``Date`` column to an ISO
date *string* raised ``asyncpg.UndefinedFunctionError`` → HTTP 500 on the
lessons / parent-lessons / bookings list endpoints whenever a date filter was
applied (beta 2026-06-27: ``GET /api/v1/lessons?date_from=...&date_to=...`` → 500).

Fix: ``app.core.date_utils.to_date`` coerces the string to a ``date`` before the
filter. This test runs the real comparison against Postgres to prove the raw
string fails and ``to_date()`` works.

Runs against either ``ALEMBIC_TEST_DATABASE_URL`` (a Postgres DSN, same gate as
the alembic validation tests) or a ``testcontainers`` Postgres. Skips if neither
is available.
"""

from __future__ import annotations

import contextlib
import os

import pytest
from sqlalchemy import func, select
from sqlalchemy.exc import ProgrammingError
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.date_utils import to_date
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


def _count_lessons_from(date_value):
    from app.models.lesson import Lesson

    inner = select(Lesson).where(Lesson.date >= date_value).subquery()
    return select(func.count()).select_from(inner)


@pytest.mark.asyncio
@pytest.mark.skipif(
    not (_ENV_DSN or _HAS_TC),
    reason="set ALEMBIC_TEST_DATABASE_URL (Postgres DSN) or install testcontainers",
)
async def test_date_column_vs_string_param_on_postgres():
    import app.models  # noqa: F401  # populate Base.metadata

    async with _pg_engine() as engine:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        session_maker = async_sessionmaker(engine, expire_on_commit=False)

        # RED: a raw string param has no `date >= character varying` operator in
        # Postgres — the query fails at plan time (no rows required).
        async with session_maker() as session:
            with pytest.raises(ProgrammingError):
                await session.scalar(_count_lessons_from("2026-06-22"))

        # GREEN: to_date() coerces to a `date`, giving a valid `date >= date`.
        async with session_maker() as session:
            count = await session.scalar(_count_lessons_from(to_date("2026-06-22")))
            assert count == 0
