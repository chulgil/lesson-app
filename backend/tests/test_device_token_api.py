"""Device token registration endpoint + service coverage (#475 FCM unblock).

The device-token infra (model/migration/endpoint/service) shipped in
migration 20260506 but had only a migration-contract test. These tests cover
the register upsert + anti-hijack + owner-scoped delete behaviors that the FCM
push path (NotificationService.create_and_send → DeviceTokenService
.get_tokens_for_user) depends on. No Firebase config required.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.schemas.device_token import DeviceTokenCreate
from app.services.device_token_service import DeviceTokenService


def _headers(user_id: str, role: str = "student") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_register_device_token_returns_201_and_redacts_token(client: AsyncClient, create_test_user):
    await create_test_user(user_id="dt-user", role="student", email="dt@test.com")

    response = await client.post(
        "/api/v1/device-tokens",
        headers=_headers("dt-user"),
        json={"token": "fcm-token-abc", "platform": "ios"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["platform"] == "ios"
    assert "id" in body
    # raw token must never come back (secret/PII).
    assert "token" not in body or body.get("token") != "fcm-token-abc"


@pytest.mark.asyncio
async def test_unregister_device_token(client: AsyncClient, create_test_user, db_session: AsyncSession):
    await create_test_user(user_id="dt-user", role="student", email="dt@test.com")
    await client.post(
        "/api/v1/device-tokens",
        headers=_headers("dt-user"),
        json={"token": "fcm-token-del", "platform": "android"},
    )

    response = await client.delete(
        "/api/v1/device-tokens/fcm-token-del",
        headers=_headers("dt-user"),
    )
    assert response.status_code == 200

    remaining = await DeviceTokenService(db_session).get_tokens_for_user("dt-user")
    assert "fcm-token-del" not in remaining


@pytest.mark.asyncio
async def test_unregister_requires_authentication(client: AsyncClient):
    response = await client.delete("/api/v1/device-tokens/any-token")
    assert response.status_code in (401, 403)


# ---------------------------------------------------------------------------
# Service — upsert / anti-hijack / ownership
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_register_same_user_upserts_platform(create_test_user, db_session: AsyncSession):
    await create_test_user(user_id="dt-user", role="student", email="dt@test.com")
    service = DeviceTokenService(db_session)

    first = await service.register("dt-user", DeviceTokenCreate(token="tok-1", platform="ios"))
    second = await service.register("dt-user", DeviceTokenCreate(token="tok-1", platform="android"))

    # Same row updated, not duplicated.
    assert first.id == second.id
    assert second.platform == "android"
    assert await service.get_tokens_for_user("dt-user") == ["tok-1"]


@pytest.mark.asyncio
async def test_register_hijack_moves_token_to_new_owner_only(create_test_user, db_session: AsyncSession):
    """A token re-registered by a different user transfers exclusively — the
    old owner must no longer receive pushes on that device (anti-spoofing)."""
    await create_test_user(user_id="victim", role="student", email="v@test.com")
    await create_test_user(user_id="attacker", role="student", email="a@test.com")
    service = DeviceTokenService(db_session)

    await service.register("victim", DeviceTokenCreate(token="shared-tok", platform="ios"))
    await service.register("attacker", DeviceTokenCreate(token="shared-tok", platform="ios"))

    assert await service.get_tokens_for_user("victim") == []
    assert await service.get_tokens_for_user("attacker") == ["shared-tok"]


@pytest.mark.asyncio
async def test_unregister_only_removes_own_token(create_test_user, db_session: AsyncSession):
    """Knowing a token string must not let another user disable it."""
    await create_test_user(user_id="owner", role="student", email="o@test.com")
    await create_test_user(user_id="other", role="student", email="ot@test.com")
    service = DeviceTokenService(db_session)

    await service.register("owner", DeviceTokenCreate(token="owned-tok", platform="ios"))

    # Another user's unregister of the same token string is a no-op.
    await service.unregister("owned-tok", "other")
    assert await service.get_tokens_for_user("owner") == ["owned-tok"]

    await service.unregister("owned-tok", "owner")
    assert await service.get_tokens_for_user("owner") == []


@pytest.mark.asyncio
async def test_get_tokens_for_user_multi_device(create_test_user, db_session: AsyncSession):
    await create_test_user(user_id="multi", role="student", email="m@test.com")
    service = DeviceTokenService(db_session)

    await service.register("multi", DeviceTokenCreate(token="phone", platform="ios"))
    await service.register("multi", DeviceTokenCreate(token="tablet", platform="android"))

    tokens = await service.get_tokens_for_user("multi")
    assert set(tokens) == {"phone", "tablet"}
