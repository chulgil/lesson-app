"""Rate limit guards on sensitive auth endpoints (refresh / dev-login / oauth)."""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.fixture
def _enable_rate_limit(monkeypatch):
    """Disable the TESTING short-circuit so rate_limit actually enforces."""
    from app.core import config as core_config

    monkeypatch.setattr(core_config.settings, "TESTING", False)

    # in-memory bucket 도 격리 — 다른 테스트의 카운트가 합산되지 않게 클리어.
    from app.core import rate_limit as rl

    rl._buckets.clear()
    yield
    rl._buckets.clear()


@pytest.mark.asyncio
async def test_refresh_token_rate_limit_kicks_in_after_window(client: AsyncClient, _enable_rate_limit):
    """20번째 호출까지 200/401 (어떤 에러든 OK) 그 이후 21번째는 429."""
    # 21회 연속 호출. 실제 token validity 와 무관하게 rate limiter 가 먼저 통과 여부 결정.
    last_status = None
    for i in range(21):
        response = await client.post(
            "/api/v1/auth/token/refresh",
            json={"refresh_token": f"invalid-{i}"},
        )
        last_status = response.status_code
        if last_status == 429:
            break

    assert last_status == 429, f"expected 429 after 20 requests, got {last_status}"


@pytest.mark.asyncio
async def test_dev_login_rate_limit_kicks_in_after_window(client: AsyncClient, _enable_rate_limit):
    """10번째 호출까지 4xx 다양 (인증 실패) 그 이후 11번째는 429."""
    last_status = None
    for i in range(11):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": f"victim-{i}@test.com", "user_id": f"u-{i}"},
        )
        last_status = response.status_code
        if last_status == 429:
            break

    assert last_status == 429, f"expected 429 after 10 requests, got {last_status}"


@pytest.mark.asyncio
async def test_rate_limit_uses_xff_when_trusted_proxy(client: AsyncClient, _enable_rate_limit, monkeypatch):
    """RATE_LIMIT_TRUST_PROXY=1 이면 XFF 로 클라이언트별 카운트 분리 — proxy 환경 검증."""
    from app.core import config as core_config

    monkeypatch.setattr(core_config.settings, "RATE_LIMIT_TRUST_PROXY", True)
    headers_a = {"X-Forwarded-For": "10.0.0.1"}
    headers_b = {"X-Forwarded-For": "10.0.0.2"}

    # IP A 에서 20번 — 모두 통과 (인증 실패해도 429 는 아님).
    for i in range(20):
        response = await client.post(
            "/api/v1/auth/token/refresh",
            json={"refresh_token": f"a-{i}"},
            headers=headers_a,
        )
        assert response.status_code != 429

    # IP A 의 21번째 → 429.
    response_a_capped = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": "a-21"},
        headers=headers_a,
    )
    assert response_a_capped.status_code == 429

    # IP B 는 별개 카운트 → 첫 요청 통과.
    response_b_fresh = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": "b-1"},
        headers=headers_b,
    )
    assert response_b_fresh.status_code != 429


@pytest.mark.asyncio
async def test_rate_limit_ignores_spoofed_xff_by_default(client: AsyncClient, _enable_rate_limit):
    """기본(비신뢰) 모드에서는 XFF 위장으로 버킷을 갈아탈 수 없다 — 우회 회귀 방지.

    RATE_LIMIT_TRUST_PROXY 기본값(False)에서는 요청마다 다른 XFF 를 보내도
    소켓 주소 기준 단일 버킷으로 합산되어 한도 초과 시 429 가 나와야 한다.
    """
    last_status = None
    for i in range(21):
        response = await client.post(
            "/api/v1/auth/token/refresh",
            json={"refresh_token": f"spoof-{i}"},
            headers={"X-Forwarded-For": f"10.9.{i}.{i}"},
        )
        last_status = response.status_code
        if last_status == 429:
            break

    assert last_status == 429, f"spoofed XFF must not reset the bucket, got {last_status}"


@pytest.mark.asyncio
async def test_rate_limit_disabled_under_testing_flag(client: AsyncClient):
    """기본 conftest 는 TESTING=1 → rate limit 노옵 (기존 테스트가 깨지지 않게 함)."""
    # 30번 연속 호출 — 모두 429 가 아니어야 한다 (TESTING 노옵).
    for i in range(30):
        response = await client.post(
            "/api/v1/auth/token/refresh",
            json={"refresh_token": f"loop-{i}"},
        )
        assert response.status_code != 429
