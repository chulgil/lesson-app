"""subscription_required_spec.md §2.5 — 수강권 응답에 멤버십 악기(instrument) 노출.

수강권 1개 = 멤버십 1개 = 악기 1개. FE 수기 레슨 수강권 선택 시트가 악기를
표시/상속하려면 BE 가 SubscriptionResponse.instrument 를 membership.instrument
에서 채워줘야 한다. 빈 문자열(레거시 default="")은 null 로 내려 FE 가 학생값으로
폴백하도록 한다.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_subscription(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
    *,
    instrument: str,
) -> str:
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=student_id,
        instrument=instrument,
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
    return sub.id


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )


@pytest.mark.asyncio
async def test_subscription_response_includes_membership_instrument(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id", instrument="violin")
    await db_session.commit()

    response = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)

    assert response.status_code == 200, response.text
    assert response.json()["instrument"] == "violin"


@pytest.mark.asyncio
async def test_subscription_response_empty_instrument_maps_to_null(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id", instrument="")
    await db_session.commit()

    response = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)

    assert response.status_code == 200, response.text
    # 레거시 membership(default="") 은 null 로 내려 FE 가 학생값으로 폴백한다.
    assert response.json()["instrument"] is None
