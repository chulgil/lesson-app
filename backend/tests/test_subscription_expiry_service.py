"""Phase 6b — SubscriptionExpiryService tests.

Plan C §2: status 자동 전이 (active → expiringSoon at D-7, expiringSoon → expired at D-1)
- KST 자정 기준 days_left 산정
- idempotent UPDATE skip
- end_date NULL / status paused 는 스캔 제외
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from freezegun import freeze_time
from sqlalchemy.ext.asyncio import AsyncSession

# UTC 2026-05-01 17:00 = KST 2026-05-02 02:00 → today_kst = 2026-05-02
_FROZEN_UTC = "2026-05-01 17:00:00"
_TODAY_KST = date(2026, 5, 2)


def _make_subscription(
    *,
    student_id: str,
    membership_id: str,
    end_date: date | None,
    status: str = "active",
):
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    return Subscription(
        student_id=student_id,
        membership_id=membership_id,
        type=SubscriptionType.package,
        end_date=end_date,
        status=SubscriptionStatus(status),
        total_lessons=8,
        used_lessons=0,
    )


async def _create_membership_and_relation(
    db_session: AsyncSession,
    *,
    teacher_id: str,
    student_id: str,
    relation_status: str = "active",
    active_subscription_id: str | None = None,
):
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.relationship import RelationStatus, TeacherStudentRelation
    from app.models.student import Student

    db_session.add(
        Student(
            id=student_id,
            teacher_id=teacher_id,
            name="Student",
            instrument="violin",
            user_id=None,
        )
    )

    lesson_class = LessonClass(teacher_id=teacher_id, name="만료 테스트 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id=student_id,
        instrument="piano",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()

    relation = TeacherStudentRelation(
        teacher_id=teacher_id,
        student_id=student_id,
        status=RelationStatus(relation_status),
        active_subscription_id=active_subscription_id,
    )
    db_session.add(relation)
    await db_session.flush()
    return membership, relation


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_compute_today_kst_uses_seoul_timezone() -> None:
    """today_kst = datetime.now(ZoneInfo('Asia/Seoul')).date()."""
    from app.services.subscription_expiry_service import compute_today_kst

    assert compute_today_kst() == _TODAY_KST


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_compute_days_left_for_d7_subscription() -> None:
    from app.services.subscription_expiry_service import compute_days_left

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=date(2026, 5, 9))
    assert compute_days_left(sub, today_kst=_TODAY_KST) == 7


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_compute_days_left_for_expired_subscription() -> None:
    from app.services.subscription_expiry_service import compute_days_left

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=date(2026, 4, 25))
    assert compute_days_left(sub, today_kst=_TODAY_KST) == -7


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_compute_days_left_returns_none_when_no_end_date() -> None:
    from app.services.subscription_expiry_service import compute_days_left

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=None)
    assert compute_days_left(sub, today_kst=_TODAY_KST) is None


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_status_transition_active_to_expiring_at_d7(db_session: AsyncSession) -> None:
    """수강권 만료 7일 전 → status active→expiringSoon 자동 전이."""
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=date(2026, 5, 9), status="active")
    db_session.add(sub)
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    result = await service.run_daily_check()

    await db_session.refresh(sub)
    assert sub.status == SubscriptionStatus.expiringSoon
    assert result["transitions"] == 1


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_status_transition_expiring_to_expired_when_past_end(
    db_session: AsyncSession,
) -> None:
    """end_date 가 today 보다 과거 → status expired 로 전이 (D < 0)."""
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    sub = _make_subscription(
        student_id="s1",
        membership_id="m1",
        end_date=date(2026, 5, 1),  # KST today=05-02 → days_left=-1
        status="expiringSoon",
    )
    db_session.add(sub)
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    result = await service.run_daily_check()

    await db_session.refresh(sub)
    assert sub.status == SubscriptionStatus.expired
    assert result["transitions"] == 1


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_status_transition_idempotent(db_session: AsyncSession) -> None:
    """두 번째 실행 시 동일 status 면 UPDATE skip (transitions=0)."""
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=date(2026, 5, 9), status="active")
    db_session.add(sub)
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    r1 = await service.run_daily_check()
    r2 = await service.run_daily_check()

    assert r1["transitions"] == 1
    assert r2["transitions"] == 0


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_run_daily_check_skips_subscriptions_without_end_date(
    db_session: AsyncSession,
) -> None:
    """end_date NULL 인 sub 는 스캔 제외 (전이 안 함)."""
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    sub = _make_subscription(student_id="s1", membership_id="m1", end_date=None, status="active")
    db_session.add(sub)
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    result = await service.run_daily_check()

    await db_session.refresh(sub)
    assert sub.status == SubscriptionStatus.active
    assert result["transitions"] == 0


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_run_daily_check_skips_paused_subscriptions(db_session: AsyncSession) -> None:
    """status=paused 는 만료 로직 비대상."""
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    sub = _make_subscription(
        student_id="s1",
        membership_id="m1",
        end_date=date(2026, 5, 9),
        status="paused",
    )
    db_session.add(sub)
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    result = await service.run_daily_check()

    await db_session.refresh(sub)
    assert sub.status == SubscriptionStatus.paused
    assert result["transitions"] == 0


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_run_daily_check_returns_milestone_subscriptions(
    db_session: AsyncSession,
) -> None:
    """run_daily_check 가 D-14/D-7/D-1/D-0 milestone hit 한 sub 들을
    Phase 6c dispatch 단계에 넘길 수 있도록 result['milestones'] 에 포함."""
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    db_session.add_all(
        [
            _make_subscription(student_id="s14", membership_id="m1", end_date=date(2026, 5, 16)),
            _make_subscription(student_id="s7", membership_id="m2", end_date=date(2026, 5, 9)),
            _make_subscription(student_id="s1", membership_id="m3", end_date=date(2026, 5, 3)),
            _make_subscription(student_id="s0", membership_id="m4", end_date=date(2026, 5, 2)),
            # not a milestone — 4 days left
            _make_subscription(student_id="s4", membership_id="m5", end_date=date(2026, 5, 6)),
        ]
    )
    await db_session.flush()

    service = SubscriptionExpiryService(db_session)
    result = await service.run_daily_check()

    milestones: dict[int, int] = {}
    for entry in result["milestones"]:
        milestones[entry["days_left"]] = milestones.get(entry["days_left"], 0) + 1
    assert milestones == {14: 1, 7: 1, 1: 1, 0: 1}


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_expired_subscription_transitions_active_relation_to_expired(
    db_session: AsyncSession,
) -> None:
    """수강권 만료 시 연결 관계도 expired 로 전이한다."""
    from app.models.relationship import RelationStatus
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    membership, relation = await _create_membership_and_relation(
        db_session,
        teacher_id="teacher-001",
        student_id="student-001",
        relation_status="active",
    )
    sub = _make_subscription(
        student_id="student-001",
        membership_id=membership.id,
        end_date=date(2026, 5, 1),
        status="expiringSoon",
    )
    db_session.add(sub)
    await db_session.flush()
    relation.active_subscription_id = sub.id
    await db_session.flush()

    result = await SubscriptionExpiryService(db_session).run_daily_check()

    await db_session.refresh(sub)
    await db_session.refresh(relation)
    assert result["transitions"] == 1
    assert sub.status == SubscriptionStatus.expired
    assert relation.status == RelationStatus.expired
    assert relation.active_subscription_id is None
    assert relation.last_subscription_expired_at is not None
    assert relation.expired_until is not None


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_expired_relation_transitions_to_past_after_30_days(
    db_session: AsyncSession,
) -> None:
    """수강권 만료 후 30일이 지난 관계는 past 로 전이한다."""
    from app.models.relationship import RelationStatus
    from app.services.subscription_expiry_service import SubscriptionExpiryService

    membership, relation = await _create_membership_and_relation(
        db_session,
        teacher_id="teacher-001",
        student_id="student-001",
        relation_status="expired",
    )
    relation.last_subscription_expired_at = datetime.now(UTC) - timedelta(days=31)
    relation.expired_until = datetime.now(UTC) - timedelta(days=1)
    sub = _make_subscription(
        student_id="student-001",
        membership_id=membership.id,
        end_date=date(2026, 4, 1),
        status="expired",
    )
    db_session.add(sub)
    await db_session.flush()

    result = await SubscriptionExpiryService(db_session).run_daily_check()

    await db_session.refresh(relation)
    assert result["relationship_transitions"] == 1
    assert relation.status == RelationStatus.past
