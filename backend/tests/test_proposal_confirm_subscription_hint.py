"""Phase 30 — ProposalConfirmRequest.subscription_id hint contract.

FE 가 보내는 subscription_id 가 silently drop 되던 P1 갭 fix.
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta  # noqa: F401  timedelta 은 본문에서 동적 사용.

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_proposal_and_sub(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
) -> tuple[str, str]:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import (
        ProposalPaymentStatus,
        ProposalStatus,
        Subscription,
        SubscriptionProposal,
    )
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=student_id,
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id=student_id,
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
    )
    db_session.add(sub)
    await db_session.flush()
    proposal = SubscriptionProposal(
        teacher_id=teacher_id,
        student_id=student_id,
        status=ProposalStatus.paymentNotified,
        payment_status=ProposalPaymentStatus.completed,
        payment_notified_at=datetime.now(UTC),
        expires_at=datetime.now(UTC) + timedelta(days=7),
    )
    db_session.add(proposal)
    await db_session.flush()
    return proposal.id, sub.id


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="학생",
        email="student@test.com",
    )


@pytest.mark.asyncio
async def test_confirm_proposal_without_hint_mints_new_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """body subscription_id 미명시 — 기존 동작 (mint)."""
    from app.models.subscription import SubscriptionProposal

    await _setup(create_test_user)
    proposal_id, _ = await _seed_proposal_and_sub(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    proposal = await db_session.get(SubscriptionProposal, proposal_id)
    assert proposal is not None
    # mint 된 새 sub 의 id 가 link 됨.
    assert proposal.subscription_id is not None


@pytest.mark.asyncio
async def test_confirm_proposal_with_subscription_id_hint_links_existing(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """body subscription_id 명시 — 기존 sub 에 link, 새로 mint 하지 않음."""
    from sqlalchemy import select as _select

    from app.models.subscription import Subscription, SubscriptionProposal

    await _setup(create_test_user)
    proposal_id, existing_sub_id = await _seed_proposal_and_sub(db_session, "test-user-id", "test-student-id")
    sub_count_before = len((await db_session.scalars(_select(Subscription))).all())
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={"subscription_id": existing_sub_id},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    proposal = await db_session.get(SubscriptionProposal, proposal_id)
    assert proposal is not None
    assert proposal.subscription_id == existing_sub_id
    # 새 sub 추가 안 됨.
    sub_count_after = len((await db_session.scalars(_select(Subscription))).all())
    assert sub_count_after == sub_count_before


@pytest.mark.asyncio
async def test_confirm_proposal_with_foreign_subscription_id_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """다른 teacher 의 sub_id hint 는 ownership 검증으로 403."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription

    await _setup(create_test_user)
    await create_test_user(
        user_id="other-teacher-user",
        role="teacher",
        name="다른선생",
        email="other@test.com",
    )
    proposal_id, _ = await _seed_proposal_and_sub(db_session, "test-user-id", "test-student-id")

    # 다른 teacher 의 sub.
    from app.services.subscription_service import resolve_teacher_id

    other_teacher_id = await resolve_teacher_id(db_session, "other-teacher-user")
    other_lc = LessonClass(teacher_id=other_teacher_id, name="Other")
    db_session.add(other_lc)
    await db_session.flush()
    other_mem = ClassMembership(
        lesson_class_id=other_lc.id,
        student_id="test-student-id",
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(other_mem)
    await db_session.flush()
    other_sub = Subscription(
        student_id="test-student-id",
        membership_id=other_mem.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
    )
    db_session.add(other_sub)
    await db_session.flush()
    other_sub_id = other_sub.id
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={"subscription_id": other_sub_id},
    )

    assert response.status_code == 403, response.text
