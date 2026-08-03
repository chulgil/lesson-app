"""Date coercion for query parameters compared against ``Date`` columns.

Postgres has no implicit ``date >= character varying`` operator: comparing a
``Date`` column to an ISO date *string* raises ``UndefinedFunctionError`` (HTTP
500). SQLite is loosely typed and silently accepts the string, so the bug is
invisible in the SQLite test suite. Coerce string date params to
``datetime.date`` before building filters.
"""

from __future__ import annotations

from datetime import date

from fastapi import HTTPException, status


def to_date(value: str | date | None) -> date | None:
    """Coerce an ISO ``YYYY-MM-DD`` string to a ``date`` for safe DB comparison.

    ``None`` and ``date`` are returned unchanged. A malformed string raises HTTP
    422 instead of leaking an opaque Postgres 500.
    """
    if value is None or isinstance(value, date):
        return value
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid date format (expected YYYY-MM-DD): {value!r}",
        ) from exc
