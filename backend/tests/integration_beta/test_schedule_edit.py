"""Remote beta scenario 3: Schedule change / rejection / no-show policy.

일정 변경 신청 / 거절 / 노쇼 정책 (no_show_policy 마이그레이션 검증).

Seed teacher (minyeon@example.com) is reused so we test against real seeded
schedule-change relationships.  Fresh student accounts are created per test
to avoid cross-test state pollution.

Teardown: lesson requests and lessons created here are cleaned up on a
best-effort basis.  Seed accounts themselves are never modified (role/email).
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient


def _future_date(days: int = 7) -> str:
    return (datetime.now(UTC).date() + timedelta(days=days)).isoformat()


@pytest.mark.asyncio
async def test_schedule_change_request_approved(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Teacher creates a schedule-change request for a student → approves it."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    student_account = BetaAccount(
        email=f"beta-sc-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(beta_teacher_account)
    await beta_client.dev_login(student_account, name=f"SC Student {suffix}")

    # Register the student under the seed teacher.
    created_student = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"SC Student {suffix}",
        instrument="violin",
        level="beginner",
        status="active",
        lesson_duration=60,
    )
    student_profile_id = created_student["id"]

    effective_date = _future_date(14)
    change = await beta_client.create_schedule_change(
        teacher_tokens.access_token,
        student_id=student_profile_id,
        change_type="singleLesson",
        new_day_of_week=2,  # Wednesday
        new_time="15:00",
        effective_from=effective_date,
        request_reason=f"beta-smoke schedule change {suffix}",
    )
    change_id = change["id"]
    assert change["status"] in ("pending", "requested"), (
        f"create_schedule_change: unexpected status {change['status']!r}"
    )

    # Approve the change.
    approved = await beta_client.respond_to_schedule_change(
        teacher_tokens.access_token,
        change_id,
        action="approved",
        response_message="일정 변경 승인합니다",
    )
    assert approved["status"] == "approved", (
        f"respond_to_schedule_change approved: expected approved, got {approved['status']!r}"
    )


@pytest.mark.asyncio
async def test_schedule_change_request_rejected(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Teacher creates a schedule-change request → rejects it."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    student_account = BetaAccount(
        email=f"beta-scr-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(beta_teacher_account)
    await beta_client.dev_login(student_account, name=f"SCR Student {suffix}")

    created_student = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"SCR Student {suffix}",
        instrument="piano",
        level="intermediate",
        status="active",
        lesson_duration=60,
    )
    student_profile_id = created_student["id"]

    effective_date = _future_date(10)
    change = await beta_client.create_schedule_change(
        teacher_tokens.access_token,
        student_id=student_profile_id,
        change_type="singleLesson",
        new_day_of_week=4,  # Friday
        new_time="11:00",
        effective_from=effective_date,
        request_reason=f"beta-smoke reject test {suffix}",
    )
    change_id = change["id"]

    rejected = await beta_client.respond_to_schedule_change(
        teacher_tokens.access_token,
        change_id,
        action="rejected",
        response_message="해당 시간에 다른 수업이 있어 불가합니다",
    )
    assert rejected["status"] == "rejected", (
        f"respond_to_schedule_change rejected: expected rejected, got {rejected['status']!r}"
    )


@pytest.mark.asyncio
async def test_no_show_policy_deduct_credit(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Teacher marks a lesson as no-show with deductCredit policy — record is created."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    student_account = BetaAccount(
        email=f"beta-ns-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(beta_teacher_account)
    await beta_client.dev_login(student_account, name=f"NS Student {suffix}")

    created_student = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"NS Student {suffix}",
        instrument="violin",
        level="beginner",
        status="active",
        lesson_duration=60,
    )
    student_profile_id = created_student["id"]

    # Create a lesson in the past so it can be marked.
    lesson_date = (datetime.now(UTC).date() - timedelta(days=1)).isoformat()
    lesson = await beta_client.create_lesson(
        teacher_tokens.access_token,
        student_id=student_profile_id,
        date=lesson_date,
        start_time="10:00",
        duration=60,
    )
    lesson_id = lesson["id"]

    # Mark the lesson as noShow via lesson status endpoint.
    no_showed = await beta_client.update_lesson_status(
        teacher_tokens.access_token,
        lesson_id,
        status="noShow",
    )
    assert no_showed["status"] == "noShow", f"update_lesson_status noShow: expected noShow, got {no_showed['status']!r}"

    # Record the no-show policy (deductCredit).
    no_show_record = await beta_client.create_no_show(
        teacher_tokens.access_token,
        lesson_id=lesson_id,
        student_id=student_profile_id,
        lesson_date=lesson_date,
        applied_policy="deductCredit",
        deducted_credits=1,
        note=f"beta-smoke no-show {suffix}",
    )
    assert no_show_record["applied_policy"] == "deductCredit", (
        f"create_no_show: expected deductCredit, got {no_show_record['applied_policy']!r}"
    )
    assert no_show_record["deducted_credits"] == 1, (
        f"create_no_show: expected deducted_credits=1, got {no_show_record['deducted_credits']}"
    )
    assert no_show_record["lesson_id"] == lesson_id, "create_no_show: lesson_id mismatch"
