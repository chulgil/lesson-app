"""Tests for teacher→student deposit-confirmation request notification — #80.

Covers:
- POST /subscriptions-proposals/{id}/request-payment-confirmation creates a real
  student notification (type ``paymentReminder``, source ``payment_inquiry``).
- 30-minute cooldown (shared with resend) → 409.
- Ownership (other teacher's proposal) → 404.
- Non-active proposal status → 400.
- Offline student (no user_id) → 200 with notified=False, no notification row.
- Regression: existing resend now actually sends a notification (was a silent no-op).
"""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification

TEACHER_PROFILE_ID = "test-user-id-prof"


async def _create_student_user(db_session: AsyncSession, *, user_id: str, name: str) -> str:
    """Insert a User + linked Student profile. Returns the Student profile id."""
    from app.models.student import Student
    from app.models.user import User, UserRole

    user = User(
        id=user_id,
        email=f"{user_id}@test.com",
        name=name,
        role=UserRole.student,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db_session.add(user)
    await db_session.flush()

    student = Student(id=f"{user_id}-profile", user_id=user_id, name=name, teacher_id=TEACHER_PROFILE_ID)
    db_session.add(student)
    await db_session.flush()
    return student.id


async def _create_proposal(
    db_session: AsyncSession,
    *,
    student_id: str,
    teacher_id: str = TEACHER_PROFILE_ID,
    status: str = "paymentNotified",
    last_reminder_sent_at: datetime | None = None,
) -> str:
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    now = datetime.now(UTC)
    proposal = SubscriptionProposal(
        teacher_id=teacher_id,
        student_id=student_id,
        status=ProposalStatus(status),
        expires_at=now + timedelta(days=7),
        last_reminder_sent_at=last_reminder_sent_at,
    )
    db_session.add(proposal)
    await db_session.flush()
    await db_session.commit()
    return proposal.id


@pytest.mark.asyncio
async def test_request_payment_confirmation_notifies_student(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Teacher requesting confirmation creates a real paymentReminder notification."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _create_student_user(db_session, user_id="confirm-student-1", name="김입금")
    pid = await _create_proposal(db_session, student_id=student_id)

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/request-payment-confirmation",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["notified"] is True

    notifications = (
        await db_session.scalars(select(Notification).where(Notification.user_id == "confirm-student-1"))
    ).all()
    assert len(notifications) == 1
    notif = notifications[0]
    assert notif.type == "paymentReminder"
    assert notif.data is not None
    assert notif.data.get("source") == "payment_inquiry"
    assert notif.data.get("proposalId") == pid
    assert notif.action_url is not None
    assert "proposals" in notif.action_url


@pytest.mark.asyncio
async def test_request_payment_confirmation_cooldown_409(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A request within 30 minutes of the previous outbound nudge is rejected (409)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _create_student_user(db_session, user_id="confirm-student-2", name="이입금")
    pid = await _create_proposal(
        db_session,
        student_id=student_id,
        last_reminder_sent_at=datetime.now(UTC) - timedelta(minutes=10),
    )

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/request-payment-confirmation",
        headers=auth_headers,
    )
    assert response.status_code == 409, response.text


@pytest.mark.asyncio
async def test_request_payment_confirmation_other_teacher_404(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A proposal owned by another teacher is not found for the current teacher (404)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _create_student_user(db_session, user_id="confirm-student-3", name="박입금")
    pid = await _create_proposal(db_session, student_id=student_id, teacher_id="other-teacher-prof")

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/request-payment-confirmation",
        headers=auth_headers,
    )
    assert response.status_code == 404, response.text


@pytest.mark.asyncio
async def test_request_payment_confirmation_wrong_status_400(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A confirmed proposal is no longer awaiting payment → 400."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _create_student_user(db_session, user_id="confirm-student-4", name="최입금")
    pid = await _create_proposal(db_session, student_id=student_id, status="confirmed")

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/request-payment-confirmation",
        headers=auth_headers,
    )
    assert response.status_code == 400, response.text


@pytest.mark.asyncio
async def test_request_payment_confirmation_offline_student_notified_false(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Offline student (no user_id) → 200 notified=False, no notification row, no crash."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    offline = Student(
        id="offline-confirm-student",
        user_id=None,
        name="오프라인",
        teacher_id=TEACHER_PROFILE_ID,
    )
    db_session.add(offline)
    await db_session.flush()
    pid = await _create_proposal(db_session, student_id="offline-confirm-student")

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/request-payment-confirmation",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["notified"] is False

    notifications = (await db_session.scalars(select(Notification))).all()
    assert len(notifications) == 0


@pytest.mark.asyncio
async def test_resend_now_sends_student_notification(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Regression: resend must actually create a student notification (was a no-op)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _create_student_user(db_session, user_id="resend-student-1", name="정입금")
    pid = await _create_proposal(db_session, student_id=student_id)

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/resend",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    notifications = (
        await db_session.scalars(select(Notification).where(Notification.user_id == "resend-student-1"))
    ).all()
    assert len(notifications) == 1
    assert notifications[0].type == "paymentReminder"
    assert notifications[0].data.get("source") == "payment_reminder"
