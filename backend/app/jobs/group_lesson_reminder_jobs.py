"""그룹 수업 리마인더 cron — P2-2.

전일(KST 20:00)·당일(KST 08:00) 두 배치가 확정 예약을 훑어 학생에게 리마인더를
보낸다. 그룹 수업은 1:1 과 달리 회차가 드문드문 열려 학생이 날짜를 잊기 쉽고,
정원이 있어 노쇼가 다른 학생의 자리를 낭비한다.

멱등성: 예약 행의 ``reminder_day_before_sent_at`` / ``reminder_day_of_sent_at``
가 NULL 인 행만 집고, 발송 직후 타임스탬프를 찍는다. advisory lock 실패나 인스턴스
재기동으로 배치가 다시 돌아도 같은 학생에게 두 번 가지 않는다.

시각 규약: 회차 ``start_time`` 은 KST 벽시계다 (schedule_ext_service 와 동일).
SQLite 는 timezone 을 되돌려주지 않으므로 최종 날짜 판정은 SQL 이 아니라 Python
에서 ``as_kst`` 로 정규화해 한다. SQL 쪽 범위 조건은 스캔을 좁히는 용도의 여유
있는 가드일 뿐이다.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.scheduler import (  # noqa: F401  release 는 finally 블록에서 사용 — ruff 가 일부 케이스에서 detect 못함.
    advisory_lock_key,
    release_advisory_lock,
    try_advisory_lock,
)
from app.services.group_notification_service import (
    TYPE_REMINDER_DAY_BEFORE,
    TYPE_REMINDER_DAY_OF,
    GroupNotificationService,
    as_kst,
)

logger = logging.getLogger(__name__)

JOB_ID_DAY_BEFORE = "group_lesson_reminder_day_before"
JOB_ID_DAY_OF = "group_lesson_reminder_day_of"

_KST = ZoneInfo("Asia/Seoul")

# SQL 범위 가드의 여유폭. 저장 dialect 에 따라 start_time 이 naive(KST)/aware(UTC) 로
# 오갈 수 있어 최대 9시간이 어긋난다 — 하루 여유를 둬 후보를 놓치지 않게 한다.
_SCAN_MARGIN = timedelta(days=1)

_SENT_AT_COLUMN = {
    TYPE_REMINDER_DAY_BEFORE: "reminder_day_before_sent_at",
    TYPE_REMINDER_DAY_OF: "reminder_day_of_sent_at",
}


async def _send_reminders(session: AsyncSession, *, notification_type: str, days_ahead: int) -> int:
    """KST 기준 ``days_ahead`` 일 뒤 회차의 확정 예약에 리마인더 1회씩. 발송 건수 반환."""
    from app.models.schedule import GroupClass
    from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking, GroupClassSchedule

    sent_at_column = _SENT_AT_COLUMN[notification_type]
    target_date = (datetime.now(UTC).astimezone(_KST) + timedelta(days=days_ahead)).date()
    window_start = datetime.combine(target_date, datetime.min.time(), tzinfo=_KST) - _SCAN_MARGIN
    window_end = window_start + _SCAN_MARGIN * 2 + timedelta(days=1)

    rows = await session.execute(
        select(GroupClassBooking, GroupClassSchedule, GroupClass)
        .join(GroupClassSchedule, GroupClassBooking.schedule_id == GroupClassSchedule.id)
        .join(GroupClass, GroupClassSchedule.group_class_id == GroupClass.id)
        .where(
            GroupClassBooking.status == GroupBookingStatus.confirmed,
            getattr(GroupClassBooking, sent_at_column).is_(None),
            GroupClassSchedule.start_time >= window_start,
            GroupClassSchedule.start_time <= window_end,
        )
    )

    service = GroupNotificationService(session)
    sent = 0
    for booking, schedule, group_class in rows.all():
        # 권위 판정 — SQL 범위는 후보 축소용이고 날짜는 KST 로 정규화해 비교한다.
        if as_kst(schedule.start_time).date() != target_date:
            continue
        try:
            delivered = await service.notify_lesson_reminder(
                booking=booking,
                schedule=schedule,
                group_class=group_class,
                notification_type=notification_type,
            )
        except Exception:  # noqa: BLE001  한 건 실패가 배치 전체를 멈추지 않게 한다.
            logger.exception("group reminder failed booking=%s type=%s", booking.id, notification_type)
            continue
        if not delivered:
            # 수신자 User 를 못 찾음 — 계정이 생기면 다시 시도하도록 타임스탬프를 남기지 않는다.
            continue
        setattr(booking, sent_at_column, datetime.now(UTC))
        sent += 1

    await session.flush()
    return sent


async def _run(
    session: AsyncSession | None,
    *,
    job_id: str,
    notification_type: str,
    days_ahead: int,
) -> dict[str, Any]:
    """Common runner — accepts an injected session (tests) or opens one (prod)."""

    async def _do(s: AsyncSession) -> dict[str, Any]:
        sent = await _send_reminders(s, notification_type=notification_type, days_ahead=days_ahead)
        return {"job_id": job_id, "sent": sent}

    if session is not None:
        return await _do(session)

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(job_id)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", job_id)
            return {"job_id": job_id, "sent": 0, "lock_acquired": False}
        try:
            out = await _do(new_session)
            await new_session.commit()
        finally:
            # PG advisory lock 누수 차단.
            await release_advisory_lock(new_session, key=lock_key)
        out["lock_acquired"] = True
        return out


async def run_group_lesson_reminder_day_before(session: AsyncSession | None = None) -> dict[str, Any]:
    """Public entry — 전일 리마인더. KST 20:00 daily."""
    return await _run(
        session,
        job_id=JOB_ID_DAY_BEFORE,
        notification_type=TYPE_REMINDER_DAY_BEFORE,
        days_ahead=1,
    )


async def run_group_lesson_reminder_day_of(session: AsyncSession | None = None) -> dict[str, Any]:
    """Public entry — 당일 리마인더. KST 08:00 daily."""
    return await _run(
        session,
        job_id=JOB_ID_DAY_OF,
        notification_type=TYPE_REMINDER_DAY_OF,
        days_ahead=0,
    )
