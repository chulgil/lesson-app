"""Resolve a booking/request participant id to a real recipient User.id.

#1207 — 상대 통지 알림은 ``Notification.user_id`` (FK → users.id) 로 저장되므로,
recipient 는 반드시 **실재하는 User.id** 여야 한다. teacher_id/student_id 는
Teacher.id/Student.id (프로필 id) 일 수도, 이미 User.id 일 수도 있어 양쪽을
해소한 뒤, 결과가 실제 User 가 아니면 ``None`` 을 돌려 호출부가 emit 을 건너뛰게
한다(핵심 흐름을 FK 위반으로 깨뜨리지 않기 위함).
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def resolve_teacher_user_id(db: AsyncSession, teacher_id: str | None) -> str | None:
    """Return the teacher's User.id for a Teacher.id-or-User.id, or None if not a real user."""
    if not teacher_id:
        return None
    from app.models.teacher import Teacher
    from app.models.user import User

    teacher = await db.get(Teacher, teacher_id)
    candidate = teacher.user_id if teacher is not None else teacher_id
    return await db.scalar(select(User.id).where(User.id == candidate))


async def resolve_student_user_id(db: AsyncSession, student_id: str | None) -> str | None:
    """Return the student's User.id for a Student.id-or-User.id, or None if not a real user."""
    if not student_id:
        return None
    from app.models.student import Student
    from app.models.user import User

    profile_user_id = await db.scalar(select(Student.user_id).where(Student.id == student_id))
    candidate = profile_user_id or student_id
    return await db.scalar(select(User.id).where(User.id == candidate))
