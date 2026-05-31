"""Tests for auto subscription creation when creating lessons without subscription_id."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_lesson_without_subscription_creates_trial(
    teacher, client: AsyncClient, auth_headers: dict
):
    """Creating a lesson without subscription_id should auto-create a trial subscription."""
    sid = await teacher.create_student("김테스트")

    # Create lesson with no subscription_id
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-06-01", "start_time": "14:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()

    # Lesson must be linked to a subscription
    assert lesson["subscription_id"] is not None, "Expected auto-created subscription_id"
    assert lesson["session_number"] is not None, "Expected session_number from auto subscription"


@pytest.mark.asyncio
async def test_create_lesson_reuses_active_subscription(
    teacher, client: AsyncClient, auth_headers: dict
):
    """Creating a lesson without subscription_id should reuse existing active subscription."""
    sid = await teacher.create_student("박재사용")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)

    # Create lesson with no subscription_id
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-06-01", "start_time": "10:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()

    # Should reuse the existing active subscription
    assert lesson["subscription_id"] == sub_id, (
        f"Expected existing subscription {sub_id}, got {lesson['subscription_id']}"
    )


@pytest.mark.asyncio
async def test_trial_subscription_has_correct_defaults(
    teacher, client: AsyncClient, auth_headers: dict
):
    """Auto-created trial subscription should have correct field values."""
    sid = await teacher.create_student("이기본값")

    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-07-15", "start_time": "11:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()
    sub_id = lesson["subscription_id"]
    assert sub_id is not None

    # Fetch the subscription and verify defaults
    r = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert r.status_code == 200, f"get_subscription failed: {r.status_code} {r.text}"
    sub = r.json()

    assert sub["type"] == "trial"
    assert sub["amount"] == 0
    assert sub["total_lessons"] == 1
    assert sub["payment_confirmed"] is True
    assert sub["total_reschedule_allowance"] == 0
    assert sub["status"] == "active"
