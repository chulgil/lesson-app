"""#468 subscription IDOR/recovery + #469 attendance auto-completion deduction.

Covers:
- #468 1a: a student cannot read a proposal for another teacher's unlinked
  (offline) student; own proposal still accessible.
- #468 1c: _next_status recovers expired -> active when end_date is extended.
- #468 1d: expire-proposals endpoint is teacher-only (student -> 403).
- #469: auto_complete deducts exactly once (idempotent), no-subscription lessons
  complete cleanly, KST timing gates the 24h cutoff, pre-notice body warns.
"""

from __future__ import annotations

from datetime import date, timedelta

import pytest
from freezegun import freeze_time
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _student_headers(user_id: str = "test-student-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# #468 1a — unlinked-student proposal IDOR
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_student_cannot_read_unlinked_student_proposal(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A student must NOT read a proposal whose Student.user_id IS NULL (offline)."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="attacker-student", role="student", name="Attacker", email="atk@test.com"
    )

    # Teacher's offline (unlinked) student profile.
    db_session.add(
        Student(id="offline-student", teacher_id="test-user-id", name="Offline", instrument="violin", user_id=None)
    )
    await db_session.flush()

    created = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "offline-student", "message": "offline invoice"},
    )
    assert created.status_code == 201, created.text
    proposal_id = created.json()["id"]

    # Attacker (unrelated student) must be denied — previously this was allowed.
    resp = await client.get(
        f"/api/v1/subscriptions-proposals/{proposal_id}",
        headers=_student_headers("attacker-student"),
    )
    assert resp.status_code in (403, 404), resp.text


@pytest.mark.asyncio
async def test_student_can_read_own_proposal(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A student can still read a proposal addressed to their own linked profile."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id", role="student", name="Owner", email="owner@test.com"
    )

    # Student profile linked to the student user.
    db_session.add(
        Student(id="linked-student", teacher_id="test-user-id", name="Owner", instrument="piano", user_id="test-student-id")
    )
    await db_session.flush()

    created = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "linked-student", "message": "your invoice"},
    )
    assert created.status_code == 201, created.text
    proposal_id = created.json()["id"]

    resp = await client.get(
        f"/api/v1/subscriptions-proposals/{proposal_id}",
        headers=_student_headers("test-student-id"),
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["id"] == proposal_id


# ---------------------------------------------------------------------------
# #468 1c — _next_status expired -> active recovery
# ---------------------------------------------------------------------------


def test_next_status_recovers_expired_when_end_date_extended():
    from app.models.subscription import SubscriptionStatus
    from app.services.subscription_expiry_service import _next_status

    # Extending an expired sub so 30 days remain -> back to active.
    assert _next_status(SubscriptionStatus.expired, 30) == SubscriptionStatus.active
    # 0..7 days left -> expiringSoon (even from expired).
    assert _next_status(SubscriptionStatus.expired, 3) == SubscriptionStatus.expiringSoon
    # Still negative -> stays expired.
    assert _next_status(SubscriptionStatus.expired, -1) == SubscriptionStatus.expired
    # Active sub far from expiry stays active.
    assert _next_status(SubscriptionStatus.active, 30) == SubscriptionStatus.active


# ---------------------------------------------------------------------------
# #468 1d — expire endpoint is teacher-only
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_expire_proposals_endpoint_rejects_student(
    client: AsyncClient, create_test_user
):
    await create_test_user(
        user_id="test-student-id", role="student", name="S", email="s@test.com"
    )
    resp = await client.post(
        "/api/v1/subscriptions-proposals/expire",
        headers=_student_headers("test-student-id"),
    )
    assert resp.status_code == 403, resp.text


@pytest.mark.asyncio
async def test_expire_proposals_endpoint_allows_teacher(
    client: AsyncClient, auth_headers, create_test_user
):
    await create_test_user(user_id="test-user-id", role="teacher")
    resp = await client.post("/api/v1/subscriptions-proposals/expire", headers=auth_headers)
    assert resp.status_code == 200, resp.text


# ---------------------------------------------------------------------------
# #469 — attendance auto-completion deduction + KST timing
# ---------------------------------------------------------------------------


async def _make_active_subscription(db_session: AsyncSession, *, total: int = 8) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

    lesson_class = LessonClass(teacher_id="test-user-id", name="자동완료 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lesson_class.id, student_id="student-001", instrument="piano", status="active"
    )
    db_session.add(membership)
    await db_session.flush()

    sub = Subscription(
        student_id="student-001",
        membership_id=membership.id,
        type=SubscriptionType.package,
        status=SubscriptionStatus.active,
        total_lessons=total,
        used_lessons=0,
    )
    db_session.add(sub)
    await db_session.flush()
    return sub.id


def _make_lesson(*, lesson_date: date, start_time: str, subscription_id: str | None):
    from app.models.lesson import Lesson, LessonStatus

    return Lesson(
        student_id="student-001",
        teacher_id="test-user-id",
        student_name="Student",
        instrument="piano",
        date=lesson_date,
        start_time=start_time,
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=subscription_id,
    )


# Frozen UTC 2026-05-10 03:00 == KST 2026-05-10 12:00.
_FROZEN_UTC = "2026-05-10 03:00:00"


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_auto_complete_deducts_exactly_once(
    db_session: AsyncSession, create_test_user
):
    from app.models.lesson import LessonStatus
    from app.services.attendance_scheduler_service import AttendanceSchedulerService

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    # Lesson ended >24h ago in KST (2 days back at 10:00 KST).
    lesson = _make_lesson(
        lesson_date=date(2026, 5, 8), start_time="10:00", subscription_id=sub_id
    )
    db_session.add(lesson)
    await db_session.flush()

    svc = AttendanceSchedulerService(db_session)
    n1 = await svc.auto_complete_expired_lessons()
    assert n1 == 1
    await db_session.refresh(lesson)
    assert lesson.status == LessonStatus.completed

    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, sub_id)
    assert sub.used_lessons == 1

    # Re-run: lesson is already completed (no longer scheduled) -> 0, and even a
    # direct re-deduction is idempotent.
    n2 = await svc.auto_complete_expired_lessons()
    assert n2 == 0
    await db_session.refresh(sub)
    assert sub.used_lessons == 1

    from app.services.subscription_service import SubscriptionService

    again = await SubscriptionService(db_session).deduct_for_completed_lesson(lesson.id, sub_id)
    assert again is False
    await db_session.refresh(sub)
    assert sub.used_lessons == 1


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_auto_complete_lesson_without_subscription_completes_cleanly(
    db_session: AsyncSession, create_test_user
):
    from app.models.lesson import LessonStatus
    from app.services.attendance_scheduler_service import AttendanceSchedulerService

    await create_test_user(user_id="test-user-id", role="teacher")
    lesson = _make_lesson(
        lesson_date=date(2026, 5, 8), start_time="10:00", subscription_id=None
    )
    db_session.add(lesson)
    await db_session.flush()

    n = await AttendanceSchedulerService(db_session).auto_complete_expired_lessons()
    assert n == 1
    await db_session.refresh(lesson)
    assert lesson.status == LessonStatus.completed


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_auto_complete_respects_kst_24h_cutoff(
    db_session: AsyncSession, create_test_user
):
    from app.models.lesson import LessonStatus
    from app.services.attendance_scheduler_service import AttendanceSchedulerService

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    # Now is KST 2026-05-10 12:00. A lesson ending <24h ago must NOT auto-complete:
    # today 09:00 KST end 10:00 -> only ~2h ago.
    recent = _make_lesson(
        lesson_date=date(2026, 5, 10), start_time="09:00", subscription_id=sub_id
    )
    db_session.add(recent)
    await db_session.flush()

    n = await AttendanceSchedulerService(db_session).auto_complete_expired_lessons()
    assert n == 0
    await db_session.refresh(recent)
    assert recent.status == LessonStatus.scheduled


@pytest.mark.asyncio
@freeze_time(_FROZEN_UTC)
async def test_pre_notice_warns_about_auto_complete_and_deduction(
    db_session: AsyncSession, create_test_user
):
    from app.services.attendance_scheduler_service import AttendanceSchedulerService

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _make_active_subscription(db_session)

    # Lesson ended >30min ago but <24h: 3h back today 09:00 KST end 10:00.
    lesson = _make_lesson(
        lesson_date=date(2026, 5, 10), start_time="08:00", subscription_id=sub_id
    )
    db_session.add(lesson)
    await db_session.flush()

    sent = await AttendanceSchedulerService(db_session).notify_unconfirmed_lessons()
    assert sent == 1

    from app.models.notification import Notification
    from sqlalchemy import select

    notif = await db_session.scalar(
        select(Notification).where(Notification.type == "attendanceUnconfirmed")
    )
    assert notif is not None
    assert "자동 완료" in notif.body
    assert "차감" in notif.body
