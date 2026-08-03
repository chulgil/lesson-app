"""Idempotency middleware — server-side POST dedupe (#1117, SN-4/INV-2).

Wraps mutating requests carrying an ``Idempotency-Key`` header. Applies to POST
only: PUT/DELETE are naturally idempotent, so re-sending them cannot duplicate a
resource. Unauthenticated requests pass through — dedupe is scoped per user.

Flow: resolve the caller from the bearer token → reserve the key (its own
transaction, separate from the handler's session) → run the handler → store its
response for replay. A concurrent duplicate that loses the reservation race gets
either the stored response (replay) or ``409 CONFLICT_IN_FLIGHT`` while the
original is still processing.
"""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse, Response

from app.core.database import AsyncSessionLocal, get_db
from app.core.security import decode_access_token
from app.services.idempotency_service import IN_FLIGHT, REPLAY, IdempotencyService

_HEADER = "Idempotency-Key"
# Headers that must not be copied verbatim when rebuilding the captured response
# (Response recomputes content-length; hop-by-hop headers are per-connection).
_SKIP_HEADERS = {"content-length"}


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """POST dedupe via the client-generated ``Idempotency-Key`` header."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        if request.method != "POST":
            return await call_next(request)

        idem_key = request.headers.get(_HEADER)
        if not idem_key:
            return await call_next(request)

        user_id = _resolve_user_id(request)
        if user_id is None:
            # Dedupe requires a user scope — unauthenticated requests pass through.
            return await call_next(request)

        session, close_session = await _open_session(request)
        try:
            service = IdempotencyService(session)
            outcome = await service.reserve_or_replay(
                user_id=user_id,
                idem_key=idem_key,
                method="POST",
                path=request.url.path,
            )
            if outcome.kind == REPLAY:
                return JSONResponse(
                    content=outcome.response_body,
                    status_code=outcome.status_code or 200,
                )
            if outcome.kind == IN_FLIGHT:
                return _conflict_in_flight()

            # Reserved → run the handler, then persist its response for replay.
            return await _process_and_store(
                request=request,
                call_next=call_next,
                service=service,
                user_id=user_id,
                idem_key=idem_key,
            )
        finally:
            await close_session()


async def _process_and_store(
    *,
    request: Request,
    call_next: RequestResponseEndpoint,
    service: IdempotencyService,
    user_id: str,
    idem_key: str,
) -> Response:
    try:
        response = await call_next(request)
    except Exception:
        # The handler blew up (unhandled 500). Release the reservation so a
        # retry can re-run rather than being wedged on a poisoned in-flight row.
        await service.release(user_id=user_id, idem_key=idem_key)
        raise

    body = b""
    async for chunk in response.body_iterator:
        body += chunk

    if 200 <= response.status_code < 500:
        # 2xx/4xx are deterministic outcomes → store for replay.
        await service.store_response(
            user_id=user_id,
            idem_key=idem_key,
            status_code=response.status_code,
            response_body=_parse_json(body),
        )
    else:
        # 5xx is transient — release so the client's retry re-processes.
        await service.release(user_id=user_id, idem_key=idem_key)

    headers = {k: v for k, v in response.headers.items() if k.lower() not in _SKIP_HEADERS}
    return Response(
        content=body,
        status_code=response.status_code,
        headers=headers,
        media_type=response.media_type,
    )


def _resolve_user_id(request: Request) -> str | None:
    """Decode the bearer token to the acting user id (``sub``), or None."""
    auth = request.headers.get("Authorization")
    if not auth or not auth.lower().startswith("bearer "):
        return None
    token = auth[7:].strip()
    payload = decode_access_token(token)
    if payload is None:
        return None
    return payload.get("sub")


async def _open_session(request: Request) -> tuple[object, Callable[[], Awaitable[None]]]:
    """Yield a DB session, honouring a ``get_db`` dependency override in tests.

    Production: a dedicated ``AsyncSessionLocal`` session (separate from the
    handler's request session, which is what makes reserve-first race-safe).
    Tests override ``get_db`` — reuse that session so middleware writes hit the
    same in-memory/SQLite DB the test asserts against.
    """
    override = request.app.dependency_overrides.get(get_db)
    if override is not None:
        gen = override()
        session = await gen.__anext__()

        async def _close_override() -> None:
            try:
                await gen.aclose()
            except Exception:
                pass

        return session, _close_override

    session = AsyncSessionLocal()

    async def _close() -> None:
        await session.close()

    return session, _close


def _parse_json(body: bytes) -> object | None:
    if not body:
        return None
    try:
        return json.loads(body)
    except (json.JSONDecodeError, UnicodeDecodeError):
        # Non-JSON body (rare for POST) — status-only replay.
        return None


def _conflict_in_flight() -> JSONResponse:
    return JSONResponse(
        status_code=409,
        content={
            "error": {
                "code": "CONFLICT_IN_FLIGHT",
                "detail": "동일 요청이 처리 중입니다. 잠시 후 다시 시도해주세요.",
            }
        },
    )
