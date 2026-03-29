"""Scenario: Legacy Full — runs the original seed_data.py.

Wraps the monolithic seed script to provide backward compatibility
while the new modular system is progressively built out.

As new scenarios are extracted (lessons, subscriptions, etc.),
they will replace portions of this legacy wrapper.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from scripts.seeds.helpers import log_seed


async def seed_legacy_full(db: AsyncSession, *, reset: bool = False) -> None:
    """Run the original seed_data.py within the new framework.

    When reset=True, deletes all seed-prefixed data first so the
    legacy script's idempotency check passes and it re-creates everything.
    """
    from sqlalchemy import text

    from scripts.seed_data import seed

    print("[Scenario] 레거시 전체 데이터 (seed_data.py)...")

    if reset:
        # Get list of existing tables
        result = await db.execute(text(
            "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
        ))
        existing_tables = {row[0] for row in result.fetchall()}

        # Delete seed-prefixed data from known tables (FK order)
        tables_to_clean = [
            "subscription_usages", "subscription_proposals", "subscriptions",
            "subscription_templates", "lesson_feedbacks", "lessons",
            "lesson_bookings", "lesson_requests",
            "availability_time_slots", "teacher_availabilities",
            "class_memberships", "lesson_classes", "lesson_policies",
            "notifications", "follows",
            "practice_sections", "practice_repertoires",
            "practice_goals", "practice_streaks",
            "teacher_student_relations", "parent_child_relations",
            "parent_teacher_connections",
            "students", "teachers", "parents", "oauth_accounts", "users",
        ]
        for table in tables_to_clean:
            if table in existing_tables:
                await db.execute(text(f"DELETE FROM {table} WHERE id LIKE 'seed-%'"))
        await db.flush()
        print("  기존 시드 데이터 삭제 완료")

    try:
        await seed(db)
    except Exception as e:
        if "already exists" in str(e).lower():
            print(f"  ⚠️ 레거시 시드 스킵 (기존 데이터 존재): {e}")
        else:
            raise

    log_seed("레거시 전체", 1, "레슨 19, 구독 8, 제안 7, 알림 8, 팔로우 6")
