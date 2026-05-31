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
async def test_create_invite_returns_frontend_deep_link_qr_contract(
    client: AsyncClient, auth_headers, create_test_user
):
    """Created invites should match the frontend QR parser and mock repository URL contract."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={},
    )

    assert response.status_code == 201
    data = response.json()
    expected_link = f"lessonapp://invite/{data['invite_code']}"
    assert data["invite_url"] == expected_link
    assert data["qr_code_data"] == expected_link


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


@pytest.mark.asyncio
async def test_get_invite_by_id_and_code_for_frontend_confirm_screen(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """RemoteInviteRepository needs direct invite lookup for scanned/shared codes."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    invite = create_resp.json()

    by_id = await client.get(f"/api/v1/invites/{invite['id']}", headers=student_auth_headers)
    assert by_id.status_code == 200
    assert by_id.json()["id"] == invite["id"]

    by_code = await client.get(
        f"/api/v1/invites/code/{invite['invite_code']}",
        headers=student_auth_headers,
    )
    assert by_code.status_code == 200
    assert by_code.json()["id"] == invite["id"]


@pytest.mark.asyncio
async def test_public_invite_landing_returns_json_contract(
    client: AsyncClient, auth_headers, create_test_user
):
    """Ghost consumes JSON data from the public invite landing API."""
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")

    create_resp = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    invite = create_resp.json()

    response = await client.get(f"/api/v1/public/invites/{invite['invite_code']}/landing")

    assert response.status_code == 200, response.text
    assert response.headers["content-type"].startswith("application/json")
    data = response.json()
    assert data["code"] == invite["invite_code"]
    assert data["status"] == "active"
    assert data["teacher"]["name"] == "홍길동"
    assert data["share"]["url"].endswith(f"/invite/{invite['invite_code']}")
    assert data["share"]["app_deep_link"] == f"lessonapp://invite/{invite['invite_code']}"


@pytest.mark.asyncio
async def test_public_invite_landing_returns_404_for_unknown_code(client: AsyncClient):
    response = await client.get("/api/v1/public/invites/UNKNOWN/landing")

    assert response.status_code == 404


# ---------------------------------------------------------------------------
# Connection Requests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_connection_request(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """POST /invites/connection-requests should create a request."""
    await create_test_user(user_id="test-user-id", role="teacher")
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
async def test_duplicate_pending_connection_request_keeps_latest_only(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Repeated student requests to the same teacher should refresh one pending request."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    first = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "test-user-id",
            "method": "inAppSearch",
            "message": "first",
        },
    )
    assert first.status_code == 201

    second = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "test-user-id",
            "method": "inAppSearch",
            "message": "second",
        },
    )
    assert second.status_code == 201
    assert second.json()["id"] == first.json()["id"]
    assert second.json()["message"] == "second"

    pending = await client.get(
        "/api/v1/invites/connection-requests/pending",
        headers=auth_headers,
    )
    assert pending.status_code == 200
    assert pending.json()["total"] == 1
    assert pending.json()["items"][0]["message"] == "second"

    sent = await client.get(
        "/api/v1/invites/connection-requests/sent",
        headers=student_auth_headers,
    )
    assert sent.status_code == 200
    assert sent.json()["total"] == 1
    assert sent.json()["items"][0]["message"] == "second"

    notifications = await client.get("/api/v1/notifications", headers=auth_headers)
    assert notifications.status_code == 200
    notification_items = notifications.json()["items"]
    connection_notifications = [
        item
        for item in notification_items
        if item["type"] == "connectionRequestReceived"
    ]
    assert len(connection_notifications) == 1
    assert connection_notifications[0]["action_url"] == "/invite/requests"
    assert connection_notifications[0]["data"]["connectionRequestId"] == first.json()["id"]


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
async def test_accept_invite_code_request_adds_student_to_teacher_roster(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Accepting a student's invite-code request should attach their profile to the teacher roster."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    profile = await client.post(
        "/api/v1/students/me/profile",
        headers=student_auth_headers,
        json={"name": "Student", "instrument": "피아노", "level": "beginner"},
    )
    assert profile.status_code == 201, profile.text
    student_id = profile.json()["id"]

    invite_resp = await client.post("/api/v1/invites/", headers=auth_headers, json={})
    invite = invite_resp.json()

    request_resp = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "",
            "method": "inviteCode",
            "invite_code": invite["invite_code"],
        },
    )
    assert request_resp.status_code == 201, request_resp.text

    accept = await client.patch(
        f"/api/v1/invites/connection-requests/{request_resp.json()['id']}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert accept.status_code == 200, accept.text

    roster = await client.get("/api/v1/students", headers=auth_headers)
    assert roster.status_code == 200, roster.text
    assert roster.json()["total"] == 1
    assert roster.json()["items"][0]["id"] == student_id
    assert roster.json()["items"][0]["teacher_id"] == "test-user-id-prof"


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


@pytest.mark.asyncio
async def test_invite_code_request_tracks_usage_and_single_use_status(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Student invite-code onboarding should consume single-use invites."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"is_single_use": True},
    )
    invite = create_resp.json()

    response = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "",
            "method": "inviteCode",
            "invite_code": invite["invite_code"],
        },
    )
    assert response.status_code == 201
    assert response.json()["target_id"] == "test-user-id"

    refreshed = await client.get(f"/api/v1/invites/{invite['id']}", headers=auth_headers)
    assert refreshed.json()["use_count"] == 1
    assert refreshed.json()["status"] == "used"

    second = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "",
            "method": "inviteCode",
            "invite_code": invite["invite_code"],
        },
    )
    assert second.status_code == 400


@pytest.mark.asyncio
async def test_sent_connection_requests_and_cancel_contract(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Frontend sent-requests view and cancel action require backend support."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

    create_resp = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={"target_id": "test-user-id", "method": "inAppSearch"},
    )
    request_id = create_resp.json()["id"]

    sent = await client.get("/api/v1/invites/connection-requests/sent", headers=student_auth_headers)
    assert sent.status_code == 200
    assert sent.json()["total"] == 1
    assert sent.json()["items"][0]["id"] == request_id

    cancel = await client.patch(
        f"/api/v1/invites/connection-requests/{request_id}/cancel",
        headers=student_auth_headers,
    )
    assert cancel.status_code == 200
    assert cancel.json()["status"] == "cancelled"

    pending = await client.get("/api/v1/invites/connection-requests/pending", headers=auth_headers)
    assert pending.json()["total"] == 0


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


@pytest.mark.asyncio
async def test_inactive_connections_can_be_listed_and_reactivated(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """My connections screen has inactive and reconnect flows."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="Student",
    )

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
    await client.delete(f"/api/v1/invites/connections/{conn_id}", headers=auth_headers)

    inactive = await client.get(
        "/api/v1/invites/connections",
        headers=auth_headers,
        params={"include_inactive": True},
    )
    assert inactive.status_code == 200
    assert inactive.json()["total"] == 1
    assert inactive.json()["items"][0]["is_active"] is False

    reactivated = await client.patch(
        f"/api/v1/invites/connections/{conn_id}/reactivate",
        headers=auth_headers,
    )
    assert reactivated.status_code == 200
    assert reactivated.json()["is_active"] is True

    active = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert active.json()["total"] == 1
