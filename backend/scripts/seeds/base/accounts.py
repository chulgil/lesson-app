"""Layer 1: Base accounts — teacher, students, parent.

Always run first. Creates user accounts with correct seed IDs.
Uses upsert so dev-login-created users get corrected to seed IDs.
"""

from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from scripts.seeds.helpers import log_seed, upsert
from scripts.seeds.ids import (
    PARENT_EMAIL,
    PARENT_ID,
    PARENT_USER_ID,
    SEED_ACCOUNTS,
    STUDENT1_EMAIL,
    STUDENT1_ID,
    STUDENT1_USER_ID,
    STUDENT2_EMAIL,
    STUDENT2_ID,
    STUDENT2_USER_ID,
    STUDENT3_EMAIL,
    STUDENT3_ID,
    STUDENT3_USER_ID,
    STUDENT4_EMAIL,
    STUDENT4_ID,
    STUDENT4_USER_ID,
    STUDENT5_EMAIL,
    STUDENT5_ID,
    STUDENT5_USER_ID,
    STUDENT6_EMAIL,
    STUDENT6_ID,
    STUDENT6_USER_ID,
    STUDENT7_EMAIL,
    STUDENT7_ID,
    STUDENT7_USER_ID,
    STUDENT8_EMAIL,
    STUDENT8_ID,
    STUDENT8_USER_ID,
    TEACHER_EMAIL,
    TEACHER_ID,
    TEACHER_USER_ID,
)


async def seed_accounts(db: AsyncSession, *, reset: bool = False) -> None:
    """Create or update all test accounts."""
    from app.models.parent import Parent
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    if reset:
        # Delete non-seed users with seed emails (dev-login leftovers)
        for email in SEED_ACCOUNTS:
            existing = await db.scalar(select(User).where(User.email == email))
            if existing and not existing.id.startswith("seed-"):
                # Clean up related records first
                await db.execute(delete(Teacher).where(Teacher.user_id == existing.id))
                await db.execute(delete(Parent).where(Parent.user_id == existing.id))
                await db.execute(delete(Student).where(Student.user_id == existing.id))
                await db.delete(existing)
        await db.flush()

    print("[Base] 계정 생성...")

    # Teacher
    await upsert(db, User, TEACHER_USER_ID,
                 email=TEACHER_EMAIL, name="박미연",
                 role=UserRole.teacher, onboarding_completed=True)
    await upsert(db, Teacher, TEACHER_ID,
                 user_id=TEACHER_USER_ID, instruments=["바이올린"])

    # Students
    students = [
        (STUDENT1_USER_ID, STUDENT1_ID, STUDENT1_EMAIL, "김소연", "바이올린", "intermediate", "active"),
        (STUDENT2_USER_ID, STUDENT2_ID, STUDENT2_EMAIL, "이준호", "바이올린", "beginner", "active"),
        (STUDENT3_USER_ID, STUDENT3_ID, STUDENT3_EMAIL, "최유진", "플루트", "beginner", "trial"),
        (STUDENT4_USER_ID, STUDENT4_ID, STUDENT4_EMAIL, "박지호", "첼로", "intermediate", "active"),
        (STUDENT5_USER_ID, STUDENT5_ID, STUDENT5_EMAIL, "한지수", "바이올린", "advanced", "inactive"),
        (STUDENT6_USER_ID, STUDENT6_ID, STUDENT6_EMAIL, "정하은", "바이올린", "beginner", "paused"),
        (STUDENT7_USER_ID, STUDENT7_ID, STUDENT7_EMAIL, "한지민", "바이올린", "beginner", "inactive"),
        (STUDENT8_USER_ID, STUDENT8_ID, STUDENT8_EMAIL, "윤서준", "바이올린", "beginner", "inactive"),
    ]
    for uid, sid, email, name, instrument, level, status in students:
        await upsert(db, User, uid,
                     email=email, name=name,
                     role=UserRole.student, onboarding_completed=True)
        await upsert(db, Student, sid,
                     teacher_id=TEACHER_ID, user_id=uid,
                     name=name, email=email, instrument=instrument,
                     level=level, status=status,
                     connection_status="connected")

    # Parent
    await upsert(db, User, PARENT_USER_ID,
                 email=PARENT_EMAIL, name="김정수",
                 role=UserRole.parent, onboarding_completed=True)
    await upsert(db, Parent, PARENT_ID,
                 user_id=PARENT_USER_ID, name="김정수", email=PARENT_EMAIL)

    log_seed("계정", 11, "선생님 1 + 학생 8 + 학부모 1 + 프로필")
