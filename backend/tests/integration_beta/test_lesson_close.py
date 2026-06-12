"""Remote beta scenario 4: Lesson completion → subscription remaining count -1 → progress.

레슨 완료 → 수강권 잔여 회차 -1 → 진행률 갱신.

Seed teacher (minyeon@example.com) is reused.  A fresh student + subscription
are created per test run.  The lesson is dated yesterday so the status
transition to 'completed' is valid on the server.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient


def _yesterday() -> str:
    return (datetime.now(UTC).date() - timedelta(days=1)).isoformat()


@pytest.mark.asyncio
async def test_complete_lesson_deducts_subscription_remaining(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Complete a lesson → subscription used_lessons +1, remaining_lessons -1."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    teacher_tokens = await beta_client.dev_login(beta_teacher_account)

    # Create a fresh student and subscription.
    student = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"Close Student {suffix}",
        instrument="violin",
        level="beginner",
        status="active",
        lesson_duration=60,
    )
    student_id = student["id"]

    subscription = await beta_client.create_subscription(
        teacher_tokens.access_token,
        student_id=student_id,
        type="package",
        total_lessons=10,
        amount=500000,
    )
    sub_id = subscription["id"]
    initial_remaining = subscription.get("remaining_lessons")
    initial_used = subscription.get("used_lessons", 0)

    # Create a lesson dated yesterday so it can be completed.
    lesson = await beta_client.create_lesson(
        teacher_tokens.access_token,
        student_id=student_id,
        date=_yesterday(),
        start_time="14:00",
        duration=60,
    )
    lesson_id = lesson["id"]

    # Deduct the lesson from the subscription before completing.
    await beta_client.use_lesson(teacher_tokens.access_token, sub_id, lesson_id)

    # Mark the lesson as completed.
    completed = await beta_client.update_lesson_status(teacher_tokens.access_token, lesson_id, status="completed")
    assert completed["status"] == "completed", (
        f"update_lesson_status completed: expected completed, got {completed['status']!r}"
    )

    # Verify subscription remaining count decreased by 1.
    sub_after = await beta_client.get_subscription(teacher_tokens.access_token, sub_id)
    used_after = sub_after.get("used_lessons", 0)
    remaining_after = sub_after.get("remaining_lessons")

    assert used_after == initial_used + 1, f"used_lessons after complete: expected {initial_used + 1}, got {used_after}"
    if initial_remaining is not None and remaining_after is not None:
        assert remaining_after == initial_remaining - 1, (
            f"remaining_lessons after complete: expected {initial_remaining - 1}, got {remaining_after}"
        )


@pytest.mark.asyncio
async def test_complete_lesson_updates_progress(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Complete 2 lessons from a 5-lesson subscription → progress reaches 40%."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    teacher_tokens = await beta_client.dev_login(beta_teacher_account)

    student = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"Progress Student {suffix}",
        instrument="piano",
        level="beginner",
        status="active",
        lesson_duration=60,
    )
    student_id = student["id"]

    subscription = await beta_client.create_subscription(
        teacher_tokens.access_token,
        student_id=student_id,
        type="package",
        total_lessons=5,
        amount=250000,
    )
    sub_id = subscription["id"]

    completed_ids: list[str] = []
    for offset in range(1, 3):  # yesterday and 2 days ago
        lesson_date = (datetime.now(UTC).date() - timedelta(days=offset)).isoformat()
        lesson = await beta_client.create_lesson(
            teacher_tokens.access_token,
            student_id=student_id,
            date=lesson_date,
            start_time="10:00",
            duration=60,
        )
        lesson_id = lesson["id"]
        await beta_client.use_lesson(teacher_tokens.access_token, sub_id, lesson_id)
        await beta_client.update_lesson_status(teacher_tokens.access_token, lesson_id, status="completed")
        completed_ids.append(lesson_id)

    sub_after = await beta_client.get_subscription(teacher_tokens.access_token, sub_id)
    used_after = sub_after.get("used_lessons", 0)
    total = sub_after.get("total_lessons", 5)

    assert used_after == 2, f"used_lessons after 2 completions: expected 2, got {used_after}"
    assert total == 5, f"total_lessons: expected 5, got {total}"

    # Progress as percentage (used / total * 100).
    progress_pct = used_after / total * 100
    assert progress_pct == 40.0, f"progress: expected 40.0%, got {progress_pct}%"
