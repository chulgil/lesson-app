"""Tests for POST /api/v1/subscriptions/{id}/undo-confirm — #426.

Policy:
- 24h window after payment_confirmed_at
- Blocked once first_lesson_consumed_at is set
- Rolls back relationship.status from previous_status
- Cancels auto-generated (subscriptionGenerated) future lessons
"""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


async def _create_membership(
    db_session: AsyncSession,
    *,
    teacher_id: str = "test-user-id-prof",
    student_id: str = "student-001",
) -> str:
    from app.models.lesson import ClassMembership, LessonClass

    lesson_class = LessonClass(teacher_id=teacher_id, name="Undo 테스트 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id=student_id,
        instrument="piano",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()
    return membership.id


async def _create_relation(
    db_session: AsyncSession,
    *,
    teacher_id: str = "test-user-id-prof",
    student_id: str = "student-001",
    status: str = "trialBooked",
) -> str:
    from app.models.relationship import TeacherStudentRelation

    relation = TeacherStudentRelation(
        teacher_id=teacher_id,
        student_id=student_id,
        status=status,
    )
    db_session.add(relation)
    await db_session.flush()
    return relation.id


async def _create_confirmed_subscription(
    client: AsyncClient,
    auth_headers: dict,
    db_session: AsyncSession,
    *,
    confirmed_hours_ago: int = 1,
) -> str:
    """Create a subscription, confirm it, then back-date payment_confirmed_at."""
    membership_id = await _create_membership(db_session)
    await _create_relation(db_session)

    create_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 4,
            "amount": 120000,
            "payment_confirmed": False,
            "payment_method": "bankTransfer",
        },
    )
    assert create_response.status_code == 201
    sub_id = create_response.json()["id"]

    confirm_response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/confirm-payment",
        headers=auth_headers,
        json={"payment_method": "bankTransfer"},
    )
    assert confirm_response.status_code == 200

    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, sub_id)
    sub.payment_confirmed_at = datetime.now(UTC) - timedelta(hours=confirmed_hours_ago)
    await db_session.commit()

    return sub_id


@pytest.mark.asyncio
async def test_undo_within_24h_success(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Undo within 24h: payment_confirmed → False, payment_confirmed_at → None."""
    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=23)

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    data = response.json()
    assert data["payment_confirmed"] is False
    assert data["payment_confirmed_at"] is None
    assert data["payment_status"] in ("needsConfirmation", "pending")


@pytest.mark.asyncio
async def test_undo_after_24h_fails(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Undo after 24h window: 409 with clear reason."""
    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=25)

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )

    assert response.status_code == 409, response.text
    assert "24" in response.json()["detail"] or "window" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_undo_after_first_lesson_consumed_fails(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Undo blocked once first lesson is consumed (firstLessonConsumedAt set)."""
    from app.models.subscription import Subscription

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=1)

    sub = await db_session.get(Subscription, sub_id)
    sub.first_lesson_consumed_at = datetime.now(UTC)
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )

    assert response.status_code == 409, response.text
    detail = response.json()["detail"].lower()
    assert "lesson" in detail or "차감" in response.json()["detail"]


@pytest.mark.asyncio
async def test_undo_rolls_back_relationship_status(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Confirm payment stashes previous_status; undo restores it."""
    from app.models.relationship import TeacherStudentRelation

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=2)

    relation_before = (
        await db_session.scalars(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == "test-user-id-prof",
                TeacherStudentRelation.student_id == "student-001",
            )
        )
    ).first()
    assert relation_before is not None
    assert relation_before.previous_status == "trialBooked", (
        f"confirm_payment must stash previous_status (was {relation_before.previous_status})"
    )

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    await db_session.refresh(relation_before)
    assert relation_before.status == "trialBooked"
    assert relation_before.previous_status is None


@pytest.mark.asyncio
async def test_undo_cancels_auto_generated_future_lessons(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Auto-generated future lessons get cancelled; manual lessons untouched."""
    from datetime import date

    from app.models.lesson import Lesson, LessonSource, LessonStatus

    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=1)

    auto_lesson = Lesson(
        student_id="student-001",
        teacher_id="test-user-id-prof",
        student_name="Test Student",
        instrument="piano",
        date=date(2026, 6, 15),
        start_time="14:00",
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=sub_id,
        lesson_source=LessonSource.subscription_generated,
    )
    manual_lesson = Lesson(
        student_id="student-001",
        teacher_id="test-user-id-prof",
        student_name="Test Student",
        instrument="piano",
        date=date(2026, 6, 20),
        start_time="14:00",
        duration=60,
        status=LessonStatus.scheduled,
        subscription_id=sub_id,
        lesson_source=LessonSource.manual,
    )
    db_session.add_all([auto_lesson, manual_lesson])
    await db_session.commit()

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    await db_session.refresh(auto_lesson)
    await db_session.refresh(manual_lesson)
    assert auto_lesson.status == LessonStatus.cancelled
    assert manual_lesson.status == LessonStatus.scheduled


@pytest.mark.asyncio
async def test_undo_requires_payment_already_confirmed(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Undo on a never-confirmed subscription is 400."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_membership(db_session)

    create_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 4,
            "amount": 120000,
            "payment_confirmed": False,
            "payment_method": "bankTransfer",
        },
    )
    sub_id = create_response.json()["id"]

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=auth_headers,
    )

    assert response.status_code == 400


@pytest.mark.asyncio
async def test_undo_rejects_other_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A different teacher cannot undo someone else's subscription."""
    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_confirmed_subscription(client, auth_headers, db_session, confirmed_hours_ago=1)

    await create_test_user(
        user_id="other-teacher-id",
        role="teacher",
        name="Other Teacher",
        email="other@test.com",
    )
    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher-id', 'role': 'teacher'})}"
    }

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/undo-confirm",
        headers=other_headers,
    )

    assert response.status_code in (403, 404)
