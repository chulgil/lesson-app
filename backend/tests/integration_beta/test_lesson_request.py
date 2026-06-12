"""Remote beta scenario 2: Lesson request lifecycle.

학생 신청 → 선생님 슬롯 제안 → 학생 확정 → 일정 생성.

Seed pool reuse: fresh (uuid-suffixed) accounts for teacher + student so the
test can run repeatedly without colliding with other sessions or the seed accounts.
Resources created in this test (lesson_request) are deleted in teardown via
the delete endpoint; the temporary user accounts are ephemeral on beta.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient


def _next_weekday(day_of_week: int) -> str:
    """Return ISO date string for the next occurrence of ``day_of_week`` (0=Mon)."""
    today = datetime.now(UTC).date()
    days_ahead = (day_of_week - today.weekday() + 7) % 7 or 7
    return (today + timedelta(days=days_ahead)).isoformat()


@pytest.mark.asyncio
async def test_lesson_request_student_to_teacher_approve(beta_client: BetaClient) -> None:
    """Student submits request → teacher approves → request reaches confirmed state."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    teacher_account = BetaAccount(
        email=f"beta-lr-teacher-{suffix}@example.com",
        role="teacher",
        expected_user_id="",
    )
    student_account = BetaAccount(
        email=f"beta-lr-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(teacher_account, name=f"LR Teacher {suffix}")
    student_tokens = await beta_client.dev_login(student_account, name=f"LR Student {suffix}")

    teacher_user = teacher_tokens.user
    teacher_id = teacher_user["id"]

    # Student submits a lesson request to the teacher.
    preferred_day = (datetime.now(UTC).date().weekday() + 2) % 7  # two days ahead weekday
    request = await beta_client.create_lesson_request(
        student_tokens.access_token,
        teacher_id=teacher_id,
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=preferred_day,
        preferred_time="14:00",
        preferred_duration=60,
        message=f"beta smoke {suffix}",
    )
    request_id = request["id"]
    assert request["status"] in ("pending", "submitted"), (
        f"create_lesson_request: expected pending/submitted, got {request['status']!r}"
    )
    assert request["teacher_id"] == teacher_id, "teacher_id mismatch after create"

    try:
        # Teacher fetches the request.
        fetched = await beta_client.get_lesson_request(teacher_tokens.access_token, request_id)
        assert fetched["id"] == request_id, "get_lesson_request: id mismatch"

        # Teacher approves directly (no alternative proposal).
        approved = await beta_client.update_lesson_request_status(
            teacher_tokens.access_token,
            request_id,
            status="approved",
        )
        assert approved["status"] == "approved", (
            f"update_lesson_request_status: expected approved, got {approved['status']!r}"
        )

        # Student can read the approved state.
        student_view = await beta_client.get_lesson_request(student_tokens.access_token, request_id)
        assert student_view["status"] == "approved", (
            f"student view after teacher approval: expected approved, got {student_view['status']!r}"
        )
    finally:
        # Best-effort cleanup — delete the request so repeated runs stay clean.
        try:
            await beta_client.delete_lesson_request(teacher_tokens.access_token, request_id)
        except Exception:  # noqa: BLE001
            pass


@pytest.mark.asyncio
async def test_lesson_request_teacher_proposes_alternatives_student_accepts(
    beta_client: BetaClient,
) -> None:
    """Teacher proposes 2 alternative slots → student accepts slot 0."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    teacher_account = BetaAccount(
        email=f"beta-alt-teacher-{suffix}@example.com",
        role="teacher",
        expected_user_id="",
    )
    student_account = BetaAccount(
        email=f"beta-alt-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(teacher_account, name=f"Alt Teacher {suffix}")
    student_tokens = await beta_client.dev_login(student_account, name=f"Alt Student {suffix}")
    teacher_id = teacher_tokens.user["id"]

    request = await beta_client.create_lesson_request(
        student_tokens.access_token,
        teacher_id=teacher_id,
        request_type="trial",
        instrument="piano",
        goal="hobby",
        experience_level="beginner",
        preferred_duration=60,
    )
    request_id = request["id"]

    try:
        # Teacher proposes 2 alternative slots.
        slot_date_0 = _next_weekday(0)  # next Monday
        slot_date_1 = _next_weekday(2)  # next Wednesday
        proposed = await beta_client.propose_alternatives(
            teacher_tokens.access_token,
            request_id,
            slots=[
                {"date": slot_date_0, "time": "10:00"},
                {"date": slot_date_1, "time": "14:00"},
            ],
            message="이 중 편한 시간으로 선택해 주세요",
        )
        assert proposed["status"] in ("negotiating", "alternativeProposed", "proposed"), (
            f"propose_alternatives: unexpected status {proposed['status']!r}"
        )

        # Student accepts the first slot (index 0).
        accepted = await beta_client.accept_alternative(
            student_tokens.access_token,
            request_id,
            selected_slot_index=0,
        )
        assert accepted["status"] in ("confirmed", "approved", "accepted"), (
            f"accept_alternative: unexpected status {accepted['status']!r}"
        )
    finally:
        try:
            await beta_client.delete_lesson_request(teacher_tokens.access_token, request_id)
        except Exception:  # noqa: BLE001
            pass


@pytest.mark.asyncio
async def test_lesson_request_teacher_rejects(beta_client: BetaClient) -> None:
    """Teacher rejects a student request → request reaches rejected state."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    teacher_account = BetaAccount(
        email=f"beta-rej-teacher-{suffix}@example.com",
        role="teacher",
        expected_user_id="",
    )
    student_account = BetaAccount(
        email=f"beta-rej-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(teacher_account, name=f"Rej Teacher {suffix}")
    student_tokens = await beta_client.dev_login(student_account, name=f"Rej Student {suffix}")
    teacher_id = teacher_tokens.user["id"]

    request = await beta_client.create_lesson_request(
        student_tokens.access_token,
        teacher_id=teacher_id,
        request_type="trial",
        instrument="cello",
        goal="hobby",
        experience_level="beginner",
        preferred_duration=60,
    )
    request_id = request["id"]

    # Teacher rejects with a reason.
    rejected = await beta_client.update_lesson_request_status(
        teacher_tokens.access_token,
        request_id,
        status="rejected",
        decline_reason="일정이 맞지 않습니다",
    )
    assert rejected["status"] == "rejected", (
        f"update_lesson_request_status rejected: expected rejected, got {rejected['status']!r}"
    )
