"""Beta seed: create teacher accounts for real user testing.

Idempotent — checks email existence before inserting.
Uses dev-login flow so teachers can log in immediately.

Usage:
    uv run python scripts/seed_beta_teachers.py
"""

from __future__ import annotations

import asyncio

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


# ── Beta teacher accounts ────────────────────────────────────
BETA_TEACHERS = [
    {
        "email": "beta.teacher1@lessonaza.app",
        "name": "베타 선생님 1",
        "instruments": ["바이올린", "비올라"],
    },
    {
        "email": "beta.teacher2@lessonaza.app",
        "name": "베타 선생님 2",
        "instruments": ["피아노"],
    },
    {
        "email": "beta.teacher3@lessonaza.app",
        "name": "베타 선생님 3",
        "instruments": ["첼로"],
    },
    {
        "email": "beta.teacher4@lessonaza.app",
        "name": "베타 선생님 4",
        "instruments": ["플루트", "클라리넷"],
    },
    {
        "email": "beta.teacher5@lessonaza.app",
        "name": "베타 선생님 5",
        "instruments": ["바이올린"],
    },
]


async def seed_beta_teachers(db: AsyncSession) -> None:
    """Create beta teacher accounts with profiles."""
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    created_count = 0

    for t in BETA_TEACHERS:
        existing = await db.scalar(
            select(User).where(User.email == t["email"])
        )
        if existing:
            print(f"  Skip: {t['email']} (already exists)")
            continue

        user = User(
            email=t["email"],
            name=t["name"],
            role=UserRole.teacher,
            onboarding_completed=True,
        )
        db.add(user)
        await db.flush()

        teacher = Teacher(
            user_id=user.id,
            instruments=t["instruments"],
            introduction=f"{t['name']}입니다. 베타 테스트 계정입니다.",
            experience_years=5,
        )
        db.add(teacher)
        created_count += 1
        print(f"  Created: {t['email']} ({t['name']})")

    await db.commit()
    print(f"\nBeta teachers: {created_count} created, {len(BETA_TEACHERS) - created_count} skipped")


async def main() -> None:
    from app.core.database import AsyncSessionLocal

    async with AsyncSessionLocal() as db:
        try:
            await seed_beta_teachers(db)
        except Exception:
            await db.rollback()
            raise


if __name__ == "__main__":
    asyncio.run(main())
