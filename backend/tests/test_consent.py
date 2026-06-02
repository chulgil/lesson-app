"""#430 G1 B2 — 약관 동의 영속 저장 테스트.

POST /auth/consent:
  * 호출 자체가 필수 묶음(서비스 이용약관 + 개인정보 처리방침) 동의를 의미
  * marketing_consent=true 면 별도 시각으로 marketing_consent_at 기록
  * marketing_consent=false 면 marketing_consent_at = NULL
  * 재호출 시 terms_accepted_at 은 최초 시각 유지 (감사 추적성)
  * marketing_consent 는 재호출마다 갱신 가능 (구독 → 해지 시나리오)
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_consent_records_required_terms_only(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    await create_test_user()

    response = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": False},
    )

    assert response.status_code == 200, response.text
    data = response.json()
    assert data["terms_accepted_at"] is not None
    assert data["marketing_consent_at"] is None


@pytest.mark.asyncio
async def test_consent_records_marketing_consent(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    await create_test_user()

    response = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": True},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["terms_accepted_at"] is not None
    assert data["marketing_consent_at"] is not None


@pytest.mark.asyncio
async def test_consent_marketing_default_false_when_omitted(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    await create_test_user()

    response = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["terms_accepted_at"] is not None
    assert data["marketing_consent_at"] is None


@pytest.mark.asyncio
async def test_consent_resend_preserves_initial_terms_timestamp(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """재호출 시 terms_accepted_at 은 최초 시각 유지 (감사 추적성)."""
    await create_test_user()

    first = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": False},
    )
    assert first.status_code == 200
    first_terms_at = first.json()["terms_accepted_at"]

    second = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": True},
    )
    assert second.status_code == 200
    second_terms_at = second.json()["terms_accepted_at"]

    assert second_terms_at == first_terms_at
    assert second.json()["marketing_consent_at"] is not None


@pytest.mark.asyncio
async def test_consent_marketing_can_be_withdrawn(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """마케팅 동의 해지 시 marketing_consent_at = NULL 로 reset."""
    await create_test_user()

    optin = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": True},
    )
    assert optin.status_code == 200
    assert optin.json()["marketing_consent_at"] is not None

    optout = await client.post(
        "/api/v1/auth/consent",
        headers=auth_headers,
        json={"marketing_consent": False},
    )
    assert optout.status_code == 200
    assert optout.json()["marketing_consent_at"] is None
    # terms_accepted_at 은 그대로 유지
    assert optout.json()["terms_accepted_at"] == optin.json()["terms_accepted_at"]


@pytest.mark.asyncio
async def test_consent_requires_auth(client: AsyncClient):
    """인증 없으면 401."""
    response = await client.post(
        "/api/v1/auth/consent",
        json={"marketing_consent": False},
    )

    assert response.status_code in (401, 403)
