"""Subscription refund request flow — issue #1271."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


async def _seed_subscription(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
    *,
    total_lessons: int = 10,
    used_lessons: int = 2,
    amount: int = 500000,
    sub_status: str = "active",
    paid_at: datetime | None = None,
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
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id=student_id,
        membership_id=membership.id,
        type="package",
        total_lessons=total_lessons,
        used_lessons=used_lessons,
        start_date=date(2126, 7, 1),
        amount=amount,
        status=sub_status,
        paid_at=paid_at,
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


REFUND_PAYLOAD = {
    "bank_name": "국민은행",
    "account_number": "123456789012",
    "account_holder": "테스트학생",
    "reason": "레슨을 그만두게 되었습니다",
}


@pytest.mark.asyncio
async def test_student_creates_refund_request(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A student can submit a refund request for their own subscription."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["subscription_id"] == sub_id
    assert body["status"] == "requested"
    # Response viewer role is the requesting student — account number is masked.
    assert body["account_number"] == "********9012"
    assert body["estimated_refund_amount"] is not None


@pytest.mark.asyncio
async def test_teacher_cannot_create_refund_request(
    client: AsyncClient,
    auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A teacher (not the student) cannot open a refund request."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.post(
        "/api/v1/refund-requests",
        headers=auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_duplicate_active_request_rejected(
    client: AsyncClient,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Only one active ('requested') refund request per subscription is allowed."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    first = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    assert first.status_code == 201, first.text

    second = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    assert second.status_code == 409, second.text


@pytest.mark.asyncio
async def test_exhausted_subscription_rejected(
    client: AsyncClient,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A subscription with no remaining sessions is not refund-eligible."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id", sub_status="exhausted")
    await db_session.commit()

    response = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    assert response.status_code == 400, response.text


@pytest.mark.asyncio
async def test_create_notifies_teacher(
    client: AsyncClient,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Creating a refund request emits a notification for the owning teacher."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    response = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    assert response.status_code == 201, response.text

    notifications = (await db_session.scalars(select(Notification).where(Notification.user_id == "test-user-id"))).all()
    assert len(notifications) == 1
    assert notifications[0].type == "refundRequested"
    assert notifications[0].action_url == f"/subscriptions/{sub_id}"


@pytest.mark.asyncio
async def test_teacher_completes_refund_request(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Completing a refund request transitions the subscription to refunded and notifies the student."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    created = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    refund_id = created.json()["id"]

    response = await client.patch(
        f"/api/v1/refund-requests/{refund_id}/complete",
        headers=auth_headers,
        json={"processed_amount": 400000},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "completed"
    assert body["processed_amount"] == 400000
    assert body["processed_at"] is not None

    sub_response = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub_response.status_code == 200
    sub_body = sub_response.json()
    assert sub_body["status"] == "refunded"
    assert sub_body["remaining_lessons"] == 0

    notifications = (
        await db_session.scalars(select(Notification).where(Notification.user_id == "test-student-id"))
    ).all()
    refund_notifs = [n for n in notifications if n.type == "refundCompleted"]
    assert len(refund_notifs) == 1


@pytest.mark.asyncio
async def test_teacher_rejects_refund_request(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Rejecting a refund request records the reason and leaves the subscription untouched."""
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    created = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    refund_id = created.json()["id"]

    response = await client.patch(
        f"/api/v1/refund-requests/{refund_id}/reject",
        headers=auth_headers,
        json={"reject_reason": "정책상 환불 불가 기간입니다"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "rejected"
    assert body["reject_reason"] == "정책상 환불 불가 기간입니다"

    sub_response = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub_response.json()["status"] == "active"


@pytest.mark.asyncio
async def test_already_processed_request_cannot_be_processed_again(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    created = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    refund_id = created.json()["id"]

    first = await client.patch(
        f"/api/v1/refund-requests/{refund_id}/reject",
        headers=auth_headers,
        json={"reject_reason": "환불 불가"},
    )
    assert first.status_code == 200

    second = await client.patch(
        f"/api/v1/refund-requests/{refund_id}/complete",
        headers=auth_headers,
        json={"processed_amount": 100000},
    )
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_other_teacher_cannot_process_refund_request(
    client: AsyncClient,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """A teacher who does not own the subscription's class cannot complete/reject it."""
    await _setup(create_test_user)
    await create_test_user(user_id="other-teacher-id", role="teacher", name="Other Teacher", email="other@test.com")
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    created = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    refund_id = created.json()["id"]

    from app.core.security import create_access_token

    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher-id', 'role': 'teacher'})}"
    }

    response = await client.patch(
        f"/api/v1/refund-requests/{refund_id}/complete",
        headers=other_headers,
        json={"processed_amount": 100000},
    )
    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_list_scoped_by_role(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )

    teacher_list = await client.get("/api/v1/refund-requests", headers=auth_headers)
    assert teacher_list.status_code == 200
    assert len(teacher_list.json()) == 1

    student_list = await client.get("/api/v1/refund-requests", headers=student_auth_headers)
    assert student_list.status_code == 200
    assert len(student_list.json()) == 1
    # Student view masks the account number.
    assert student_list.json()[0]["account_number"] != "123456789012"
    assert student_list.json()[0]["account_number"].endswith("9012")


@pytest.mark.asyncio
async def test_account_fields_redacted_after_retention_window(
    client: AsyncClient,
    auth_headers: dict,
    student_auth_headers: dict,
    create_test_user,
    db_session: AsyncSession,
):
    """Account fields are redacted for both roles once the 30-day window has passed."""
    from app.models.refund_request import RefundRequest

    await _setup(create_test_user)
    sub_id = await _seed_subscription(db_session, "test-user-id", "test-student-id")
    await db_session.commit()

    created = await client.post(
        "/api/v1/refund-requests",
        headers=student_auth_headers,
        json={"subscription_id": sub_id, **REFUND_PAYLOAD},
    )
    refund_id = created.json()["id"]

    await client.patch(
        f"/api/v1/refund-requests/{refund_id}/complete",
        headers=auth_headers,
        json={"processed_amount": 400000},
    )

    # Backdate processed_at beyond the retention window directly on the row.
    refund = await db_session.get(RefundRequest, refund_id)
    refund.processed_at = datetime.now(UTC) - timedelta(days=31)
    await db_session.commit()

    teacher_list = await client.get("/api/v1/refund-requests", headers=auth_headers)
    entry = teacher_list.json()[0]
    assert entry["bank_name"] is None
    assert entry["account_number"] is None
    assert entry["account_holder"] is None
