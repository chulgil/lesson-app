"""Phone verification hard gate at subscription issuance (#430).

Spec: docs/specs/user/phone_verification_policy.md §4.2 — first subscription
issuance requires a verified teacher phone number. Returns 409 with code
``phone_verification_required`` so the frontend can intercept and route to the
verification flow.
"""

from __future__ import annotations

import pytest
from sqlalchemy import select

from app.models.teacher import Teacher
from tests.scenarios.helpers import TeacherActions


@pytest.mark.asyncio
async def test_unverified_teacher_cannot_issue_subscription(teacher: TeacherActions, db_session):
    """Unverified teacher gets 409 + phone_verification_required when issuing."""
    # Flip the default-verified fixture teacher back to unverified.
    teacher_row = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    assert teacher_row is not None
    teacher_row.is_phone_verified = False
    teacher_row.phone_verified_at = None
    await db_session.flush()

    sid = await teacher.create_student("게이트 학생")

    payload = {
        "student_id": sid,
        "type": "package",
        "total_lessons": 4,
        "amount": 160000,
    }
    response = await teacher.client.post(
        f"{teacher._base}/subscriptions",
        headers=teacher.headers,
        json=payload,
    )

    assert response.status_code == 409, response.text
    body = response.json()
    assert body["error"]["code"] == "phone_verification_required"


@pytest.mark.asyncio
async def test_verified_teacher_can_issue_subscription(teacher: TeacherActions):
    """Default-verified fixture teacher passes the gate and issues a subscription."""
    sid = await teacher.create_student("정상 학생")
    sub_id = await teacher.create_subscription(
        sid,
        total_lessons=4,
        amount=160000,
        payment_confirmed=False,
    )
    assert sub_id
