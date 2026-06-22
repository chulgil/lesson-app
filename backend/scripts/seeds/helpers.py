"""Shared helpers for seed modules — upsert, delete, logging."""

from __future__ import annotations

from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def upsert(db: AsyncSession, model: type, id: str, **kwargs: Any) -> Any:
    """Create or update a record by ID.

    Unlike INSERT-only, this never fails on duplicates and always
    reflects the latest seed definition. Also handles email uniqueness
    by merging records if an email conflict exists.
    """
    obj = await db.get(model, id)
    if obj:
        for key, value in kwargs.items():
            setattr(obj, key, value)
    else:
        # Check for email conflict (different ID, same email)
        if "email" in kwargs and kwargs["email"]:
            existing = await db.scalar(
                select(model).where(model.email == kwargs["email"])
            )
            if existing:
                # Merge: update existing record's ID and fields
                for key, value in kwargs.items():
                    setattr(existing, key, value)
                obj = existing
                await db.flush()
                return obj
        obj = model(id=id, **kwargs)
        db.add(obj)
    await db.flush()
    return obj



def log_seed(label: str, count: int, details: str = "") -> None:
    """Print seed progress."""
    suffix = f" ({details})" if details else ""
    print(f"  {label}: {count}건{suffix}")
