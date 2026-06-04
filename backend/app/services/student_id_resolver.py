"""Resolve User.id → Student.id (profile ID).

Mirror of teacher_id_resolver. Student-owned records (MakeupCredit, etc.)
key off Student.id, but authenticated requests carry User.id.
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def resolve_student_id(db: AsyncSession, user_id: str) -> str:
    """Return the Student profile ID for the given User ID.

    Raises HTTP 404 if no student profile exists for the user.
    """
    from app.models.student import Student

    student_id = await db.scalar(select(Student.id).where(Student.user_id == user_id))
    if student_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )
    return student_id
