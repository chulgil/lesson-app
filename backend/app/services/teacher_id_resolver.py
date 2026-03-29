"""Resolve User.id → Teacher.id (profile ID).

All teacher-owned models (Student, Lesson, LessonClass, etc.) store
Teacher.id as their teacher_id foreign key. However, authenticated
requests provide current_user.id which is a User.id.

This module bridges that gap with a single DB lookup.
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def resolve_teacher_id(db: AsyncSession, user_id: str) -> str:
    """Return the Teacher profile ID for the given User ID.

    Raises HTTP 404 if no teacher profile exists for the user.
    """
    from app.models.teacher import Teacher

    teacher_id = await db.scalar(
        select(Teacher.id).where(Teacher.user_id == user_id)
    )
    if teacher_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher profile not found",
        )
    return teacher_id


async def try_resolve_teacher_id(db: AsyncSession, user_id: str) -> str | None:
    """Return the Teacher profile ID, or None if no profile exists."""
    from app.models.teacher import Teacher

    return await db.scalar(
        select(Teacher.id).where(Teacher.user_id == user_id)
    )
