"""IAP receipt default-deny guard tests (#405).

Before this guard, any POST to /me/billing/iap/validate with arbitrary base64
data would upgrade the caller's plan to Pro for 365 days. These tests pin the
new default-deny contract so the bug cannot regress.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.app_billing import (
    AppBillingPlan,
    BillingTier,
    IapReceipt,
    IapReceiptStatus,
)
from app.services.app_billing_service import AppBillingService

# ---------------------------------------------------------------------------
# Service-level: apply_iap_receipt default-deny
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_apply_iap_receipt_default_denies_upgrade(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="iap-default-user", role="teacher")
    service = AppBillingService(db_session)

    granted, plan = await service.apply_iap_receipt(
        user_id=user.id,
        platform="apple",
        raw_receipt="forged-receipt-bytes",
        transaction_id="tx-1",
        product_id="pro_monthly",
    )

    assert granted is False
    assert plan.tier == BillingTier.free
    assert plan.expires_at is None


@pytest.mark.asyncio
async def test_apply_iap_receipt_persists_audit_row_even_when_denied(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="iap-audit-user", role="teacher")
    service = AppBillingService(db_session)

    await service.apply_iap_receipt(
        user_id=user.id,
        platform="google",
        raw_receipt="some-receipt",
        transaction_id="tx-audit-1",
        product_id="pro_yearly",
    )

    receipts = (await db_session.execute(select(IapReceipt).where(IapReceipt.user_id == user.id))).scalars().all()
    assert len(receipts) == 1
    assert receipts[0].status == IapReceiptStatus.pending_verification
    assert receipts[0].validated_at is None


@pytest.mark.asyncio
async def test_apply_iap_receipt_dev_flag_grants_in_non_production(
    db_session: AsyncSession,
    create_test_user,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(settings, "IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY", True)

    user = await create_test_user(user_id="iap-dev-user", role="teacher")
    service = AppBillingService(db_session)

    granted, plan = await service.apply_iap_receipt(
        user_id=user.id,
        platform="apple",
        raw_receipt="dev-mock-receipt",
        transaction_id="tx-dev-1",
        product_id="pro_yearly",
    )

    assert granted is True
    assert plan.tier == BillingTier.pro
    assert plan.expires_at is not None


@pytest.mark.asyncio
async def test_apply_iap_receipt_dev_flag_is_ignored_in_production(
    db_session: AsyncSession,
    create_test_user,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY", True)

    user = await create_test_user(user_id="iap-prod-user", role="teacher")
    service = AppBillingService(db_session)

    granted, plan = await service.apply_iap_receipt(
        user_id=user.id,
        platform="apple",
        raw_receipt="prod-attempt-receipt",
        transaction_id="tx-prod-1",
        product_id="pro_yearly",
    )

    assert granted is False
    assert plan.tier == BillingTier.free


@pytest.mark.asyncio
async def test_apply_iap_receipt_dev_flag_is_ignored_in_beta(
    db_session: AsyncSession,
    create_test_user,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "beta")
    monkeypatch.setattr(settings, "IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY", True)

    user = await create_test_user(user_id="iap-beta-user", role="teacher")
    service = AppBillingService(db_session)

    granted, plan = await service.apply_iap_receipt(
        user_id=user.id,
        platform="google",
        raw_receipt="beta-attempt-receipt",
        transaction_id="tx-beta-1",
        product_id="pro_yearly",
    )

    assert granted is False
    assert plan.tier == BillingTier.free


# ---------------------------------------------------------------------------
# HTTP-level: /me/billing/iap/validate default-deny
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_iap_validate_endpoint_defaults_to_failure(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_test_user,
    db_session: AsyncSession,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/me/billing/iap/validate",
        json={
            "platform": "apple",
            "receipt": "AAAA-forged-bytes",
            "product_id": "pro_monthly",
        },
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["success"] is False
    assert body["plan_id"] is None
    assert body["tier"] is None
    assert body["expires_at"] is None

    plan = await db_session.scalar(
        select(AppBillingPlan).where(AppBillingPlan.user_id == "test-user-id"),
    )
    assert plan is not None
    assert plan.tier == BillingTier.free
