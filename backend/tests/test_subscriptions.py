"""Subscription, template, and proposal endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_subscription(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions creates a subscription (teacher only) and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 8,
            "amount": 200000,
            "start_date": "2026-03-01",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "student-001"
    assert data["total_lessons"] == 8
    assert data["remaining_lessons"] == 8
    assert "id" in data


@pytest.mark.asyncio
async def test_create_subscription_preserves_pending_deposit_status(
    client: AsyncClient, auth_headers, create_test_user
):
    """Immediate issue can create a subscription waiting for deposit confirmation."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 8,
            "amount": 200000,
            "payment_confirmed": False,
            "payment_method": "bankTransfer",
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["payment_confirmed"] is False
    assert data["payment_method"] == "bankTransfer"
    assert data["payment_status"] == "pending"


@pytest.mark.asyncio
async def test_list_subscriptions(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/subscriptions returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a subscription first
    await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 4,
            "amount": 100000,
        },
    )

    response = await client.get("/api/v1/subscriptions", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_use_lesson_deduction(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/subscriptions/{id}/use-lesson deducts a lesson."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    sub_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/use-lesson",
        headers=auth_headers,
        json={"lesson_id": "lesson-001", "type": "lesson"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["used_lessons"] == 1
    assert data["remaining_lessons"] == 7


@pytest.mark.asyncio
async def test_create_subscription_template(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions-templates creates a template and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "name": "Basic Monthly",
            "type": "monthly",
            "lessons_count": 4,
            "amount": 100000,
            "description": "4 lessons per month",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Basic Monthly"
    assert data["lessons_count"] == 4
    assert data["teacher_id"] == "test-user-id-prof"


@pytest.mark.asyncio
async def test_subscription_template_frontend_contract_aliases_and_actions(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend template repository sends/receives owner/price/total aliases and uses detail actions."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "owner_id": "test-user-id-prof",
            "owner_type": "teacher",
            "name": "8회권",
            "total_lessons": 8,
            "lesson_duration_minutes": 50,
            "validity_days": 90,
            "price": 400000,
            "display_order": 2,
            "reschedule_allowance": 1,
            "is_auto_proposal_enabled": True,
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["owner_id"] == "test-user-id-prof"
    assert created["owner_type"] == "teacher"
    assert created["total_lessons"] == 8
    assert created["price"] == 400000

    template_id = created["id"]
    detail_response = await client.get(
        f"/api/v1/subscriptions-templates/{template_id}",
        headers=auth_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == template_id

    toggle_response = await client.patch(
        f"/api/v1/subscriptions-templates/{template_id}/toggle-active",
        headers=auth_headers,
    )
    assert toggle_response.status_code == 200
    assert toggle_response.json()["is_active"] is False

    reorder_response = await client.patch(
        "/api/v1/subscriptions-templates/reorder",
        headers=auth_headers,
        json={"ordered_ids": [template_id]},
    )
    assert reorder_response.status_code == 204


@pytest.mark.asyncio
async def test_create_subscription_proposal(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions-proposals creates a proposal and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "message": "Please review this subscription plan",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "student-001"
    assert data["status"] == "pending"
    assert data["teacher_id"] == "test-user-id-prof"


@pytest.mark.asyncio
async def test_subscription_proposal_notify_payment_action_marks_deposit_notified(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Student can notify manual deposit without using the legacy accept action."""
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
        json={
            "student_id": "test-student-id",
            "message": "입금 안내를 확인해주세요.",
        },
    )
    proposal_id = create_response.json()["id"]

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "notify_payment"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "paymentNotified"
    assert data["payment_notified_at"] is not None


@pytest.mark.asyncio
async def test_subscription_proposal_frontend_contract_detail_and_expire(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend proposal repository can fetch one proposal and trigger expiry processing."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "template_ids": ["template-a", "template-b"],
            "recommended_template_id": "template-a",
            "message": "수강권을 선택해주세요.",
        },
    )
    assert create_response.status_code == 201
    proposal_id = create_response.json()["id"]

    detail_response = await client.get(
        f"/api/v1/subscriptions-proposals/{proposal_id}",
        headers=auth_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == proposal_id

    expire_response = await client.post(
        "/api/v1/subscriptions-proposals/expire",
        headers=auth_headers,
    )
    assert expire_response.status_code == 200
    assert "message" in expire_response.json()


@pytest.mark.asyncio
async def test_subscription_proposal_frontend_contract_action_aliases(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Frontend proposal repository sends template_id/reason aliases and cancel action."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student-proposal-alias@test.com",
    )

    select_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "test-student-id",
            "template_ids": ["template-a", "template-b"],
            "recommended_template_id": "template-a",
            "message": "수강권을 선택해주세요.",
        },
    )
    select_proposal_id = select_response.json()["id"]
    selected = await client.patch(
        f"/api/v1/subscriptions-proposals/{select_proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "select_template", "template_id": "template-b"},
    )
    assert selected.status_code == 200
    assert selected.json()["status"] == "paymentNotified"
    assert selected.json()["selected_template_id"] == "template-b"

    reject_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "거절 테스트"},
    )
    reject_proposal_id = reject_response.json()["id"]
    rejected = await client.patch(
        f"/api/v1/subscriptions-proposals/{reject_proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "reject", "reason": "다음 달에 할게요"},
    )
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "rejected"
    assert rejected.json()["rejection_reason"] == "다음 달에 할게요"

    cancel_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "취소 테스트"},
    )
    cancel_proposal_id = cancel_response.json()["id"]
    cancelled = await client.patch(
        f"/api/v1/subscriptions-proposals/{cancel_proposal_id}/respond",
        headers=auth_headers,
        json={"action": "cancel"},
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"


@pytest.mark.asyncio
async def test_subscription_usage_frontend_contract_paginated_and_usage_type(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend usage repository expects {items: [...]} and usage_type/created_at fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    subscription_id = create_response.json()["id"]

    usage_response = await client.post(
        f"/api/v1/subscriptions/{subscription_id}/usage",
        headers=auth_headers,
        json={
            "lesson_id": "lesson-001",
            "usage_type": "lateCancellation",
            "teacher_name": "김선생",
            "instrument": "violin",
            "note": "당일 취소",
            "deducted": True,
        },
    )
    assert usage_response.status_code == 201
    usage = usage_response.json()
    assert usage["usage_type"] == "lateCancellation"
    assert usage["created_at"] is not None
    assert usage["teacher_name"] == "김선생"
    assert usage["instrument"] == "violin"
    assert usage["note"] == "당일 취소"

    history_response = await client.get(
        f"/api/v1/subscriptions/{subscription_id}/usage",
        headers=auth_headers,
    )
    assert history_response.status_code == 200
    history = history_response.json()
    assert "items" in history
    assert history["items"][0]["usage_type"] == "lateCancellation"
    assert history["items"][0]["teacher_name"] == "김선생"
