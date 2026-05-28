"""DB-level constraint tests for app_billing tables (#406).

Pins the schema contract so application-level dedup cannot be the only
line of defense against replay attacks and orphaned billing rows.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_billing import (
    AppBillingPlan,
    BillingPlanStatus,
    BillingTier,
    IapPlatform,
    IapReceipt,
    IapReceiptStatus,
)


@pytest.mark.asyncio
async def test_app_billing_plans_unique_per_user(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="plan-unique-user", role="teacher")

    db_session.add(
        AppBillingPlan(
            id=str(uuid.uuid4()),
            user_id=user.id,
            tier=BillingTier.free,
            status=BillingPlanStatus.active,
        )
    )
    await db_session.commit()

    db_session.add(
        AppBillingPlan(
            id=str(uuid.uuid4()),
            user_id=user.id,
            tier=BillingTier.pro,
            status=BillingPlanStatus.active,
        )
    )
    with pytest.raises(IntegrityError):
        await db_session.commit()
    await db_session.rollback()


@pytest.mark.asyncio
async def test_iap_receipt_replay_blocked(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="iap-replay-user", role="teacher")

    db_session.add(
        IapReceipt(
            id=str(uuid.uuid4()),
            user_id=user.id,
            platform=IapPlatform.apple,
            raw_receipt="receipt-1",
            transaction_id="tx-replay-1",
            product_id="pro_yearly",
            status=IapReceiptStatus.pending_verification,
        )
    )
    await db_session.commit()

    db_session.add(
        IapReceipt(
            id=str(uuid.uuid4()),
            user_id=user.id,
            platform=IapPlatform.apple,
            raw_receipt="receipt-1-replay",
            transaction_id="tx-replay-1",
            product_id="pro_yearly",
            status=IapReceiptStatus.pending_verification,
        )
    )
    with pytest.raises(IntegrityError):
        await db_session.commit()
    await db_session.rollback()


@pytest.mark.asyncio
async def test_iap_receipt_same_transaction_id_different_platform_ok(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """(platform, transaction_id) is the uniqueness key — same tx id across
    Apple and Google is legitimate (the platforms issue ids independently)."""
    user = await create_test_user(user_id="iap-cross-platform-user", role="teacher")

    db_session.add(
        IapReceipt(
            id=str(uuid.uuid4()),
            user_id=user.id,
            platform=IapPlatform.apple,
            raw_receipt="apple-receipt",
            transaction_id="tx-shared-id",
            product_id="pro_yearly",
            status=IapReceiptStatus.pending_verification,
        )
    )
    db_session.add(
        IapReceipt(
            id=str(uuid.uuid4()),
            user_id=user.id,
            platform=IapPlatform.google,
            raw_receipt="google-receipt",
            transaction_id="tx-shared-id",
            product_id="pro_yearly",
            status=IapReceiptStatus.pending_verification,
        )
    )
    await db_session.commit()
