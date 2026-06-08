"""IAP placeholder transaction_id 충돌 회귀 — 두 사용자가 같은 SKU 영수증을 제출해도 정상 처리.

Phase 13 — router 가 ``transaction_id=product_id`` 로 placeholder 를 넘기던 P0 차단.
이전 동작은 ``(platform, transaction_id)`` UNIQUE 제약으로 두 번째 사용자부터 InsertError →
broad except → 500 (응답에는 detail 노출). 본 PR 의 합성 transaction_id 가 user 별로 분리되어
충돌 없음.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.app_billing import IapReceipt


def _headers_for(user_id: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_two_users_can_submit_same_sku_without_unique_conflict(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """두 사용자가 같은 ``product_id`` 로 IAP 영수증을 제출해도 모두 audit 행 생성 + 200."""
    await create_test_user(user_id="iap-user-a", role="teacher", email="iap-a@test.com")
    await create_test_user(user_id="iap-user-b", role="teacher", email="iap-b@test.com")

    payload = {
        "platform": "apple",
        "receipt": "receipt-bytes-for-pro-yearly-sku",
        "product_id": "pro_yearly",
    }

    response_a = await client.post("/api/v1/me/billing/iap/validate", headers=_headers_for("iap-user-a"), json=payload)
    assert response_a.status_code == 200

    # 다른 user 가 같은 SKU 의 영수증을 제출 — UNIQUE 위반 없이 성공해야 한다.
    response_b = await client.post(
        "/api/v1/me/billing/iap/validate",
        headers=_headers_for("iap-user-b"),
        json={**payload, "receipt": "receipt-bytes-for-different-purchase"},
    )
    assert response_b.status_code == 200

    # 두 user 의 audit receipt 행이 모두 생성됨.
    rows = list(
        (await db_session.scalars(select(IapReceipt).where(IapReceipt.user_id.in_(["iap-user-a", "iap-user-b"])))).all()
    )
    user_ids = sorted({r.user_id for r in rows})
    assert user_ids == ["iap-user-a", "iap-user-b"]


@pytest.mark.asyncio
async def test_same_user_resubmitting_same_receipt_is_idempotent(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """같은 user 가 같은 raw_receipt 를 두 번 제출해도 audit 행은 1건만 (idempotent)."""
    await create_test_user(user_id="iap-idem-user", role="teacher")

    payload = {
        "platform": "apple",
        "receipt": "identical-receipt-bytes",
        "product_id": "pro_monthly",
    }

    # 1차 제출 — 200, receipt audit 생성.
    response1 = await client.post(
        "/api/v1/me/billing/iap/validate", headers=_headers_for("iap-idem-user"), json=payload
    )
    assert response1.status_code == 200

    # 2차 제출 — broad except 가 잡아 200 success=False 로 응답하지만 audit 중복은 없어야 한다.
    response2 = await client.post(
        "/api/v1/me/billing/iap/validate", headers=_headers_for("iap-idem-user"), json=payload
    )
    assert response2.status_code == 200

    rows = list((await db_session.scalars(select(IapReceipt).where(IapReceipt.user_id == "iap-idem-user"))).all())
    # 동일 (user, raw_receipt) → 동일 transaction_id 합성 → UNIQUE 로 중복 거부.
    assert len(rows) == 1
