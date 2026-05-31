"""Helpers for remote beta API integration tests."""

from __future__ import annotations

from dataclasses import dataclass

import httpx


@dataclass(frozen=True)
class BetaAccount:
    email: str
    role: str
    expected_user_id: str


@dataclass(frozen=True)
class BetaTokens:
    access_token: str
    refresh_token: str
    user: dict


class BetaClient:
    """Small HTTP wrapper that keeps beta integration failures readable."""

    def __init__(self, client: httpx.AsyncClient, internal_api_key: str) -> None:
        self._client = client
        self._internal_api_key = internal_api_key

    async def health(self) -> httpx.Response:
        return await self._client.get("/health")

    async def dev_login(self, account: BetaAccount) -> BetaTokens:
        response = await self._client.post(
            "/api/v1/auth/dev-login",
            headers={"X-Internal-API-Key": self._internal_api_key},
            json={"email": account.email, "role": account.role},
        )
        assert response.status_code == 200, _response_error(response, "dev-login")
        data = response.json()
        return BetaTokens(
            access_token=data["access_token"],
            refresh_token=data["refresh_token"],
            user=data["user"],
        )

    async def get_me(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        assert response.status_code == 200, _response_error(response, "auth/me")
        return response.json()


def _response_error(response: httpx.Response, label: str) -> str:
    body = response.text[:500]
    return f"{label} failed: status={response.status_code}, body={body}"
