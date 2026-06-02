"""Phone verification hard gate on direct subscription creation — #10 A-C2 Phase B.

Phase A covered ``PATCH /subscriptions-proposals/{id}/confirm``.
Phase B promotes the gate to a reusable FastAPI dependency and verifies the
direct ``POST /subscriptions`` issuance path is also gated at the route layer.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.teacher import Teacher


async def _set_teacher_phone_verified(db: AsyncSession, user_id: str, verified: bool) -> None:
    teacher_row = await db.scalar(select(Teacher).where(Teacher.user_id == user_id))
    assert teacher_row is not None
    teacher_row.is_phone_verified = verified
    if not verified:
        teacher_row.phone_verified_at = None
    await db.flush()


async def _seed_membership(db: AsyncSession, teacher_user_id: str, student_id: str) -> str:
    """Create the LessonClass + ClassMembership so the subscription create path
    doesn't trip earlier guards before the gate fires.
    """
    from app.models.lesson import ClassMembership, LessonClass
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db, teacher_user_id)
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db.add(lc)
    await db.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=student_id,
        instrument="violin",
        lesson_duration=60,
    )
    db.add(membership)
    await db.flush()
    return membership.id


async def _setup_users(create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )


def _body(membership_id: str) -> dict:
    return {
        "student_id": "test-student-id",
        "membership_id": membership_id,
        "type": "monthly",
        "lessons_per_month": 4,
        "start_date": date(2126, 7, 1).isoformat(),
        "end_date": date(2126, 7, 31).isoformat(),
        "amount": 200000,
    }


@pytest.mark.asyncio
async def test_unverified_teacher_cannot_create_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """409 phone_verification_required at the route layer for direct issuance."""
    await _setup_users(create_test_user)
    membership_id = await _seed_membership(db_session, "test-user-id", "test-student-id")
    await _set_teacher_phone_verified(db_session, "test-user-id", verified=False)
    await db_session.commit()

    response = await client.post("/api/v1/subscriptions", headers=auth_headers, json=_body(membership_id))

    assert response.status_code == 409, response.text
    body = response.json()
    assert body["error"]["code"] == "phone_verification_required"


@pytest.mark.asyncio
async def test_verified_teacher_can_create_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Verified teachers pass the route-level gate and reach the service."""
    await _setup_users(create_test_user)
    membership_id = await _seed_membership(db_session, "test-user-id", "test-student-id")
    # Default factory flips is_phone_verified=True for teachers; assert and proceed.
    teacher_row = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    assert teacher_row is not None and teacher_row.is_phone_verified is True
    await db_session.commit()

    response = await client.post("/api/v1/subscriptions", headers=auth_headers, json=_body(membership_id))

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["student_id"] == "test-student-id"
    assert body["amount"] == 200000
