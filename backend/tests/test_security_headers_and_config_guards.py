"""SecurityHeadersMiddleware + production runtime config guard 회귀 테스트.

Phase 15:
- 응답에 X-Content-Type-Options / X-Frame-Options / Referrer-Policy / Permissions-Policy 부착
- HSTS 는 production_like 에서만 부착 (localhost 디버그 방해 차단)
- validate_runtime_configuration 가 production_like 에서 DEBUG / CORS_ORIGINS 검증 추가
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.core.config import settings, validate_runtime_configuration


@pytest.mark.asyncio
async def test_default_security_headers_applied(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200

    assert response.headers.get("x-content-type-options") == "nosniff"
    assert response.headers.get("x-frame-options") == "DENY"
    assert response.headers.get("referrer-policy") == "strict-origin-when-cross-origin"
    assert "geolocation" in response.headers.get("permissions-policy", "")


@pytest.mark.asyncio
async def test_hsts_not_applied_in_non_production(client: AsyncClient) -> None:
    """test 환경에서는 HSTS 가 부착되면 안 됨 (자체 서명 인증서 디버그 방해)."""
    response = await client.get("/health")
    assert response.status_code == 200
    assert "strict-transport-security" not in response.headers


@pytest.mark.asyncio
async def test_hsts_applied_in_production_like(client: AsyncClient, monkeypatch) -> None:
    """production 환경에서는 HSTS 헤더가 부착돼야 한다."""
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    response = await client.get("/health")
    assert response.status_code == 200
    hsts = response.headers.get("strict-transport-security", "")
    assert "max-age=" in hsts
    assert "includeSubDomains" in hsts


def test_runtime_config_rejects_debug_in_production(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "DEBUG", True)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["https://lessonaza.app"])

    with pytest.raises(RuntimeError, match="DEBUG must be False"):
        validate_runtime_configuration()


def test_runtime_config_rejects_wildcard_cors_in_production(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "DEBUG", False)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["*"])

    with pytest.raises(RuntimeError, match="must not contain '\\*' wildcard"):
        validate_runtime_configuration()


def test_runtime_config_rejects_localhost_cors_in_production(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "DEBUG", False)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["http://localhost:3000"])

    with pytest.raises(RuntimeError, match="local origin"):
        validate_runtime_configuration()


def test_runtime_config_rejects_http_origin_in_production(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "DEBUG", False)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["http://api.example.com"])

    with pytest.raises(RuntimeError, match="https://"):
        validate_runtime_configuration()


def test_runtime_config_passes_with_proper_production_setup(monkeypatch) -> None:
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "DEBUG", False)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "x" * 32)
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "x" * 32)
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["https://lessonaza.app"])

    validate_runtime_configuration()  # 예외 없이 통과해야 한다.


def test_runtime_config_skips_in_development(monkeypatch) -> None:
    """development 환경에서는 CORS / DEBUG 검증이 적용되지 않는다 (DX 보장)."""
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(settings, "DEBUG", True)
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "")
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "dev-only-insecure-jwt-secret-change-before-production")
    monkeypatch.setattr(settings, "CORS_ORIGINS", ["*"])

    validate_runtime_configuration()  # 예외 없이 통과 (development 게이트).


# ---------------------------------------------------------------------------
# Phase 17 — CSP report-only mode
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_csp_report_only_not_applied_in_testing(client: AsyncClient) -> None:
    """TESTING=1 환경에서는 CSP 헤더가 부착되지 않는다 (pytest 단순화)."""
    response = await client.get("/health")
    assert response.status_code == 200
    assert "content-security-policy-report-only" not in response.headers


@pytest.mark.asyncio
async def test_csp_report_only_applied_in_production_like(client: AsyncClient, monkeypatch) -> None:
    """production_like 환경 + TESTING=False 면 CSP report-only 헤더가 부착된다."""
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "TESTING", False)
    response = await client.get("/health")
    assert response.status_code == 200
    policy = response.headers.get("content-security-policy-report-only", "")
    # 핵심 directive 들이 존재해야 한다.
    assert "default-src 'self'" in policy
    assert "frame-ancestors 'none'" in policy
    assert "base-uri 'self'" in policy
    assert "form-action 'self'" in policy
    # report-uri 미설정 시 report-uri directive 미존재.
    assert "report-uri" not in policy


@pytest.mark.asyncio
async def test_csp_report_only_includes_report_uri_when_set(client: AsyncClient, monkeypatch) -> None:
    """CSP_REPORT_URI 가 설정되면 정책에 report-uri directive 가 포함된다."""
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "TESTING", False)
    monkeypatch.setattr(settings, "CSP_REPORT_URI", "https://csp-reports.lessonaza.app/report")

    response = await client.get("/health")
    assert response.status_code == 200
    policy = response.headers.get("content-security-policy-report-only", "")
    assert "report-uri https://csp-reports.lessonaza.app/report" in policy


@pytest.mark.asyncio
async def test_csp_enforce_header_never_emitted(client: AsyncClient, monkeypatch) -> None:
    """본 PR 은 report-only 만 부착 — 강제 모드 (Content-Security-Policy) 는 emit 하지 않는다.

    frontend 호환성 데이터 수집 전 강제로 전환되면 inline script 등이 차단되어 사이트가 깨질 위험.
    """
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "TESTING", False)
    response = await client.get("/health")
    assert response.status_code == 200
    assert "content-security-policy" not in (k.lower() for k in response.headers)
