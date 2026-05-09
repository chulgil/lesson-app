"""Seed runner — CLI entry point.

Usage:
    # Full reset + all data
    uv run python -m scripts.seeds.runner --preset full --reset

    # Accounts only (minimal)
    uv run python -m scripts.seeds.runner --preset minimal

    # Reset only schedule scenario
    uv run python -m scripts.seeds.runner --scenario schedule --reset

    # List available scenarios and presets
    uv run python -m scripts.seeds.runner --list
"""

from __future__ import annotations

import argparse
import asyncio

SCENARIOS = {
    "schedule": "스케줄 (가용시간, 부킹, 레슨 요청)",
    "legacy-full": "기존 seed_data.py 전체 데이터 (레슨, 구독, 알림 등)",
    "app-version": "앱 버전 + 새 소식 + 로드맵 (R6 신뢰구축)",
}

PRESETS = {
    "minimal": {
        "description": "계정만 (빠른 테스트)",
        "scenarios": [],
    },
    "full": {
        "description": "전체 데이터 (기존 seed_data.py + 스케줄)",
        "scenarios": ["legacy-full", "schedule", "app-version"],
    },
    "schedule-test": {
        "description": "스케줄 흐름 테스트 (계정 + 스케줄)",
        "scenarios": ["schedule"],
    },
}


async def run(
    *,
    preset: str | None = None,
    scenario: str | None = None,
    reset: bool = False,
) -> None:
    """Execute seed operations."""
    from app.core.database import AsyncSessionLocal

    from scripts.seeds.base.accounts import seed_accounts
    from scripts.seeds.scenarios.app_version import seed_app_version
    from scripts.seeds.scenarios.legacy_full import seed_legacy_full
    from scripts.seeds.scenarios.schedule import seed_schedule

    scenario_map = {
        "schedule": seed_schedule,
        "legacy-full": seed_legacy_full,
        "app-version": seed_app_version,
    }

    async with AsyncSessionLocal() as session:
        try:
            print("=" * 60)
            print("  Lessonaza Seed Runner")
            print("=" * 60)

            # Always seed accounts first
            await seed_accounts(session, reset=reset)

            # Run scenarios
            scenarios_to_run: list[str] = []
            if preset:
                scenarios_to_run = PRESETS[preset]["scenarios"]
                print(f"\n  프리셋: {preset} — {PRESETS[preset]['description']}")
            elif scenario:
                scenarios_to_run = [scenario]

            for name in scenarios_to_run:
                if name in scenario_map:
                    await scenario_map[name](session, reset=reset)

            await session.commit()

            print("\n" + "=" * 60)
            print("  시드 완료!")
            print("=" * 60)

        except Exception:
            await session.rollback()
            raise


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Lessonaza seed runner")
    parser.add_argument("--preset", choices=list(PRESETS.keys()), help="프리셋 선택")
    parser.add_argument("--scenario", choices=list(SCENARIOS.keys()), help="시나리오 선택")
    parser.add_argument("--reset", action="store_true", help="기존 데이터 삭제 후 재생성")
    parser.add_argument("--list", action="store_true", help="사용 가능한 시나리오/프리셋 목록")
    args = parser.parse_args()

    if args.list:
        print("\n프리셋:")
        for name, info in PRESETS.items():
            print(f"  {name:20s} — {info['description']}")
        print("\n시나리오:")
        for name, desc in SCENARIOS.items():
            print(f"  {name:20s} — {desc}")
        return

    if not args.preset and not args.scenario:
        args.preset = "full"

    asyncio.run(run(preset=args.preset, scenario=args.scenario, reset=args.reset))


if __name__ == "__main__":
    main()
