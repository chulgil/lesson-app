"""Tests for invite, connection request, and connection endpoints."""

import pytest
from httpx import AsyncClient


# ---------------------------------------------------------------------------
# Invites
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_invite(client: AsyncClient, auth_headers, create_test_user):
    """POST /invites/ should create a new invite with a code."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"is_single_use": True, "expires_in_hours": 24},
    )
    assert response.status_code == 201
    data = response.json()
    assert "id" in data
    assert data["invite_code"] is not None
    assert len(data["invite_code"]) == 6
    assert data["is_single_use"] is True
    assert data["status"] == "active"
    assert data["use_count"] == 0


@pytest.mark.asyncio
async def test_list_invites(client: AsyncClient, auth_headers, create_test_user):
    """GET /invites/ should return paginated invites."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create two invites
    await client.post("/api/v1/invites/", headers=auth_headers, json={})
    await client.post("/api/v1/invites/", headers=auth_headers, json={})

    response = await client.get("/api/v1/invites/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert len(data["items"]) == 2


@pytest.mark.asyncio
async def test_revoke_invite(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /invites/{id}/revoke should set status to 'revoked'."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    invite_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/invites/{invite_id}/revoke",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["status"] == "revoked"


@pytest.mark.asyncio
async def test_revoke_nonexistent_invite(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /invites/{id}/revoke with bad ID should return 404."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.patch(
        "/api/v1/invites/nonexistent-id/revoke",
        headers=auth_headers,
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_create_invite_unauthenticated(client: AsyncClient):
    """POST /invites/ without auth should return 401."""
    response = await client.post("/api/v1/invites/", json={})
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Connection Requests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_connection_request(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """POST /invites/connection-requests should create a request."""
    teacher = await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    # Student creates connection request to teacher
    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["requester_id"] == "test-student-id"
    assert data["target_id"] == "test-user-id"
    assert data["status"] == "pending"


@pytest.mark.asyncio
async def test_list_pending_requests(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """GET /invites/connection-requests/pending should list pending requests."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    # Student creates request
    await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )

    # Teacher sees pending requests
    response = await client.get(
        "/api/v1/invites/connection-requests/pending",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1


@pytest.mark.asyncio
async def test_accept_connection_request(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """PATCH respond with 'accept' should create a Connection."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    create_resp = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    req_id = create_resp.json()["id"]

    # Teacher accepts
    response = await client.patch(
        f"/api/v1/invites/connection-requests/{req_id}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"

    # Verify connection was created
    conn_resp = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert conn_resp.json()["total"] == 1


@pytest.mark.asyncio
async def test_reject_connection_request(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """PATCH respond with 'reject' should set status rejected with reason."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    create_resp = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    req_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/invites/connection-requests/{req_id}/respond",
        headers=auth_headers,
        json={"action": "reject", "rejection_reason": "Not my student"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "rejected"
    assert response.json()["rejection_reason"] == "Not my student"


# ---------------------------------------------------------------------------
# Connections
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_connections_empty(client: AsyncClient, auth_headers, create_test_user):
    """GET /invites/connections with no connections should return empty."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["total"] == 0


@pytest.mark.asyncio
async def test_deactivate_connection(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """DELETE /invites/connections/{id} should deactivate."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    # Create and accept connection
    cr = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    await client.patch(
        f"/api/v1/invites/connection-requests/{cr.json()['id']}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )

    conn_resp = await client.get("/api/v1/invites/connections", headers=auth_headers)
    conn_id = conn_resp.json()["items"][0]["id"]

    # Deactivate
    response = await client.delete(
        f"/api/v1/invites/connections/{conn_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204

    # Verify it's gone from active list
    after = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert after.json()["total"] == 0
