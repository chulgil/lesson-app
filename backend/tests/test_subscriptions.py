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
