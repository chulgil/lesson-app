"""Issue #633 — 학원 초대 만료 cron entrypoint.

매시간 또는 1일 1회 호출 권장 (배포 환경 scheduler 에 등록):

```bash
python -m scripts.cron.invite_expiry_tick
```
"""

from __future__ import annotations

import asyncio
import json
import sys

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import engine
from app.services.academy_invite_expiry_service import run_tick


async def _run() -> dict[str, int]:
    async with AsyncSession(engine) as db:
        result = await run_tick(db)
        await db.commit()
        return result


def main() -> int:
    result = asyncio.run(_run())
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
