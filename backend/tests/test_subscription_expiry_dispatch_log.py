"""Phase 6a — SubscriptionExpiryDispatchLog model tests.

Plan C §3 dispatch dedup table — UNIQUE(subscription_id, milestone, sent_date, recipient_user_id)
"""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_dispatch_log_persists_required_fields(db_session: AsyncSession) -> None:
    """5 핵심 필드 (subscription_id, milestone, recipient_user_id, recipient_role, sent_date) 영속화."""
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog

    log = SubscriptionExpiryDispatchLog(
        subscription_id="sub-1",
        milestone=7,
        recipient_user_id="user-1",
        recipient_role="student",
        sent_date=date(2026, 5, 1),
        sent_at=datetime.now(UTC),
    )
    db_session.add(log)
    await db_session.flush()

    fetched = (await db_session.scalars(select(SubscriptionExpiryDispatchLog))).one()
    assert fetched.subscription_id == "sub-1"
    assert fetched.milestone == 7
    assert fetched.recipient_user_id == "user-1"
    assert fetched.recipient_role == "student"
    assert fetched.sent_date == date(2026, 5, 1)


@pytest.mark.asyncio
async def test_dispatch_log_unique_constraint_blocks_duplicates(
    db_session: AsyncSession,
) -> None:
    """UNIQUE(subscription_id, milestone, sent_date, recipient_user_id) 차단."""
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog

    common = dict(
        subscription_id="sub-1",
        milestone=7,
        recipient_user_id="user-1",
        recipient_role="student",
        sent_date=date(2026, 5, 1),
    )
    db_session.add(SubscriptionExpiryDispatchLog(**common, sent_at=datetime.now(UTC)))
    await db_session.flush()

    db_session.add(SubscriptionExpiryDispatchLog(**common, sent_at=datetime.now(UTC)))
    with pytest.raises(IntegrityError):
        await db_session.flush()


@pytest.mark.asyncio
async def test_dispatch_log_allows_different_recipient(db_session: AsyncSession) -> None:
    """같은 (sub, milestone, sent_date) 라도 recipient 다르면 허용 (학생 + 학부모)."""
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog

    base = dict(
        subscription_id="sub-1",
        milestone=7,
        sent_date=date(2026, 5, 1),
    )
    db_session.add(
        SubscriptionExpiryDispatchLog(
            **base,
            recipient_user_id="user-student",
            recipient_role="student",
            sent_at=datetime.now(UTC),
        )
    )
    db_session.add(
        SubscriptionExpiryDispatchLog(
            **base,
            recipient_user_id="user-parent",
            recipient_role="parent",
            sent_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    rows = (await db_session.scalars(select(SubscriptionExpiryDispatchLog))).all()
    assert len(rows) == 2


@pytest.mark.asyncio
async def test_dispatch_log_allows_different_milestone(db_session: AsyncSession) -> None:
    """같은 (sub, recipient, sent_date) 라도 milestone (D-14/7/1/0) 다르면 허용."""
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog

    common = dict(
        subscription_id="sub-1",
        recipient_user_id="user-1",
        recipient_role="student",
        sent_date=date(2026, 5, 1),
    )
    db_session.add(SubscriptionExpiryDispatchLog(**common, milestone=14, sent_at=datetime.now(UTC)))
    db_session.add(SubscriptionExpiryDispatchLog(**common, milestone=7, sent_at=datetime.now(UTC)))
    await db_session.flush()

    rows = (await db_session.scalars(select(SubscriptionExpiryDispatchLog))).all()
    assert len(rows) == 2
