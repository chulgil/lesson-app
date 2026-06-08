"""HTTP 응답에 기본 보안 헤더를 부착하는 ASGI 미들웨어.

reverse proxy (nginx) 가 이미 적용한다면 중복이지만, layer-in-depth 보안을 위해 백엔드 응답
자체에도 헤더를 명시한다. 누락 시 OWASP top10 의 일부 (clickjacking, MIME sniffing, mixed content) 노출.

production_like 환경에서만 적용 — 로컬 개발 (`http://localhost`) 에서 HSTS 가 걸리면 자체 서명
인증서 / http 디버그가 어려워지기 때문.

CSP (Content-Security-Policy) 는 *report-only* 모드로 적용 — 위반을 모니터링만 하고 강제하지
않아 frontend 가 inline script / style / eval 사용해도 그대로 동작한다. `CSP_REPORT_URI` 가
설정되면 위반 신고가 그 URL 로 POST 되므로 운영자가 적응 기간 데이터를 수집할 수 있고, 충분히
검토 후 별도 PR 에서 `Content-Security-Policy` 헤더 (강제 모드) 로 전환한다.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Any


def _is_production_like() -> bool:
    from app.core.config import PRODUCTION_LIKE_ENVIRONMENTS, settings

    return settings.ENVIRONMENT in PRODUCTION_LIKE_ENVIRONMENTS


def _csp_report_only_enabled() -> bool:
    """CSP report-only 헤더를 부착할지 결정.

    기본 True (production_like) — frontend 호환성 데이터 수집. TESTING 환경은 노옵 — pytest
    응답 헤더 검증을 단순하게 유지.
    """
    from app.core.config import settings

    if getattr(settings, "TESTING", False):
        return False
    return _is_production_like()


def _build_csp_report_only_policy() -> str:
    """기본 CSP report-only 정책 문자열을 빌드.

    설계:
    - `default-src 'self'` — 모든 fetch 출처를 동일 출처로 제한.
    - `img-src 'self' data: https:` — favicon · data URI 인라인 / CDN 허용.
    - `style-src 'self' 'unsafe-inline'` — CSS-in-JS / inline style 호환 (점진 도입).
    - `script-src 'self'` — inline script 차단 (frontend 가 위반 시 위반 리포트 발생).
    - `connect-src 'self'` — API 응답 fetch 만 허용.
    - `font-src 'self' data:` — 인라인 font · 동일 출처 허용.
    - `frame-ancestors 'none'` — clickjacking 방어 (X-Frame-Options 백업).
    - `base-uri 'self'`, `form-action 'self'` — base/form hijack 방어.
    - `report-uri` 가 설정되어 있으면 위반 신고 endpoint 명시.
    """
    from app.core.config import settings

    parts = [
        "default-src 'self'",
        "img-src 'self' data: https:",
        "style-src 'self' 'unsafe-inline'",
        "script-src 'self'",
        "connect-src 'self'",
        "font-src 'self' data:",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'",
    ]
    report_uri = getattr(settings, "CSP_REPORT_URI", "")
    if report_uri:
        parts.append(f"report-uri {report_uri}")
    return "; ".join(parts)


class SecurityHeadersMiddleware:
    """Add HSTS / nosniff / frame-options / referrer-policy / permissions-policy.

    응답 헤더는 항상 추가 (production_like 가 아닐 때도 안전), 단 HSTS 만 production_like 한정.
    """

    def __init__(self, app: Callable[..., Awaitable[None]]) -> None:
        self.app = app

    async def __call__(self, scope: dict[str, Any], receive: Callable, send: Callable) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_headers(message: dict[str, Any]) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                existing = {key.lower() for key, _ in headers}

                # MIME sniffing 차단 — text/html 같은 sniff 으로 XSS 우회 방지.
                if b"x-content-type-options" not in existing:
                    headers.append((b"x-content-type-options", b"nosniff"))

                # Clickjacking 차단 — 어떤 origin 도 iframe 으로 임베드 금지.
                if b"x-frame-options" not in existing:
                    headers.append((b"x-frame-options", b"DENY"))

                # Referrer 누설 차단 — cross-origin 시 origin 만 보냄.
                if b"referrer-policy" not in existing:
                    headers.append((b"referrer-policy", b"strict-origin-when-cross-origin"))

                # 권한 일괄 차단 — geolocation / camera / microphone 등 의도하지 않은 API 호출 차단.
                if b"permissions-policy" not in existing:
                    headers.append(
                        (
                            b"permissions-policy",
                            b"accelerometer=(), camera=(), geolocation=(), gyroscope=(), microphone=(), payment=()",
                        )
                    )

                # HSTS — production_like 만. localhost 에 걸면 자체 서명 인증서 디버그가 어려워진다.
                if _is_production_like() and b"strict-transport-security" not in existing:
                    headers.append(
                        (b"strict-transport-security", b"max-age=31536000; includeSubDomains"),
                    )

                # CSP report-only — 강제 모드 전환 전 frontend 호환성 데이터 수집.
                # 기본 정책: 자기 출처만 허용 + img/font/style 'unsafe-inline' (CSS-in-JS 등).
                # 위반 발생 시 (있다면) report-uri 로 POST. 운영자가 충분히 분석한 후 별도 PR 에서
                # `Content-Security-Policy` 헤더 (enforce) 로 전환.
                if _csp_report_only_enabled() and b"content-security-policy-report-only" not in existing:
                    policy = _build_csp_report_only_policy()
                    headers.append((b"content-security-policy-report-only", policy.encode("ascii")))

                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_with_headers)
