"""In-memory sliding-window rate limiter for sensitive auth endpoints.

저렴한 brute-force / credential-stuffing 방어용. slowapi 등 외부 의존성 없이 단일
프로세스 메모리에서 sliding window 카운터를 유지한다.

Production caveat:
- 다중 worker / 다중 인스턴스 환경에서는 worker 당 카운트가 분리된다 → 실효 한도는
  worker 수만큼 곱해진다. 강력한 보호가 필요하면 Redis 기반 분산 카운터로 교체.
- IP 기반 — proxy 뒤에서는 X-Forwarded-For 우선 사용 (settings.RATE_LIMIT_TRUST_PROXY).
- TESTING 환경에서는 ``settings.TESTING`` 플래그로 노옵 가능 (per-test fixture 가 옵트인).

사용:
    @router.post("/login", dependencies=[Depends(rate_limit("login", 10, 60))])
    async def login(...): ...

또는 dependency factory 사용:
    @router.post("/login")
    async def login(_: None = Depends(rate_limit("login", 10, 60)), ...): ...
"""

from __future__ import annotations

import time
from collections import defaultdict, deque
from collections.abc import Awaitable, Callable

from fastapi import Depends, HTTPException, Request, status

# 키 = (bucket_name, identifier) → deque[timestamp_seconds]
# defaultdict 로 자동 생성, sliding window 안 timestamp 만 유지.
_buckets: dict[tuple[str, str], deque[float]] = defaultdict(deque)


def _client_identifier(request: Request) -> str:
    """Return the rate-limit key for the request.

    X-Forwarded-For is client-forgeable: trusting it unconditionally lets every
    request mint a fresh bucket, turning the limiter into a no-op. It is only
    honored when RATE_LIMIT_TRUST_PROXY is enabled (deployment sits behind a
    trusted reverse proxy), and then the *last* hop is used — the one appended
    by our proxy — since the leading entries are client-controlled.
    """
    from app.core.config import settings

    forwarded = request.headers.get("x-forwarded-for", "").strip()
    if forwarded and getattr(settings, "RATE_LIMIT_TRUST_PROXY", False):
        return forwarded.split(",")[-1].strip()
    if request.client is not None:
        return request.client.host
    return "unknown"


def rate_limit(bucket: str, max_requests: int, window_seconds: int) -> Callable[..., Awaitable[None]]:
    """Build a FastAPI dependency that enforces ``max_requests`` per ``window_seconds`` per client IP.

    Args:
        bucket: 카운터를 분리할 키 (예: "auth_refresh", "auth_dev_login").
        max_requests: window 안 허용 요청 수.
        window_seconds: window 길이 (초).
    """

    async def _dependency(request: Request) -> None:
        from app.core.config import settings

        # TESTING 플래그가 켜져 있으면 노옵 — pytest 격리.
        if getattr(settings, "TESTING", False):
            return

        identifier = _client_identifier(request)
        now = time.monotonic()
        cutoff = now - window_seconds
        timestamps = _buckets[(bucket, identifier)]
        # 만료 항목 제거.
        while timestamps and timestamps[0] < cutoff:
            timestamps.popleft()
        if len(timestamps) >= max_requests:
            # window 가 다 차 있다면 가장 오래된 항목이 window 끝나는 시간까지 대기 — Retry-After.
            retry_after = max(1, int(timestamps[0] + window_seconds - now))
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests — please retry later.",
                headers={"Retry-After": str(retry_after)},
            )
        timestamps.append(now)

    return _dependency


# 미리 정의된 의존성 — `dependencies=[...]` 에 직접 넣을 수 있도록 Depends 객체로 노출.
# Annotated alias 와 `= None` 기본값 조합은 일부 FastAPI 버전에서 dependency 가 실행되지 않는
# 사례가 있어 (`dependencies=` 가 가장 안전한 패턴).
auth_refresh_rate_limit = Depends(rate_limit("auth_refresh", max_requests=20, window_seconds=60))
auth_dev_login_rate_limit = Depends(rate_limit("auth_dev_login", max_requests=10, window_seconds=60))
auth_oauth_rate_limit = Depends(rate_limit("auth_oauth", max_requests=20, window_seconds=60))
