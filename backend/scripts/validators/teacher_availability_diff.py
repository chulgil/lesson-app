"""Issue #606 — TeacherAvailability ↔ TeacherSettings.available_slots diff validator.

목적: dual-write 결과가 일치하는지 모든 선생님 단위로 검증.

```
python -m scripts.validators.teacher_availability_diff
```

Exit code:
- 0 : diff_count == 0 (단계 2 진입 가능)
- 1 : 불일치 존재 (mismatched_teachers 출력)
"""

from __future__ import annotations

import asyncio
import json
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
from app.models.settings import TeacherSettings


def _canon(slots: list[dict]) -> set[tuple[int, str, str]]:
    """슬롯 list 를 비교 가능한 set (dow, start, end) 으로 정규화."""
    return {(int(s["day_of_week"]), str(s["start_time"]), str(s["end_time"])) for s in slots}


async def _collect_ssot(db: AsyncSession, teacher_id: str) -> set[tuple[int, str, str]]:
    rows = await db.scalars(select(TeacherAvailability).where(TeacherAvailability.teacher_id == teacher_id))
    out: set[tuple[int, str, str]] = set()
    for avail in rows.all():
        time_slots = await db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
        )
        for ts in time_slots.all():
            out.add((avail.day_of_week, ts.start_time, ts.end_time))
    return out


async def _collect_settings(db: AsyncSession, teacher_id: str) -> set[tuple[int, str, str]]:
    settings = await db.scalar(select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id))
    if settings is None or settings.available_slots is None:
        return set()
    return _canon(settings.available_slots)


async def collect_diff() -> dict:
    """모든 선생님 대상 diff 계산."""
    async with AsyncSession(engine) as db:
        teacher_ids = (await db.scalars(select(TeacherAvailability.teacher_id).distinct())).all()
        settings_teacher_ids = (await db.scalars(select(TeacherSettings.teacher_id).distinct())).all()
        all_teachers = sorted(set(teacher_ids) | set(settings_teacher_ids))

        mismatched: list[dict] = []
        for tid in all_teachers:
            ssot = await _collect_ssot(db, tid)
            settings = await _collect_settings(db, tid)
            if ssot != settings:
                mismatched.append(
                    {
                        "teacher_id": tid,
                        "only_in_ssot": sorted(ssot - settings),
                        "only_in_settings": sorted(settings - ssot),
                    }
                )
        return {
            "teacher_count": len(all_teachers),
            "diff_count": len(mismatched),
            "mismatched_teachers": mismatched,
        }


def main() -> int:
    result = asyncio.run(collect_diff())
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["diff_count"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
