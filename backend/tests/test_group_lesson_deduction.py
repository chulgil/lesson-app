"""P1-4 적용범위 필드 — ``appliesTo`` + ``groupClassId``.

수강권이 어떤 수업에 쓰일 수 있는지를 나타내는 스코프 필드. 이 모듈은 두 가지를
고정한다.

1. **비파괴** — 그룹레슨 이전에 발급된 수강권(스코프 개념이 없던 행)은 NULL 로
   남고 ``universal`` 로 읽힌다. 백필도, server_default 도 없다.
2. **발급 전파** — 그룹 전용 템플릿으로 발급하면 스코프와 대상 반이 그대로
   Subscription 에 복사된다.

3. **실차감 (J5a)** — 출석 확정된 그룹 booking 의 deduct 는 기존 ``add_usage``
   경로로 실제 잔여를 줄인다. 멱등 + 선택 규칙(group→universal, 만료 임박 우선)
   + 스코프 검증(1:1 전용권 4xx) 포함.

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P1-3 / P1-4 / §4.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.subscription import Subscription, SubscriptionAppliesTo


async def _make_membership(db_session: AsyncSession, teacher_id: str, student_id: str) -> str:
    from app.models.lesson import ClassMembership, LessonClass

    lesson_class = LessonClass(teacher_id=teacher_id, name="개인레슨")
    db_session.add(lesson_class)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id=student_id,
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    return membership.id


@pytest.mark.asyncio
async def test_applies_to_migration_nondestructive(
    db_session: AsyncSession,
    create_test_user,
):
    """스코프를 모르는 기존 행은 NULL 로 남고 universal 로 읽힌다."""
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="학생",
        email="student@test.com",
    )
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    membership_id = await _make_membership(db_session, teacher_id, "test-student-id")

    # 마이그레이션 이전 코드가 쓰던 그대로 — applies_to / group_class_id 미지정.
    legacy = Subscription(
        student_id="test-student-id",
        membership_id=membership_id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        amount=200000,
    )
    db_session.add(legacy)
    await db_session.flush()
    await db_session.refresh(legacy)

    # 컬럼 계약: nullable, default/server_default 없음 — 기존 행이 절대 바뀌지 않는다.
    for table, column in (
        (Subscription.__table__, "applies_to"),
        (Subscription.__table__, "group_class_id"),
    ):
        col = table.c[column]
        assert col.nullable is True
        assert col.default is None
        assert col.server_default is None

    assert legacy.applies_to is None
    assert legacy.group_class_id is None
    # NULL 의 의미는 "1:1 전용" 이 아니라 "어디에나" — 사후 축소 금지.
    assert legacy.effective_applies_to is SubscriptionAppliesTo.universal


@pytest.mark.asyncio
async def test_issue_group_template(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """그룹 전용 템플릿으로 발급 → Subscription 에 스코프·대상 반이 전파된다."""
    from app.models.schedule import GroupClass, GroupClassType
    from app.models.student import Student
    from app.models.subscription import (
        ProposalPaymentStatus,
        ProposalStatus,
        SubscriptionProposal,
        SubscriptionTemplate,
    )
    from app.services.subscription_service import resolve_teacher_id

    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="학생",
        email="student@test.com",
    )
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    # J15b — confirm 은 그룹 템플릿이면 로스터 배정까지 수행하므로 교사 소속
    # Student 프로필이 실플로우처럼 존재해야 한다.
    db_session.add(Student(id="test-student-id", user_id="test-student-id", teacher_id=teacher_id, name="학생"))
    await db_session.flush()

    group_class = GroupClass(
        teacher_id=teacher_id,
        name="앙상블반",
        type=GroupClassType.regular,
        max_capacity=6,
    )
    db_session.add(group_class)
    await db_session.flush()

    template = SubscriptionTemplate(
        teacher_id=teacher_id,
        name="앙상블반 8회권",
        type="package",
        lessons_count=8,
        amount=280000,
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=group_class.id,
    )
    db_session.add(template)
    await db_session.flush()

    proposal = SubscriptionProposal(
        teacher_id=teacher_id,
        student_id="test-student-id",
        template_id=template.id,
        status=ProposalStatus.paymentNotified,
        payment_status=ProposalPaymentStatus.completed,
        payment_notified_at=datetime.now(UTC),
        expires_at=datetime.now(UTC) + timedelta(days=7),
    )
    db_session.add(proposal)
    await db_session.flush()
    # 아래 expire_all 이후 ORM 속성 접근은 sync lazy load 를 유발하므로 id 를 미리 확보.
    proposal_id, group_class_id = proposal.id, group_class.id
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    refreshed = await db_session.get(SubscriptionProposal, proposal_id)
    assert refreshed.subscription_id is not None
    issued = await db_session.get(Subscription, refreshed.subscription_id)
    assert issued.applies_to is SubscriptionAppliesTo.group
    assert issued.group_class_id == group_class_id
    assert issued.effective_applies_to is SubscriptionAppliesTo.group


# ---------------------------------------------------------------------------
# J5a 실차감 코어 — 출석 확정 booking 의 deduct 가 add_usage 경로로 실제 차감
# ---------------------------------------------------------------------------

_DEDUCT = "/api/v1/groups/bookings/{}/deduct"


async def _make_group_attendance(
    db_session: AsyncSession,
    create_test_user,
    *,
    booking_status: str = "attended",
    no_show_policy: str | None = None,
) -> dict:
    """teacher(test-user-id) + student(test-student-id) + 반 회차 + booking."""
    from app.models.schedule import GroupClass, GroupClassType, NoShowPolicy
    from app.models.schedule_ext import (
        GroupBookingStatus,
        GroupClassBooking,
        GroupClassSchedule,
    )
    from app.services.subscription_service import resolve_teacher_id

    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="학생",
        email="student@test.com",
    )
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    membership_id = await _make_membership(db_session, teacher_id, "test-student-id")

    group_class = GroupClass(
        teacher_id=teacher_id,
        name="앙상블반",
        type=GroupClassType.regular,
        max_capacity=6,
    )
    if no_show_policy is not None:
        group_class.no_show_policy = NoShowPolicy(no_show_policy)
    db_session.add(group_class)
    await db_session.flush()

    now = datetime.now(UTC)
    schedule = GroupClassSchedule(
        group_class_id=group_class.id,
        start_time=now - timedelta(hours=1),
        end_time=now,
        max_capacity=6,
        waitlist_capacity=2,
    )
    db_session.add(schedule)
    await db_session.flush()

    booking = GroupClassBooking(
        schedule_id=schedule.id,
        student_id="test-student-id",
        status=GroupBookingStatus(booking_status),
        attended_at=now if booking_status == "attended" else None,
    )
    db_session.add(booking)
    await db_session.flush()
    return {
        "membership_id": membership_id,
        "class_id": group_class.id,
        "booking_id": booking.id,
    }


def _make_subscription(
    *,
    membership_id: str,
    applies_to: SubscriptionAppliesTo | None = None,
    group_class_id: str | None = None,
    total_lessons: int = 8,
    used_lessons: int = 0,
    payment_confirmed: bool = True,
    end_in_days: int | None = None,
) -> Subscription:
    end_date = (datetime.now(UTC) + timedelta(days=end_in_days)).date() if end_in_days is not None else None
    return Subscription(
        student_id="test-student-id",
        membership_id=membership_id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=total_lessons,
        used_lessons=used_lessons,
        amount=200000,
        applies_to=applies_to,
        group_class_id=group_class_id,
        payment_confirmed=payment_confirmed,
        end_date=end_date,
    )


async def _usage_rows(db_session: AsyncSession, subscription_id: str) -> list:
    from sqlalchemy import select

    from app.models.subscription import SubscriptionUsage

    rows = await db_session.scalars(
        select(SubscriptionUsage).where(SubscriptionUsage.subscription_id == subscription_id)
    )
    return list(rows.all())


@pytest.mark.asyncio
async def test_deduction_decrements_remaining(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """출석 확정 차감: usage row + used_lessons 증가 + booking 마킹 (flag-only 금지)."""
    from app.models.schedule_ext import GroupClassBooking

    ctx = await _make_group_attendance(db_session, create_test_user)
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 200, response.text

    db_session.expire_all()
    refreshed = await db_session.get(Subscription, sub_id)
    assert refreshed.used_lessons == 1, "flag-only 가 아니라 실제 잔여가 줄어야 한다"
    usages = await _usage_rows(db_session, sub_id)
    assert len(usages) == 1
    assert usages[0].deducted is True
    booking = await db_session.get(GroupClassBooking, ctx["booking_id"])
    assert booking.subscription_deducted is True
    assert booking.subscription_id == sub_id


@pytest.mark.asyncio
async def test_deduction_idempotent_on_reconfirm(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """재확정(중복 호출)은 멱등 — usage 1건, 카운터 1회만."""
    ctx = await _make_group_attendance(db_session, create_test_user)
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    first = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    second = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert first.status_code == 200, first.text
    assert second.status_code == 200, second.text

    db_session.expire_all()
    refreshed = await db_session.get(Subscription, sub_id)
    assert refreshed.used_lessons == 1, "중복 확정이 이중 차감되면 안 된다"
    assert len(await _usage_rows(db_session, sub_id)) == 1


@pytest.mark.asyncio
async def test_one_to_one_only_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """1:1 전용권만 보유 → 그룹 차감 4xx, 아무것도 차감되지 않는다 (AC-2.1)."""
    from app.models.schedule_ext import GroupClassBooking

    ctx = await _make_group_attendance(db_session, create_test_user)
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.oneToOne,
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 400, response.text

    db_session.expire_all()
    refreshed = await db_session.get(Subscription, sub_id)
    assert refreshed.used_lessons == 0
    booking = await db_session.get(GroupClassBooking, ctx["booking_id"])
    assert booking.subscription_deducted is False


@pytest.mark.asyncio
async def test_selection_prefers_group_over_universal(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """선택 규칙: appliesTo=group 우선, universal 은 폴백."""
    ctx = await _make_group_attendance(db_session, create_test_user)
    universal = _make_subscription(membership_id=ctx["membership_id"])
    group_scoped = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add_all([universal, group_scoped])
    await db_session.flush()
    universal_id, group_id = universal.id, group_scoped.id
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, group_id)).used_lessons == 1
    assert (await db_session.get(Subscription, universal_id)).used_lessons == 0


@pytest.mark.asyncio
async def test_selection_prefers_earlier_expiry(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """선택 규칙: 동순위(group)면 만료 임박 수강권 우선."""
    ctx = await _make_group_attendance(db_session, create_test_user)
    expiring = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
        end_in_days=5,
    )
    later = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
        end_in_days=30,
    )
    db_session.add_all([expiring, later])
    await db_session.flush()
    expiring_id, later_id = expiring.id, later.id
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, expiring_id)).used_lessons == 1
    assert (await db_session.get(Subscription, later_id)).used_lessons == 0


@pytest.mark.asyncio
async def test_booking_pinned_subscription_wins(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """예약 시 지정된 수강권(booking.subscription_id)이 선택 규칙보다 우선한다."""
    from app.models.schedule_ext import GroupClassBooking

    ctx = await _make_group_attendance(db_session, create_test_user)
    pinned = _make_subscription(membership_id=ctx["membership_id"])
    group_scoped = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add_all([pinned, group_scoped])
    await db_session.flush()
    pinned_id, group_id = pinned.id, group_scoped.id
    booking = await db_session.get(GroupClassBooking, ctx["booking_id"])
    booking.subscription_id = pinned_id
    await db_session.flush()
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, pinned_id)).used_lessons == 1
    assert (await db_session.get(Subscription, group_id)).used_lessons == 0


@pytest.mark.asyncio
async def test_no_eligible_subscription_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """잔여 0 / 미입금 수강권만 있으면 4xx — 무언 성공(가짜 차감) 금지."""
    from app.models.schedule_ext import GroupClassBooking

    ctx = await _make_group_attendance(db_session, create_test_user)
    exhausted = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
        total_lessons=8,
        used_lessons=8,
    )
    unconfirmed = _make_subscription(
        membership_id=ctx["membership_id"],
        payment_confirmed=False,
    )
    db_session.add_all([exhausted, unconfirmed])
    await db_session.flush()
    exhausted_id, unconfirmed_id = exhausted.id, unconfirmed.id
    await db_session.commit()

    response = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert response.status_code == 400, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, exhausted_id)).used_lessons == 8
    assert (await db_session.get(Subscription, unconfirmed_id)).used_lessons == 0
    booking = await db_session.get(GroupClassBooking, ctx["booking_id"])
    assert booking.subscription_deducted is False


# ---------------------------------------------------------------------------
# J5b 노쇼 정책 집행 — 업계 2축([차감]x[보강권]) 정렬 (옵시디언 54, 2026-08-18)
# ---------------------------------------------------------------------------

_BATCH = "/api/v1/groups/bookings/batch-attendance"
_ATTENDANCE = "/api/v1/groups/bookings/{}/attendance"
_CLASSES_URL = "/api/v1/groups/classes"


async def _no_show_records(db_session: AsyncSession, booking_id: str) -> list:
    from sqlalchemy import select

    from app.models.schedule_ext import NoShowRecord

    rows = await db_session.scalars(select(NoShowRecord).where(NoShowRecord.lesson_id == booking_id))
    return list(rows.all())


async def _no_show_notifications(db_session: AsyncSession) -> list:
    from sqlalchemy import select

    from app.models.notification import Notification

    rows = await db_session.scalars(select(Notification).where(Notification.type == "groupNoShowWarning"))
    return list(rows.all())


async def _makeup_credits(db_session: AsyncSession, student_id: str = "test-student-id") -> list:
    from sqlalchemy import select

    from app.models.makeup_credit import MakeupCredit

    rows = await db_session.scalars(select(MakeupCredit).where(MakeupCredit.student_id == student_id))
    return list(rows.all())


@pytest.mark.asyncio
async def test_no_show_deduct_credit_policy(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """deductCredit: 노쇼 처리 → 1회 차감 + NoShowRecord + 결과 문구 알림."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="deductCredit"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.post(
        _BATCH,
        headers=auth_headers,
        json={"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    refreshed = await db_session.get(Subscription, sub_id)
    assert refreshed.used_lessons == 1, "노쇼 차감 정책이면 실제 잔여가 줄어야 한다"
    usages = await _usage_rows(db_session, sub_id)
    assert len(usages) == 1
    assert usages[0].type.value == "noShow"
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert len(records) == 1
    assert records[0].deducted_credits == 1
    assert records[0].applied_policy.value == "deductCredit"
    notifications = await _no_show_notifications(db_session)
    assert notifications, "배치 경로에서도 노쇼 알림이 발송돼야 한다"
    assert "차감" in notifications[0].body, "조용한 차감 금지 — 결과 문구 필수"


@pytest.mark.asyncio
async def test_no_show_reschedule_policy_deducts_and_accrues(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """reschedule: 1회 차감 + 보강권(noShowExempt) 1회 적립 — 쌍 회계."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="reschedule"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.post(
        _BATCH,
        headers=auth_headers,
        json={"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, sub_id)).used_lessons == 1
    credits = await _makeup_credits(db_session)
    assert len(credits) == 1
    assert credits[0].reason.value == "noShowExempt"
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert records[0].deducted_credits == 1
    notifications = await _no_show_notifications(db_session)
    assert any("보강" in n.body for n in notifications), "보강권 적립을 알림에 명시"


@pytest.mark.asyncio
async def test_no_show_no_deduction_policy(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """noDeduction: 무차감 + 기록 + '차감 없이' 문구. 단건 경로로 검증."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="noDeduction"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.patch(
        _ATTENDANCE.format(ctx["booking_id"]),
        headers=auth_headers,
        json={"attended": False},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, sub_id)).used_lessons == 0
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert len(records) == 1
    assert records[0].deducted_credits == 0
    notifications = await _no_show_notifications(db_session)
    assert any("차감 없이" in n.body for n in notifications)


@pytest.mark.asyncio
async def test_no_show_half_credit_legacy_no_deduction(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """폐기된 halfCredit 레거시 행: 조용한 차감 금지 — 무차감 처리 + 기록."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="halfCredit"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.post(
        _BATCH,
        headers=auth_headers,
        json={"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, sub_id)).used_lessons == 0
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert len(records) == 1
    assert records[0].deducted_credits == 0
    assert records[0].applied_policy.value == "halfCredit"


@pytest.mark.asyncio
async def test_no_show_idempotent_on_remark(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """노쇼 재처리는 멱등 — 차감·기록·알림 1회만."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="deductCredit"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    payload = {"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]}
    first = await client.post(_BATCH, headers=auth_headers, json=payload)
    second = await client.post(_BATCH, headers=auth_headers, json=payload)
    assert first.status_code == 200, first.text
    assert second.status_code == 200, second.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, sub_id)).used_lessons == 1
    assert len(await _usage_rows(db_session, sub_id)) == 1
    assert len(await _no_show_records(db_session, ctx["booking_id"])) == 1
    per_user_counts: dict[str, int] = {}
    for n in await _no_show_notifications(db_session):
        per_user_counts[n.user_id] = per_user_counts.get(n.user_id, 0) + 1
    assert all(count == 1 for count in per_user_counts.values()), "재처리가 알림을 중복 발송하면 안 된다"


@pytest.mark.asyncio
async def test_no_show_without_subscription_still_marks(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """수강권이 없어도 노쇼 마킹은 성공 — 기록만 남기고 출석부를 막지 않는다."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="confirmed", no_show_policy="deductCredit"
    )
    await db_session.commit()

    response = await client.post(
        _BATCH,
        headers=auth_headers,
        json={"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert len(records) == 1
    assert records[0].deducted_credits == 0
    assert len(await _makeup_credits(db_session)) == 0


@pytest.mark.asyncio
async def test_no_show_after_attended_deduction_no_double(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """출석 차감 후 노쇼로 정정해도 이중 차감 없음 — 마커 공유."""
    ctx = await _make_group_attendance(
        db_session, create_test_user, booking_status="attended", no_show_policy="deductCredit"
    )
    sub = _make_subscription(
        membership_id=ctx["membership_id"],
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=ctx["class_id"],
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    deducted = await client.patch(_DEDUCT.format(ctx["booking_id"]), headers=auth_headers)
    assert deducted.status_code == 200, deducted.text
    response = await client.post(
        _BATCH,
        headers=auth_headers,
        json={"bookings": [{"booking_id": ctx["booking_id"], "attended": False}]},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    assert (await db_session.get(Subscription, sub_id)).used_lessons == 1, "출석 차감 1회만"
    records = await _no_show_records(db_session, ctx["booking_id"])
    assert len(records) == 1
    assert records[0].deducted_credits == 0


@pytest.mark.asyncio
async def test_half_credit_rejected_on_create_and_update(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """폐기 정책: 신규 클래스 생성·수정에서 halfCredit 은 400."""
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await db_session.commit()

    payload = {
        "name": "앙상블반",
        "type": "regular",
        "max_capacity": 6,
        "duration_minutes": 60,
        "no_show_policy": "halfCredit",
        "repeat_days_of_week": [1],
        "repeat_time_of_day": "18:00",
    }
    created = await client.post(_CLASSES_URL, headers=auth_headers, json=payload)
    assert created.status_code == 400, created.text

    payload["no_show_policy"] = "deductCredit"
    ok = await client.post(_CLASSES_URL, headers=auth_headers, json=payload)
    assert ok.status_code in (200, 201), ok.text
    class_id = ok.json()["id"]

    updated = await client.patch(
        f"{_CLASSES_URL}/{class_id}",
        headers=auth_headers,
        json={"no_show_policy": "halfCredit"},
    )
    assert updated.status_code == 400, updated.text
