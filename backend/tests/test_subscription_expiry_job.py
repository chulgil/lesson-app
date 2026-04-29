"""Phase 6c — Integration test for the daily expiry job.

`run_subscription_expiry_job()` composes:
1. PG advisory lock (sqlite test → 항상 True)
2. SubscriptionExpiryService.run_daily_check (status 전이 + milestones)
3. SubscriptionExpiryDispatcher.dispatch_milestones (FCM + in-app + dedup)

In sqlite test env we override AsyncSessionLocal to share the test session
so transactional state is observable.
"""

from __future__ import annotations

from datetime import date

import pytest
from freezegun import freeze_time
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# UTC 2026-05-01 17:00 = KST 2026-05-02 02:00 → today_kst = 2026-05-02
_FROZEN_UTC = "2026-05-01 17:00:00"
_TODAY_KST = date(2026, 5, 2)


async def _seed_user_student(db: AsyncSession, *, user_id: str, role: str = "teacher") -> None:
    from app.models.user import User, UserRole

    db.add(
        User(
            id=user_id,
            email=f"{user_id}@test.com",
            name=f"User {user_id}",
            role=UserRole(role),
            locale="ko",
            country="KR",
            timezone="Asia/Seoul",
            currency="KRW",
        )
    )
    await db.flush()


async def _seed_subscription(db: AsyncSession, *, sub_id: str, student_id: str, end: date, status: str) -> None:
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    db.add(
        Subscription(
            id=sub_id,
            student_id=student_id,
            membership_id="m1",
            type=SubscriptionType.package,
            end_date=end,
            status=SubscriptionStatus(status),
            total_lessons=8,
            used_lessons=0,
        )
    )
    await db.flush()


async def _seed_student(db: AsyncSession, *, student_id: str, teacher_id: str, user_id: str | None) -> None:
    from app.models.student import Student

    db.add(
        Student(
            id=student_id,
            user_id=user_id,
            teacher_id=teacher_id,
            name=f"Student {student_id}",
            instrument="violin",
        )
    )
    await db.flush()


@pytest.fixture
def patched_session(monkeypatch, db_session: AsyncSession):
    """Patch AsyncSessionLocal to yield the test session.

    Otherwise the job opens a fresh PG-bound session that doesn't see test fixtures.
    """
    from contextlib import asynccontextmanager

    from app.jobs import subscription_expiry_job as job_module

    @asynccontextmanager
    async def _ctx():
        # Avoid commit (test rolls back). Provide nested transaction so commits stay local.
        yield db_session

    monkeypatch.setattr(job_module, "AsyncSessionLocal", _ctx)
    monkeypatch.setattr(db_session, "commit", lambda: _noop())
    return db_session


async def _noop() -> None:
    return None


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_job_transitions_status_and_dispatches_for_d7(
    patched_session: AsyncSession,
) -> None:
    """E2E: D-7 sub → status active→expiringSoon + 학생 알림 1건."""
    from app.jobs.subscription_expiry_job import run_subscription_expiry_job
    from app.models.notification import Notification
    from app.models.subscription import Subscription, SubscriptionStatus

    db = patched_session
    await _seed_user_student(db, user_id="t1", role="teacher")
    await _seed_user_student(db, user_id="su1", role="student")
    await _seed_student(db, student_id="s1", teacher_id="t1", user_id="su1")
    await _seed_subscription(db, sub_id="sub1", student_id="s1", end=date(2026, 5, 9), status="active")

    result = await run_subscription_expiry_job()

    assert result["lock_acquired"] is True
    assert result["transitions"] == 1
    assert result["milestones"] == 1
    assert result["sent"] == 1
    assert result["deduplicated"] == 0
    assert result["today_kst"] == _TODAY_KST

    sub = await db.get(Subscription, "sub1")
    assert sub is not None
    assert sub.status == SubscriptionStatus.expiringSoon

    notifs = (await db.scalars(select(Notification))).all()
    assert len(notifs) == 1
    assert notifs[0].user_id == "su1"
    assert notifs[0].type == "subscription_expiring"


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_job_idempotent_same_day(patched_session: AsyncSession) -> None:
    """같은 날 두 번 실행 → 1차 sent=1, 2차 deduplicated=1, 알림 1건 유지."""
    from app.jobs.subscription_expiry_job import run_subscription_expiry_job
    from app.models.notification import Notification

    db = patched_session
    await _seed_user_student(db, user_id="t1", role="teacher")
    await _seed_user_student(db, user_id="su1", role="student")
    await _seed_student(db, student_id="s1", teacher_id="t1", user_id="su1")
    await _seed_subscription(db, sub_id="sub1", student_id="s1", end=date(2026, 5, 9), status="active")

    r1 = await run_subscription_expiry_job()
    r2 = await run_subscription_expiry_job()

    assert r1["sent"] == 1
    assert r1["deduplicated"] == 0
    assert r1["transitions"] == 1

    assert r2["sent"] == 0
    assert r2["deduplicated"] == 1
    assert r2["transitions"] == 0  # 이미 expiringSoon

    notifs = (await db.scalars(select(Notification))).all()
    assert len(notifs) == 1


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_job_handles_no_milestones_gracefully(patched_session: AsyncSession) -> None:
    """milestone hit 없는 sub (D-4) → status 전이 + dispatch 모두 0 (전이는 expiringSoon)."""
    from app.jobs.subscription_expiry_job import run_subscription_expiry_job
    from app.models.notification import Notification

    db = patched_session
    await _seed_user_student(db, user_id="t1", role="teacher")
    await _seed_user_student(db, user_id="su1", role="student")
    await _seed_student(db, student_id="s1", teacher_id="t1", user_id="su1")
    # D-4 — 14/7/1/0 milestone 비대상이지만 ≤7 이므로 status 전이 발생
    await _seed_subscription(db, sub_id="sub1", student_id="s1", end=date(2026, 5, 6), status="active")

    result = await run_subscription_expiry_job()

    assert result["transitions"] == 1
    assert result["milestones"] == 0
    assert result["sent"] == 0
    assert result["deduplicated"] == 0

    notifs = (await db.scalars(select(Notification))).all()
    assert len(notifs) == 0
