"""Phase 6c — SubscriptionExpiryDispatcher tests.

Plan C §3 만료 알림 dispatch + dedup.
- Recipient resolution: 학생 (Student.user_id) + 학부모 (ParentChildRelation)
- 선생님 제외 (대시보드 뱃지로 대체, #240 결정)
- Dedup: (subscription_id, milestone, sent_date, recipient_user_id) UNIQUE
- Notification payload: title/body/priority(D≤1=high)/data/action_url
"""

from __future__ import annotations

from datetime import date, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

_TODAY_KST = date(2026, 5, 2)


async def _make_user(db: AsyncSession, *, user_id: str, role: str = "student", email: str | None = None) -> None:
    from app.models.user import User, UserRole

    user = User(
        id=user_id,
        email=email or f"{user_id}@test.com",
        name=f"User {user_id}",
        role=UserRole(role),
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db.add(user)
    await db.flush()


async def _make_student(db: AsyncSession, *, student_id: str, teacher_id: str, user_id: str | None = None) -> None:
    from app.models.student import Student

    student = Student(
        id=student_id,
        user_id=user_id,
        teacher_id=teacher_id,
        name=f"Student {student_id}",
        instrument="violin",
    )
    db.add(student)
    await db.flush()


async def _make_parent_relation(db: AsyncSession, *, parent_user_id: str, parent_id: str, student_id: str) -> None:
    from app.models.parent import Parent, ParentChildRelation, ParentStatus

    parent = Parent(
        id=parent_id,
        user_id=parent_user_id,
        name=f"Parent {parent_id}",
        status=ParentStatus.active,
    )
    db.add(parent)
    rel = ParentChildRelation(parent_id=parent_id, student_id=student_id)
    db.add(rel)
    await db.flush()


def _milestone(*, sub_id: str, student_id: str, days_left: int, end_date: date) -> dict:
    return {
        "subscription_id": sub_id,
        "student_id": student_id,
        "membership_id": "m1",
        "days_left": days_left,
        "end_date": end_date,
    }


@pytest.mark.asyncio
async def test_dispatch_creates_notification_for_student_only(db_session: AsyncSession) -> None:
    """student.user_id 가 set 이고 학부모 미연결 → 학생 1명에게만 발송."""
    from app.models.notification import Notification
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    result = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    assert result["sent"] == 1
    assert result["deduplicated"] == 0

    notifs = (await db_session.scalars(select(Notification))).all()
    assert len(notifs) == 1
    assert notifs[0].user_id == "su1"
    assert notifs[0].type == "subscription_expiring"

    logs = (await db_session.scalars(select(SubscriptionExpiryDispatchLog))).all()
    assert len(logs) == 1
    assert logs[0].recipient_role == "student"
    assert logs[0].milestone == 7


@pytest.mark.asyncio
async def test_dispatch_skips_when_student_has_no_user_account(db_session: AsyncSession) -> None:
    """Student.user_id NULL + 학부모 미연결 → 발송 0건."""
    from app.models.notification import Notification
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id=None)

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    result = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    assert result["sent"] == 0
    notifs = (await db_session.scalars(select(Notification))).all()
    assert len(notifs) == 0


@pytest.mark.asyncio
async def test_dispatch_creates_notifications_for_student_and_parents(db_session: AsyncSession) -> None:
    """학생 1 + 학부모 2 → 3 건 발송."""
    from app.models.notification import Notification
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_user(db_session, user_id="pu1", role="parent")
    await _make_user(db_session, user_id="pu2", role="parent")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")
    await _make_parent_relation(db_session, parent_user_id="pu1", parent_id="p1", student_id="s1")
    await _make_parent_relation(db_session, parent_user_id="pu2", parent_id="p2", student_id="s1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    result = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    assert result["sent"] == 3
    notifs = (await db_session.scalars(select(Notification))).all()
    user_ids = {n.user_id for n in notifs}
    assert user_ids == {"su1", "pu1", "pu2"}


@pytest.mark.asyncio
async def test_dispatch_dedup_same_day_same_recipient(db_session: AsyncSession) -> None:
    """같은 날 두 번 dispatch 호출 → 1차만 발송, 2차는 dedup."""
    from app.models.notification import Notification
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))

    r1 = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)
    r2 = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    assert r1["sent"] == 1
    assert r1["deduplicated"] == 0
    assert r2["sent"] == 0
    assert r2["deduplicated"] == 1

    notifs = (await db_session.scalars(select(Notification))).all()
    assert len(notifs) == 1


@pytest.mark.asyncio
async def test_dispatch_different_milestones_record_separately(db_session: AsyncSession) -> None:
    """동일 sub + recipient 라도 milestone (D-7 vs D-1) 다르면 별도 발송."""
    from app.models.notification import Notification
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    m_d7 = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    m_d1 = _milestone(sub_id="sub1", student_id="s1", days_left=1, end_date=date(2026, 5, 3))

    r = await dispatcher.dispatch_milestones([m_d7, m_d1], today_kst=_TODAY_KST)
    assert r["sent"] == 2

    notifs = (await db_session.scalars(select(Notification))).all()
    assert len(notifs) == 2
    days_set = {n.data["daysLeft"] for n in notifs}
    assert days_set == {7, 1}


@pytest.mark.asyncio
async def test_dispatch_filters_disabled_teacher_alert_milestone(db_session: AsyncSession) -> None:
    """선생님 설정에서 빠진 D-day milestone 은 발송하지 않는다."""
    from app.models.notification import Notification
    from app.models.settings import SubscriptionSettings
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")
    db_session.add(SubscriptionSettings(teacher_id="t1", renewal_alert_days_set=[1]))
    await db_session.flush()

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    milestone["teacher_id"] = "t1"
    result = await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    assert result == {"sent": 0, "deduplicated": 0, "filtered": 1}
    notifs = (await db_session.scalars(select(Notification))).all()
    assert len(notifs) == 0


@pytest.mark.asyncio
async def test_dispatch_priority_high_for_d0_d1(db_session: AsyncSession) -> None:
    """D-0/D-1 → priority=high, D-7/D-14 → normal."""
    from app.models.notification import Notification, NotificationPriority
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestones = [
        _milestone(sub_id="sub_a", student_id="s1", days_left=14, end_date=date(2026, 5, 16)),
        _milestone(sub_id="sub_b", student_id="s1", days_left=7, end_date=date(2026, 5, 9)),
        _milestone(sub_id="sub_c", student_id="s1", days_left=1, end_date=date(2026, 5, 3)),
        _milestone(sub_id="sub_d", student_id="s1", days_left=0, end_date=date(2026, 5, 2)),
    ]
    await dispatcher.dispatch_milestones(milestones, today_kst=_TODAY_KST)

    notifs = (await db_session.scalars(select(Notification))).all()
    by_days = {n.data["daysLeft"]: n.priority for n in notifs}
    assert by_days[14] == NotificationPriority.normal
    assert by_days[7] == NotificationPriority.normal
    assert by_days[1] == NotificationPriority.high
    assert by_days[0] == NotificationPriority.high


@pytest.mark.asyncio
async def test_dispatch_payload_contains_subscription_metadata(db_session: AsyncSession) -> None:
    """Notification.data 에 subscriptionId, daysLeft 포함, action_url=/subscriptions/{id}."""
    from app.models.notification import Notification
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    notif = (await db_session.scalars(select(Notification))).one()
    assert notif.data["subscriptionId"] == "sub1"
    assert notif.data["daysLeft"] == 7
    assert notif.action_url == "/subscriptions/sub1"
    assert "D-7" in notif.title or "7" in notif.title


@pytest.mark.asyncio
async def test_dispatch_log_records_recipient_role(db_session: AsyncSession) -> None:
    """dispatch_log 에 recipient_role (student/parent) 정확히 기록."""
    from app.models.subscription_expiry import SubscriptionExpiryDispatchLog
    from app.services.subscription_expiry_dispatcher import SubscriptionExpiryDispatcher

    await _make_user(db_session, user_id="t1", role="teacher")
    await _make_user(db_session, user_id="su1", role="student")
    await _make_user(db_session, user_id="pu1", role="parent")
    await _make_student(db_session, student_id="s1", teacher_id="t1", user_id="su1")
    await _make_parent_relation(db_session, parent_user_id="pu1", parent_id="p1", student_id="s1")

    dispatcher = SubscriptionExpiryDispatcher(db_session)
    milestone = _milestone(sub_id="sub1", student_id="s1", days_left=7, end_date=date(2026, 5, 9))
    await dispatcher.dispatch_milestones([milestone], today_kst=_TODAY_KST)

    logs = (await db_session.scalars(select(SubscriptionExpiryDispatchLog))).all()
    by_role = {log.recipient_user_id: log.recipient_role for log in logs}
    assert by_role == {"su1": "student", "pu1": "parent"}
    assert all(log.sent_date == _TODAY_KST for log in logs)
    # sent_at 은 datetime — sqlite DateTime(timezone=True) 는 tzinfo 를 drop 하지만
    # PG 본 운영에서는 보존됨 (column type 으로 강제). 본 테스트는 type smoke 만 검사.
    assert all(isinstance(log.sent_at, datetime) for log in logs)
