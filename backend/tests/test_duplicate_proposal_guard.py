"""Duplicate proposal guard — §3.1.5 single active proposal constraint (#696).

Spec: docs/specs/subscription/subscription_master.md §3.1.5
"""

from __future__ import annotations

import pytest

from tests.scenarios.helpers import TeacherActions


@pytest.mark.asyncio
async def test_duplicate_proposal_blocked_409(teacher: TeacherActions) -> None:
    """Second proposal to same student while first is pending → 409 active_proposal_exists."""
    sid = await teacher.create_student("중복테스트 학생")
    template_id = await teacher.create_template("8회권", lessons_count=8, amount=320000)

    # First proposal should succeed.
    first_id = await teacher.send_proposal(sid, template_id)
    assert first_id

    # Second proposal to the same student (still pending) must be rejected.
    payload = {
        "student_id": sid,
        "template_id": template_id,
        "template_ids": [template_id],
        "recommended_template_id": template_id,
    }
    response = await teacher.client.post(
        f"{teacher._base}/subscriptions-proposals",
        headers=teacher.headers,
        json=payload,
    )

    assert response.status_code == 409, response.text
    body = response.json()
    # FastAPI wraps HTTPException detail → {"detail": {...}} for dict details.
    detail = body.get("detail") or body.get("error", {})
    if isinstance(detail, dict):
        assert detail.get("error") == "active_proposal_exists"
        assert detail.get("proposalId") == first_id
    else:
        # Tolerate wrapper structure from exception handler.
        assert "active_proposal_exists" in response.text


@pytest.mark.asyncio
async def test_new_proposal_allowed_after_cancel(teacher: TeacherActions) -> None:
    """After cancelling the existing proposal, a new one can be created successfully."""
    sid = await teacher.create_student("취소후재제안 학생")
    template_id = await teacher.create_template("4회권", lessons_count=4, amount=160000)

    # Create initial proposal.
    first_id = await teacher.send_proposal(sid, template_id)

    # Revoke (teacher-side cancel) it.
    cancel_response = await teacher.client.post(
        f"{teacher._base}/subscriptions-proposals/{first_id}/revoke",
        headers=teacher.headers,
        json={},
    )
    assert cancel_response.status_code == 200, cancel_response.text

    # Now a new proposal should succeed.
    payload = {
        "student_id": sid,
        "template_id": template_id,
        "template_ids": [template_id],
        "recommended_template_id": template_id,
    }
    response = await teacher.client.post(
        f"{teacher._base}/subscriptions-proposals",
        headers=teacher.headers,
        json=payload,
    )
    assert response.status_code == 201, response.text
    new_id = response.json()["id"]
    assert new_id != first_id
