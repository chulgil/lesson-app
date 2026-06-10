"""Issue #630 — 학부모 자녀 수강권 조회 API regression.

spec user_master.md §5.2 / subscription_master.md §3.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _parent_headers(user_id: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_parent_and_children(
    db_session: AsyncSession,
    *,
    parent_user_id: str,
    teacher_user_id: str,
    children: list[tuple[str, str, str | None]],  # (student_id, name, sub_status or None)
) -> None:
    """학부모 + N명 자녀 + 자녀별 옵션 subscription."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.student import Student
    from app.models.subscription import Subscription, SubscriptionStatus
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    db_session.add(Parent(id="parent-profile-id", user_id=parent_user_id, name="학부모"))
    await db_session.flush()

    for student_id, name, sub_status in children:
        db_session.add(Student(id=student_id, teacher_id=teacher_id, name=name, instrument="violin"))
        db_session.add(
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id=student_id,
                status=ParentChildRelationStatus.active,
            )
        )
        await db_session.flush()

        if sub_status:
            lc = LessonClass(teacher_id=teacher_id, name=f"Class-{student_id}")
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
            db_session.add(
                Subscription(
                    student_id=student_id,
                    membership_id=membership.id,
                    type="monthly",
                    lessons_per_month=4,
                    total_lessons=4,
                    start_date=date(2126, 7, 1),
                    end_date=date(2126, 7, 31),
                    amount=200000,
                    status=SubscriptionStatus(sub_status),
                )
            )
            await db_session.flush()


async def _setup_users(create_test_user) -> None:
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="학부모",
        email="parent@test.com",
    )
    await create_test_user(
        user_id="teacher-user-id",
        role="teacher",
        name="홍선생",
        email="t@test.com",
    )


@pytest.mark.asyncio
async def test_returns_active_subscription_per_child(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """자녀 2명 각각 active subscription — 2 항목 반환."""
    await _setup_users(create_test_user)
    await _seed_parent_and_children(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        children=[("child-001", "첫째", "active"), ("child-002", "둘째", "active")],
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/parents/me/children-subscriptions",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body) == 2
    names = {item["student_name"] for item in body}
    assert names == {"첫째", "둘째"}
    for item in body:
        assert item["subscription_id"] is not None
        assert item["status"] == "active"


@pytest.mark.asyncio
async def test_returns_child_row_without_subscription(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """자녀 row 있고 subscription 없으면 subscription_id=None."""
    await _setup_users(create_test_user)
    await _seed_parent_and_children(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        children=[("child-no-sub", "수강권없음", None)],
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/parents/me/children-subscriptions",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body) == 1
    assert body[0]["student_id"] == "child-no-sub"
    assert body[0]["subscription_id"] is None
    assert body[0]["status"] is None


@pytest.mark.asyncio
async def test_excludes_expired_or_cancelled_subscriptions(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """expired/cancelled 인 subscription 은 제외 — 자녀 row 만 (sub None)."""
    await _setup_users(create_test_user)
    await _seed_parent_and_children(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        children=[("child-expired", "만료자녀", "expired")],
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/parents/me/children-subscriptions",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body) == 1
    assert body[0]["subscription_id"] is None  # expired sub 은 active 매칭 안 됨.


@pytest.mark.asyncio
async def test_inactive_child_relation_excluded(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """ParentChildRelation.status=inactive 자녀는 제외."""
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    await _setup_users(create_test_user)
    teacher_id = await resolve_teacher_id(db_session, "teacher-user-id")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            Student(id="inactive-child", teacher_id=teacher_id, name="비활성", instrument="piano"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id="inactive-child",
                status=ParentChildRelationStatus.inactive,
            ),
        ]
    )
    await db_session.flush()
    await db_session.commit()

    response = await client.get(
        "/api/v1/parents/me/children-subscriptions",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    assert response.json() == []


@pytest.mark.asyncio
async def test_non_parent_role_rejected(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학생/선생님 role 토큰 → 403."""
    from app.core.security import create_access_token

    await _setup_users(create_test_user)
    await db_session.commit()

    response = await client.get(
        "/api/v1/parents/me/children-subscriptions",
        headers={"Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-user-id', 'role': 'teacher'})}"},
    )

    assert response.status_code == 403, response.text
