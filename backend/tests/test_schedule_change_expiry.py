"""Unit tests for schedule_change_expiry_jobs — #692.

케이스:
1. 72h 경과 → scheduleChangeExpired 이벤트 생성
2. 72h 미경과 (48h) → 만료 없음
3. 변경권 복원: change_credit_used=1 이면 used_reschedule_count -= 1
4. 리마인드 중복 방지: scheduleChangeReminder 이미 있으면 중복 생성 안함
5. 만료 중복 방지: scheduleChangeExpired 이미 있으면 중복 생성 안함
6. 24h 경과 → scheduleChangeReminder 이벤트 생성
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.jobs.schedule_change_expiry_jobs import run_schedule_change_expiry_job
from app.models.request_event import RequestEvent, RequestEventType


def _make_event(
    *,
    request_id: str = "req-1",
    actor_type: str = "student",
    actor_id: str = "student-1",
    event_type: RequestEventType = RequestEventType.scheduleChangeProposed,
    created_at: datetime,
    session_number: int = 1,
    subscription_id: str | None = "sub-1",
    change_credit_used: int | None = None,
) -> RequestEvent:
    return RequestEvent(
        request_id=request_id,
        actor_type=actor_type,
        actor_id=actor_id,
        event_type=event_type,
        created_at=created_at,
        session_number=session_number,
        subscription_id=subscription_id,
        change_credit_used=change_credit_used,
    )


async def _count_events(session: AsyncSession, event_type: RequestEventType, request_id: str = "req-1") -> int:
    from sqlalchemy import select

    result = await session.scalars(
        select(RequestEvent).where(
            RequestEvent.request_id == request_id,
            RequestEvent.event_type == event_type,
        )
    )
    return len(list(result.all()))


@pytest.mark.asyncio
async def test_expired_event_created_after_72h(db_session: AsyncSession) -> None:
    """72h 경과된 제안 → scheduleChangeExpired 이벤트 생성."""
    proposed_at = datetime.now(UTC) - timedelta(hours=73)
    event = _make_event(created_at=proposed_at)
    db_session.add(event)
    await db_session.flush()

    result = await run_schedule_change_expiry_job(session=db_session)

    assert result["expired"] == 1
    assert await _count_events(db_session, RequestEventType.scheduleChangeExpired) == 1


@pytest.mark.asyncio
async def test_no_expiry_before_72h(db_session: AsyncSession) -> None:
    """48h 경과 → 만료 없음."""
    proposed_at = datetime.now(UTC) - timedelta(hours=48)
    event = _make_event(created_at=proposed_at)
    db_session.add(event)
    await db_session.flush()

    result = await run_schedule_change_expiry_job(session=db_session)

    assert result["expired"] == 0
    assert await _count_events(db_session, RequestEventType.scheduleChangeExpired) == 0


@pytest.mark.asyncio
async def test_reschedule_credit_restored_on_expiry(db_session: AsyncSession) -> None:
    """72h 만료 시 change_credit_used=1 이면 used_reschedule_count 복원."""
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    sub = Subscription(
        id="sub-1",
        student_id="student-1",
        membership_id="membership-1",
        type=SubscriptionType.package,
        total_lessons=10,
        used_lessons=0,
        amount=0,
        total_reschedule_allowance=2,
        used_reschedule_count=1,  # 이미 차감된 상태
        reschedule_deadline_hours=12,
        status=SubscriptionStatus.active,
        payment_confirmed=True,
    )
    db_session.add(sub)

    proposed_at = datetime.now(UTC) - timedelta(hours=73)
    event = _make_event(created_at=proposed_at, change_credit_used=1)
    db_session.add(event)
    await db_session.flush()

    await run_schedule_change_expiry_job(session=db_session)

    await db_session.refresh(sub)
    assert sub.used_reschedule_count == 0  # 복원됨


@pytest.mark.asyncio
async def test_reminder_not_duplicated(db_session: AsyncSession) -> None:
    """scheduleChangeReminder 이미 있으면 중복 생성 안함."""
    proposed_at = datetime.now(UTC) - timedelta(hours=30)
    event = _make_event(created_at=proposed_at)
    db_session.add(event)

    # 리마인더 이미 존재
    existing_reminder = _make_event(
        created_at=datetime.now(UTC) - timedelta(hours=5),
        actor_type="system",
        actor_id="system",
        event_type=RequestEventType.scheduleChangeReminder,
    )
    db_session.add(existing_reminder)
    await db_session.flush()

    result = await run_schedule_change_expiry_job(session=db_session)

    assert result["reminded"] == 0
    assert await _count_events(db_session, RequestEventType.scheduleChangeReminder) == 1


@pytest.mark.asyncio
async def test_expiry_not_duplicated(db_session: AsyncSession) -> None:
    """scheduleChangeExpired 이미 있으면 중복 생성 안함."""
    proposed_at = datetime.now(UTC) - timedelta(hours=80)
    event = _make_event(created_at=proposed_at)
    db_session.add(event)

    existing_expired = _make_event(
        created_at=datetime.now(UTC) - timedelta(hours=5),
        actor_type="system",
        actor_id="system",
        event_type=RequestEventType.scheduleChangeExpired,
    )
    db_session.add(existing_expired)
    await db_session.flush()

    result = await run_schedule_change_expiry_job(session=db_session)

    assert result["expired"] == 0
    assert await _count_events(db_session, RequestEventType.scheduleChangeExpired) == 1


@pytest.mark.asyncio
async def test_reminder_created_after_24h(db_session: AsyncSession) -> None:
    """24h 경과 → scheduleChangeReminder 이벤트 생성."""
    proposed_at = datetime.now(UTC) - timedelta(hours=25)
    event = _make_event(created_at=proposed_at)
    db_session.add(event)
    await db_session.flush()

    result = await run_schedule_change_expiry_job(session=db_session)

    assert result["reminded"] == 1
    assert await _count_events(db_session, RequestEventType.scheduleChangeReminder) == 1
