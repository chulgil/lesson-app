"""OAuth error-response leak guard (#407).

Before this guard, Google's raw error response body was echoed back to the
client in the HTTPException detail:

    detail=f"Google token exchange failed: {token_resp.text}"

Google's error body can contain diagnostic info (echoed redirect_uri, internal
trace IDs, partial token material). This test pins that the API surface never
leaks the upstream provider's response body to the caller.

Kakao/Apple paths already return a fixed generic message; this test focuses on
Google.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_google_token_exchange_failure_does_not_leak_upstream_body(
    client: AsyncClient,
) -> None:
    """A 4xx from Google's token endpoint must not echo Google's response.text."""
    leaked_marker = "GOOGLE_INTERNAL_TRACE_xyz123_DO_NOT_LEAK"
    leaked_body = (
        f'{{"error":"invalid_grant","error_description":"{leaked_marker}","trace_id":"backend-only-trace-id"}}'
    )

    mock_resp = MagicMock()
    mock_resp.status_code = 400
    mock_resp.text = leaked_body

    mock_http_client = MagicMock()
    mock_http_client.post = AsyncMock(return_value=mock_resp)

    mock_ctx = MagicMock()
    mock_ctx.__aenter__ = AsyncMock(return_value=mock_http_client)
    mock_ctx.__aexit__ = AsyncMock(return_value=None)

    with patch("app.services.auth_service.httpx.AsyncClient", return_value=mock_ctx):
        response = await client.post(
            "/api/v1/auth/oauth/google",
            json={"provider": "google", "code": "client-supplied-auth-code"},
        )

    assert response.status_code == 401, response.text
    detail = response.json().get("detail", "")
    assert leaked_marker not in detail, f"Upstream Google error body leaked into HTTP response detail: {detail!r}"
    assert "trace_id" not in detail, f"Upstream trace_id leaked: {detail!r}"
    assert "invalid_grant" not in detail, f"Upstream OAuth error code leaked: {detail!r}"
    # The fixed message is allowed; just verify it's stable / generic.
    assert "Google" in detail or "token" in detail.lower(), (
        f"Expected a generic provider-failure message, got: {detail!r}"
    )


@pytest.mark.asyncio
async def test_google_userinfo_failure_does_not_leak_upstream_body(
    client: AsyncClient,
) -> None:
    """A 4xx from Google's userinfo endpoint must also stay generic.

    Currently the userinfo path already returns a generic message, but pin it
    so a future "improve error messages" refactor cannot reintroduce the leak.
    """
    leaked_marker = "USERINFO_INTERNAL_LEAK_abc789"

    token_resp = MagicMock(status_code=200)
    token_resp.json = MagicMock(return_value={"access_token": "fake"})

    userinfo_resp = MagicMock()
    userinfo_resp.status_code = 401
    userinfo_resp.text = f'{{"error":"{leaked_marker}"}}'

    mock_http_client = MagicMock()
    mock_http_client.post = AsyncMock(return_value=token_resp)
    mock_http_client.get = AsyncMock(return_value=userinfo_resp)

    mock_ctx = MagicMock()
    mock_ctx.__aenter__ = AsyncMock(return_value=mock_http_client)
    mock_ctx.__aexit__ = AsyncMock(return_value=None)

    with patch("app.services.auth_service.httpx.AsyncClient", return_value=mock_ctx):
        response = await client.post(
            "/api/v1/auth/oauth/google",
            json={"provider": "google", "code": "client-supplied-auth-code"},
        )

    assert response.status_code == 401, response.text
    detail = response.json().get("detail", "")
    assert leaked_marker not in detail, f"Upstream userinfo body leaked into HTTP response detail: {detail!r}"
