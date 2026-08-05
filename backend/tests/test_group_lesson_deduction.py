"""P1-4 적용범위 필드 — ``appliesTo`` + ``groupClassId``.

수강권이 어떤 수업에 쓰일 수 있는지를 나타내는 스코프 필드. 이 모듈은 두 가지를
고정한다.

1. **비파괴** — 그룹레슨 이전에 발급된 수강권(스코프 개념이 없던 행)은 NULL 로
   남고 ``universal`` 로 읽힌다. 백필도, server_default 도 없다.
2. **발급 전파** — 그룹 전용 템플릿으로 발급하면 스코프와 대상 반이 그대로
   Subscription 에 복사된다.

차감 시 스코프 검증(그룹 수업에 1:1 전용권 4xx)은 J5a 소관이라 여기 없다.

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P1-4 / §4.
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
