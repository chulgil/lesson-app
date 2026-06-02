"""Phone verification hard gate on proposal confirmation — #10 A-C2 Phase A."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.teacher import Teacher


def _student_headers(user_id: str = "test-student-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


async def _set_teacher_phone_verified(db: AsyncSession, user_id: str, verified: bool) -> None:
    teacher_row = await db.scalar(select(Teacher).where(Teacher.user_id == user_id))
    assert teacher_row is not None
    teacher_row.is_phone_verified = verified
    if not verified:
        teacher_row.phone_verified_at = None
    await db.flush()


async def _create_payment_notified_proposal(
    client: AsyncClient,
    auth_headers: dict,
    db_session: AsyncSession,
    create_test_user,
) -> str:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )

    create_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "입금 안내"},
    )
    assert create_response.status_code == 201, create_response.text
    proposal_id = create_response.json()["id"]

    notify = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=_student_headers(),
        json={"action": "notify_payment"},
    )
    assert notify.status_code == 200, notify.text
    return proposal_id


@pytest.mark.asyncio
async def test_unverified_teacher_cannot_confirm_proposal(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    proposal_id = await _create_payment_notified_proposal(client, auth_headers, db_session, create_test_user)
    await _set_teacher_phone_verified(db_session, "test-user-id", verified=False)

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={"payment_method": "bankTransfer"},
    )

    assert response.status_code == 409, response.text
    body = response.json()
    assert body["error"]["code"] == "phone_verification_required"


@pytest.mark.asyncio
async def test_verified_teacher_can_confirm_proposal(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    proposal_id = await _create_payment_notified_proposal(client, auth_headers, db_session, create_test_user)

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={"payment_method": "bankTransfer"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "confirmed"
