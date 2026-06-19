"""Validate the alembic migration chain against a REAL Postgres — the gap that
let two production 500s through (long revision id overflowing
``alembic_version.version_num``; ``requesteventtype`` missing enum values).

The default test suite builds the schema with ``metadata.create_all`` on SQLite,
which silently ignores VARCHAR length and stores enums as TEXT — so neither class
of bug is observable there. This module runs the actual migrations on Postgres
and asserts the resulting schema matches the models.

Gated on ``ALEMBIC_TEST_DATABASE_URL`` (a Postgres DSN pointing at a throwaway/CI
database). Skipped when unset so local SQLite runs are unaffected. CI should start
a Postgres service and set the env var.
"""

from __future__ import annotations

import asyncio
import os
import subprocess
from pathlib import Path

import pytest

PG_DSN = os.environ.get("ALEMBIC_TEST_DATABASE_URL")

pytestmark = pytest.mark.skipif(
    not PG_DSN,
    reason="set ALEMBIC_TEST_DATABASE_URL (Postgres DSN) to run migration validation",
)

_BACKEND_ROOT = Path(__file__).resolve().parents[1]


def _asyncpg_dsn(dsn: str) -> str:
    """asyncpg wants a plain ``postgresql://`` DSN (strip SQLAlchemy driver suffix)."""
    return dsn.replace("postgresql+asyncpg://", "postgresql://").replace("postgresql+psycopg://", "postgresql://")


@pytest.fixture(scope="module")
def migrated_pg() -> str:
    """Run ``alembic upgrade head`` against the target Postgres once per module.

    A non-zero exit (e.g. a revision id overflowing ``alembic_version.version_num``)
    fails here, surfacing chain breaks that SQLite create_all hides.
    """
    env = {**os.environ, "ALEMBIC_DATABASE_URL": PG_DSN}
    result = subprocess.run(
        ["uv", "run", "alembic", "upgrade", "head"],
        cwd=_BACKEND_ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (
        "alembic upgrade head FAILED on Postgres — the migration chain does not "
        f"apply cleanly:\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}"
    )
    return PG_DSN


def _native_enum_columns() -> dict[str, set[str]]:
    """Map each native Postgres enum *type name* -> the exact set of string values
    SQLAlchemy will bind for it, by introspecting the actual mapped columns.

    Using ``Base.metadata`` (not class-name guessing) avoids false matches when two
    model enums share a class name or a name coincidentally collides with an
    unrelated Postgres type. ``col.type.enums`` is precisely what SQLAlchemy sends
    to the DB (member names, or ``.value`` when ``values_callable`` is set), so it
    is exactly what the Postgres enum type must contain.
    """
    import sqlalchemy as sa

    import app.models  # noqa: F401  populate Base.metadata
    from app.models.base import Base

    expected: dict[str, set[str]] = {}
    for table in Base.metadata.tables.values():
        for col in table.columns:
            col_type = col.type
            if isinstance(col_type, sa.Enum) and getattr(col_type, "native_enum", False) and col_type.name:
                expected.setdefault(col_type.name, set()).update(col_type.enums)
    return expected


def _db_enum_values(dsn: str) -> dict[str, set[str]]:
    """Map every Postgres enum type name -> set of its labels."""
    import asyncpg

    async def _fetch() -> dict[str, set[str]]:
        conn = await asyncpg.connect(_asyncpg_dsn(dsn))
        try:
            rows = await conn.fetch(
                "SELECT t.typname AS typname, e.enumlabel AS label FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid"
            )
        finally:
            await conn.close()
        result: dict[str, set[str]] = {}
        for row in rows:
            result.setdefault(row["typname"], set()).add(row["label"])
        return result

    return asyncio.run(_fetch())


def test_alembic_chain_applies_on_postgres(migrated_pg: str) -> None:
    """The whole chain applies to head on Postgres (asserted by the fixture)."""
    assert migrated_pg


def test_model_enum_values_present_in_db(migrated_pg: str) -> None:
    """Every model enum value must exist in its Postgres enum type.

    Catches "added an enum member to the model/queries but forgot the
    ``ALTER TYPE ... ADD VALUE`` migration" — which ``alembic check`` does NOT
    detect and which 500s any query binding the new value.
    """
    expected = _native_enum_columns()
    db_enums = _db_enum_values(migrated_pg)

    violations: list[str] = []
    for type_name, model_values in sorted(expected.items()):
        db_values = db_enums.get(type_name)
        if db_values is None:
            violations.append(
                f"pg enum type '{type_name}' is referenced by a model column but does not exist in the DB"
            )
            continue
        missing = model_values - db_values
        if missing:
            violations.append(f"pg type '{type_name}' missing values bound by model: {sorted(missing)}")

    assert expected, "no native Enum columns found in Base.metadata — check introspection"
    assert not violations, "Model enum values absent from Postgres enums:\n" + "\n".join(violations)
