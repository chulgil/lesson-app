"""Phase 24 — subscription_edit_spec.md §6.1 4 PATCH endpoint compliance.

reschedule-credits / location / travel-time / cancel-deadline.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_subscription(db_session: AsyncSession, teacher_user_id: str, student_id: str) -> str:
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
async def test_patch_reschedule_credits_adds_bonus(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/reschedule-credits",
        headers=auth_headers,
        json={"additional_count": 2, "reason": "학생 사정 배려"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["bonus_reschedule_count"] == 2
    assert body["bonus_reason"] == "학생 사정 배려"


@pytest.mark.asyncio
async def test_patch_reschedule_credits_rejects_non_positive(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/reschedule-credits",
        headers=auth_headers,
        json={"additional_count": 0},
    )

    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_patch_lesson_location(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/location",
        headers=auth_headers,
        json={
            "location_type": "teacherStudio",
            "location_id": "loc_xxx",
            "travel_time_minutes": 15,
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["lesson_location_type"] == "teacherStudio"
    assert body["lesson_location_id"] == "loc_xxx"
    assert body["travel_time_minutes"] == 15


@pytest.mark.asyncio
async def test_patch_travel_time_only(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/travel-time",
        headers=auth_headers,
        json={"travel_time_minutes": 30},
    )

    assert response.status_code == 200, response.text
    assert response.json()["travel_time_minutes"] == 30


@pytest.mark.asyncio
async def test_patch_cancel_deadline_set_and_reset(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    # 1) set override.
    response_set = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/cancel-deadline",
        headers=auth_headers,
        json={"override_cancel_deadline_hours": 24},
    )
    assert response_set.status_code == 200, response_set.text
    assert response_set.json()["override_cancel_deadline_hours"] == 24

    # 2) reset → null = 기본 정책 복귀.
    response_reset = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/cancel-deadline",
        headers=auth_headers,
        json={"override_cancel_deadline_hours": None},
    )
    assert response_reset.status_code == 200, response_reset.text
    assert response_reset.json()["override_cancel_deadline_hours"] is None
