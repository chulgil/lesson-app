"""Tests for app billing API endpoints (R4 IAP monetization)."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_billing_status_returns_free_by_default(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """New teacher gets a free plan by default."""
    await create_test_user()

    response = await client.get(
        "/api/v1/app/billing/status",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["plan"] == "free"
    assert data["is_active"] is True
    assert data["student_limit"] == 5
    assert data["features"]["ai_notes"] is False
    assert data["features"]["recording"] is False


@pytest.mark.asyncio
async def test_trial_start_creates_14_day_trial(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """Starting trial changes plan to trial_pro with 14-day expiry."""
    await create_test_user()

    response = await client.post(
        "/api/v1/app/billing/trial/start",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["plan"] == "trial_pro"
    assert data["trial_ends_at"] is not None


@pytest.mark.asyncio
async def test_trial_cannot_start_twice(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """Second trial attempt should fail."""
    await create_test_user()

    resp1 = await client.post(
        "/api/v1/app/billing/trial/start",
        headers=auth_headers,
    )
    assert resp1.status_code == 200

    resp2 = await client.post(
        "/api/v1/app/billing/trial/start",
        headers=auth_headers,
    )
    assert resp2.status_code == 400


@pytest.mark.asyncio
async def test_verify_purchase_activates_pro(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """Verifying a purchase receipt activates the Pro plan."""
    await create_test_user()

    response = await client.post(
        "/api/v1/app/billing/verify-purchase",
        headers=auth_headers,
        json={
            "store_platform": "ios",
            "product_id": "pro_monthly",
            "transaction_id": "test-txn-001",
            "receipt_data": "fake-receipt-data",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["plan"] == "pro"
    assert data["is_active"] is True
    assert data["expires_at"] is not None


@pytest.mark.asyncio
async def test_verify_purchase_unknown_product(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """Unknown product ID should return 400."""
    await create_test_user()

    response = await client.post(
        "/api/v1/app/billing/verify-purchase",
        headers=auth_headers,
        json={
            "store_platform": "ios",
            "product_id": "unknown_product",
            "transaction_id": "test-txn-002",
            "receipt_data": "fake-receipt-data",
        },
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_products_list_returns_all_products(
    client: AsyncClient,
) -> None:
    """Products endpoint returns the full product catalog."""
    response = await client.get("/api/v1/app/billing/products")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 4
    product_ids = {p["product_id"] for p in data}
    assert product_ids == {"pro_monthly", "pro_yearly", "studio_monthly", "lifetime"}


@pytest.mark.asyncio
async def test_billing_status_after_purchase_shows_pro_features(
    client: AsyncClient, create_test_user, auth_headers: dict[str, str]
) -> None:
    """After purchase, status should reflect Pro features."""
    await create_test_user()

    await client.post(
        "/api/v1/app/billing/verify-purchase",
        headers=auth_headers,
        json={
            "store_platform": "ios",
            "product_id": "pro_monthly",
            "transaction_id": "test-txn-003",
            "receipt_data": "fake-receipt",
        },
    )

    response = await client.get(
        "/api/v1/app/billing/status",
        headers=auth_headers,
    )
    data = response.json()
    assert data["plan"] == "pro"
    assert data["student_limit"] is None
    assert data["features"]["ai_notes"] is True
    assert data["features"]["recording"] is True
    assert data["features"]["parent_portal"] is True
    assert data["features"]["multi_teacher"] is False
