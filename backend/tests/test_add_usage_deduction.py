"""#743 — add_usage must decrement remaining (bump used_lessons) when deducted=True.

The FE auto-deduct flows (lesson confirmation / add past lesson) POST
/subscriptions/{id}/usage with deducted=True expecting the session to be
counted against the subscription. Before the fix add_usage only inserted a
SubscriptionUsage row and left used_lessons untouched -> remaining (computed
from used_lessons) was under-counted, effectively granting free sessions.

deducted=False rows are history-only and must NOT touch the counter.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient


async def _create_subscription(client: AsyncClient, auth_headers) -> str:
    resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={"student_id": "student-001", "total_lessons": 8, "amount": 200000},
    )
    assert resp.status_code in (200, 201), resp.text
    assert resp.json()["used_lessons"] == 0
    return resp.json()["id"]


@pytest.mark.asyncio
async def test_add_usage_deducted_true_increments_used_lessons(client: AsyncClient, auth_headers, create_test_user):
    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_subscription(client, auth_headers)

    resp = await client.post(
        f"/api/v1/subscriptions/{sub_id}/usage",
        headers=auth_headers,
        json={"lesson_id": "lesson-1", "usage_type": "lateCancellation", "deducted": True},
    )
    assert resp.status_code == 201, resp.text

    detail = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert detail.status_code == 200, detail.text
    body = detail.json()
    assert body["used_lessons"] == 1, "deducted usage must bump used_lessons"
    assert body["remaining_lessons"] == 7, "remaining must decrement (8 - 1)"


@pytest.mark.asyncio
async def test_add_usage_deducted_false_leaves_counter(client: AsyncClient, auth_headers, create_test_user):
    await create_test_user(user_id="test-user-id", role="teacher")
    sub_id = await _create_subscription(client, auth_headers)

    resp = await client.post(
        f"/api/v1/subscriptions/{sub_id}/usage",
        headers=auth_headers,
        json={"lesson_id": "lesson-2", "usage_type": "lateCancellation", "deducted": False},
    )
    assert resp.status_code == 201, resp.text

    detail = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    body = detail.json()
    assert body["used_lessons"] == 0, "history-only (deducted=False) must NOT bump used_lessons"
    assert body["remaining_lessons"] == 8
