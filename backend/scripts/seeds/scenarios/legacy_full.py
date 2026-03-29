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

    Note: The legacy script has its own idempotency check (email existence).
    When reset=True, accounts.py already cleans up dev-login users,
    so the legacy script's check will pass.
    """
    from scripts.seed_data import seed

    print("[Scenario] 레거시 전체 데이터 (seed_data.py)...")

    try:
        await seed(db)
    except Exception as e:
        # If legacy seed fails due to existing data, log and continue
        if "already exists" in str(e).lower():
            print(f"  ⚠️ 레거시 시드 스킵 (기존 데이터 존재): {e}")
        else:
            raise

    log_seed("레거시 전체", 1, "레슨 19, 구독 8, 제안 7, 알림 8, 팔로우 6")
