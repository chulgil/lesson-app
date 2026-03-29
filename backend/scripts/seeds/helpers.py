"""Shared helpers for seed modules — upsert, delete, logging."""

from __future__ import annotations

from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession


async def upsert(db: AsyncSession, model: type, id: str, **kwargs: Any) -> Any:
    """Create or update a record by ID.

    Unlike INSERT-only, this never fails on duplicates and always
    reflects the latest seed definition.
    """
    obj = await db.get(model, id)
    if obj:
        for key, value in kwargs.items():
            setattr(obj, key, value)
    else:
        obj = model(id=id, **kwargs)
        db.add(obj)
    await db.flush()
    return obj


async def delete_by_prefix(db: AsyncSession, model: type, id_prefix: str) -> int:
    """Delete all records whose ID starts with a prefix (e.g., 'seed-')."""
    result = await db.execute(
        delete(model).where(model.id.startswith(id_prefix))
    )
    await db.flush()
    return result.rowcount


async def delete_by_field(
    db: AsyncSession, model: type, field_name: str, value: Any
) -> int:
    """Delete records by a specific field value."""
    field = getattr(model, field_name)
    result = await db.execute(delete(model).where(field == value))
    await db.flush()
    return result.rowcount


def log_seed(label: str, count: int, details: str = "") -> None:
    """Print seed progress."""
    suffix = f" ({details})" if details else ""
    print(f"  {label}: {count}건{suffix}")
