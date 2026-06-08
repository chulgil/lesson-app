"""HTTP 응답에 기본 보안 헤더를 부착하는 ASGI 미들웨어.

reverse proxy (nginx) 가 이미 적용한다면 중복이지만, layer-in-depth 보안을 위해 백엔드 응답
자체에도 헤더를 명시한다. 누락 시 OWASP top10 의 일부 (clickjacking, MIME sniffing, mixed content) 노출.

production_like 환경에서만 적용 — 로컬 개발 (`http://localhost`) 에서 HSTS 가 걸리면 자체 서명
인증서 / http 디버그가 어려워지기 때문.

CSP 는 site-specific 정책이라 본 미들웨어에서 강제하지 않는다 (frontend 호환성 확인 후 별도 PR).
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Any


def _is_production_like() -> bool:
    from app.core.config import PRODUCTION_LIKE_ENVIRONMENTS, settings

    return settings.ENVIRONMENT in PRODUCTION_LIKE_ENVIRONMENTS


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

                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_with_headers)
