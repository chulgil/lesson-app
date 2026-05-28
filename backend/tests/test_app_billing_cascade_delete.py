"""Cascade-delete regression for app_billing tables (codex audit follow-up).

Migration f2e8c3d9b1a2 declares ON DELETE CASCADE on user_id FKs for
app_billing_plans and iap_receipts. If the cascade is silently dropped
(e.g., schema drift, missing pragma on SQLite), deleting a user would
leave orphan billing rows — a privacy regression on account deletion.

This pins the cascade contract at the DB level.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.app_billing import (
    AppBillingPlan,
    BillingPlanStatus,
    BillingTier,
    IapPlatform,
    IapReceipt,
    IapReceiptStatus,
)
from app.models.user import User


@pytest.mark.sqlite_fk_on
@pytest.mark.asyncio
async def test_user_delete_cascades_to_app_billing_plan(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="cascade-plan-user", role="teacher")

    plan_id = str(uuid.uuid4())
    db_session.add(
        AppBillingPlan(
            id=plan_id,
            user_id=user.id,
            tier=BillingTier.pro,
            status=BillingPlanStatus.active,
        )
    )
    await db_session.commit()

    db_user = await db_session.get(User, user.id)
    assert db_user is not None
    await db_session.delete(db_user)
    await db_session.commit()

    result = await db_session.execute(select(AppBillingPlan).where(AppBillingPlan.id == plan_id))
    assert result.scalar_one_or_none() is None, "AppBillingPlan must be cascade-deleted when its owner User is deleted"


@pytest.mark.sqlite_fk_on
@pytest.mark.asyncio
async def test_user_delete_cascades_to_iap_receipts(
    db_session: AsyncSession,
    create_test_user,
) -> None:
    user = await create_test_user(user_id="cascade-receipt-user", role="teacher")

    receipt_ids = [str(uuid.uuid4()) for _ in range(2)]
    db_session.add_all(
        [
            IapReceipt(
                id=receipt_ids[0],
                user_id=user.id,
                platform=IapPlatform.apple,
                raw_receipt="r1",
                transaction_id="tx-cascade-1",
                product_id="pro_yearly",
                status=IapReceiptStatus.verified,
            ),
            IapReceipt(
                id=receipt_ids[1],
                user_id=user.id,
                platform=IapPlatform.google,
                raw_receipt="r2",
                transaction_id="tx-cascade-2",
                product_id="pro_yearly",
                status=IapReceiptStatus.pending_verification,
            ),
        ]
    )
    await db_session.commit()

    db_user = await db_session.get(User, user.id)
    assert db_user is not None
    await db_session.delete(db_user)
    await db_session.commit()

    result = await db_session.execute(select(IapReceipt).where(IapReceipt.id.in_(receipt_ids)))
    assert result.scalars().all() == [], "IapReceipt rows must be cascade-deleted with their owner User"
