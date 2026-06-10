"""Issue #635 — 학부모 입금 알림 endpoint regression.

spec parent_system.md §6.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _parent_headers(user_id: str = "parent-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


def _teacher_headers(user_id: str = "teacher-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_full_link(db_session: AsyncSession) -> str:
    """학부모 ↔ 자녀 ↔ 선생님 ↔ subscription 풀세팅 → sub.id."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.student import Student
    from app.models.subscription import Subscription, SubscriptionStatus
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, "teacher-user-id")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            Student(id="child-001", teacher_id=teacher_id, name="자녀", instrument="violin"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id="child-001",
                status=ParentChildRelationStatus.active,
            ),
        ]
    )
    await db_session.flush()
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id="child-001",
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id="child-001",
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
        status=SubscriptionStatus.pending,
        payment_confirmed=False,
    )
    db_session.add(sub)
    await db_session.flush()
    return sub.id


async def _setup_users(create_test_user) -> None:
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="학부모",
        email="p@test.com",
    )
    await create_test_user(
        user_id="teacher-user-id",
        role="teacher",
        name="홍선생",
        email="t@test.com",
    )


@pytest.mark.asyncio
async def test_parent_payment_notified_sets_paid_at_and_notifies_teacher(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모 호출 → sub.paid_at + 선생님에 paymentReceived 알림 + paid_by_parent=true."""
    from sqlalchemy import select

    from app.models.notification import Notification
    from app.models.subscription import Subscription

    await _setup_users(create_test_user)
    sub_id = await _seed_full_link(db_session)
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/parent-payment-notified",
        headers=_parent_headers(),
        json={"payment_method": "bankTransfer"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    sub = await db_session.get(Subscription, sub_id)
    assert sub.paid_at is not None
    notifs = (
        await db_session.scalars(
            select(Notification)
            .where(Notification.user_id == "teacher-user-id")
            .where(Notification.type == "paymentReceived")
        )
    ).all()
    assert len(notifs) >= 1
    # body 에 '학부모' 포함, data.paidByParent=True.
    assert any("학부모" in (n.body or "") for n in notifs)
    assert any((n.data or {}).get("paidByParent") is True for n in notifs)


@pytest.mark.asyncio
async def test_teacher_role_rejected_with_403(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """선생님이 endpoint 호출 → 403."""
    await _setup_users(create_test_user)
    sub_id = await _seed_full_link(db_session)
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/parent-payment-notified",
        headers=_teacher_headers(),
        json={},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_parent_cannot_notify_unrelated_subscription(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """자기 자녀가 아닌 sub → 403."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.parent import Parent
    from app.models.student import Student
    from app.models.subscription import Subscription, SubscriptionStatus
    from app.services.subscription_service import resolve_teacher_id

    await _setup_users(create_test_user)
    teacher_id = await resolve_teacher_id(db_session, "teacher-user-id")
    db_session.add(Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"))
    db_session.add(Student(id="other-child", teacher_id=teacher_id, name="무관자녀", instrument="piano"))
    await db_session.flush()
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id="other-child",
        instrument="piano",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id="other-child",
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=4,
        total_lessons=4,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
        status=SubscriptionStatus.pending,
        payment_confirmed=False,
    )
    db_session.add(sub)
    await db_session.flush()
    sub_id = sub.id
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/parent-payment-notified",
        headers=_parent_headers(),
        json={},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_already_confirmed_subscription_rejected(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """이미 payment_confirmed=True 인 sub → 400."""
    from app.models.subscription import Subscription

    await _setup_users(create_test_user)
    sub_id = await _seed_full_link(db_session)
    sub = await db_session.get(Subscription, sub_id)
    sub.payment_confirmed = True
    await db_session.flush()
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/parent-payment-notified",
        headers=_parent_headers(),
        json={},
    )

    assert response.status_code == 400, response.text
