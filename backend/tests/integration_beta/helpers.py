"""Helpers for remote beta API integration tests."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

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

    async def dev_login(self, account: BetaAccount, *, name: str | None = None) -> BetaTokens:
        payload: dict[str, str] = {"email": account.email, "role": account.role}
        if name is not None:
            payload["name"] = name
        response = await self._client.post(
            "/api/v1/auth/dev-login",
            headers={"X-Internal-API-Key": self._internal_api_key},
            json=payload,
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

    async def create_student(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/students",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create student")
        return response.json()

    async def get_students(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/students",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "students")
        return response.json()

    async def create_invite(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/invites/",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create invite")
        return response.json()

    async def create_connection_request(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/invites/connection-requests",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create connection request")
        return response.json()

    async def get_sent_connection_requests(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/invites/connection-requests/sent",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "sent connection requests")
        return response.json()

    async def get_pending_connection_requests(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/invites/connection-requests/pending",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "pending connection requests")
        return response.json()

    async def respond_to_connection_request(
        self,
        access_token: str,
        request_id: str,
        *,
        action: str,
    ) -> dict:
        response = await self._client.patch(
            f"/api/v1/invites/connection-requests/{request_id}/respond",
            headers=self._auth_headers(access_token),
            json={"action": action},
        )
        assert response.status_code == 200, _response_error(response, "respond connection request")
        return response.json()

    async def get_connections(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/invites/connections",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "connections")
        return response.json()

    @staticmethod
    def _auth_headers(access_token: str) -> dict[str, str]:
        return {"Authorization": f"Bearer {access_token}"}


def _response_error(response: httpx.Response, label: str) -> str:
    body = response.text[:500]
    return f"{label} failed: status={response.status_code}, body={body}"
