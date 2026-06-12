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

    async def create_lesson_class(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/lessons-classes",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create lesson class")
        return response.json()

    async def create_membership(self, access_token: str, class_id: str, **payload: Any) -> dict:
        response = await self._client.post(
            f"/api/v1/lessons-classes/{class_id}/memberships",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create membership")
        return response.json()

    async def get_memberships(self, access_token: str, *, student_id: str) -> list[dict]:
        response = await self._client.get(
            "/api/v1/memberships",
            headers=self._auth_headers(access_token),
            params={"student_id": student_id},
        )
        assert response.status_code == 200, _response_error(response, "memberships")
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

    # -- Lesson Requests -------------------------------------------------------

    async def create_lesson_request(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/schedule/lesson-requests",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create lesson request")
        return response.json()

    async def get_lesson_request(self, access_token: str, request_id: str) -> dict:
        response = await self._client.get(
            f"/api/v1/schedule/lesson-requests/{request_id}",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "get lesson request")
        return response.json()

    async def list_lesson_requests(self, access_token: str, **params: Any) -> dict:
        response = await self._client.get(
            "/api/v1/schedule/lesson-requests",
            headers=self._auth_headers(access_token),
            params=params,
        )
        assert response.status_code == 200, _response_error(response, "list lesson requests")
        return response.json()

    async def update_lesson_request_status(self, access_token: str, request_id: str, **payload: Any) -> dict:
        response = await self._client.patch(
            f"/api/v1/schedule/lesson-requests/{request_id}/status",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 200, _response_error(response, "update lesson request status")
        return response.json()

    async def propose_alternatives(self, access_token: str, request_id: str, slots: list[dict], **payload: Any) -> dict:
        response = await self._client.post(
            f"/api/v1/schedule/lesson-requests/{request_id}/propose-alternatives",
            headers=self._auth_headers(access_token),
            json={"slots": slots, **payload},
        )
        assert response.status_code == 200, _response_error(response, "propose alternatives")
        return response.json()

    async def accept_alternative(
        self, access_token: str, request_id: str, selected_slot_index: int, **payload: Any
    ) -> dict:
        response = await self._client.post(
            f"/api/v1/schedule/lesson-requests/{request_id}/accept-alternative",
            headers=self._auth_headers(access_token),
            json={"selected_slot_index": selected_slot_index, **payload},
        )
        assert response.status_code == 200, _response_error(response, "accept alternative")
        return response.json()

    async def delete_lesson_request(self, access_token: str, request_id: str) -> None:
        response = await self._client.delete(
            f"/api/v1/schedule/lesson-requests/{request_id}",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 204, _response_error(response, "delete lesson request")

    # -- Lessons ---------------------------------------------------------------

    async def create_lesson(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/lessons",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create lesson")
        return response.json()

    async def get_lesson(self, access_token: str, lesson_id: str) -> dict:
        response = await self._client.get(
            f"/api/v1/lessons/{lesson_id}",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "get lesson")
        return response.json()

    async def update_lesson_status(self, access_token: str, lesson_id: str, status: str) -> dict:
        response = await self._client.patch(
            f"/api/v1/lessons/{lesson_id}/status",
            headers=self._auth_headers(access_token),
            json={"status": status},
        )
        assert response.status_code == 200, _response_error(response, f"update lesson status to {status}")
        return response.json()

    async def update_lesson_status_expect(
        self, access_token: str, lesson_id: str, status: str, expected_status: int
    ) -> httpx.Response:
        """Update lesson status without asserting — caller checks expected_status."""
        return await self._client.patch(
            f"/api/v1/lessons/{lesson_id}/status",
            headers=self._auth_headers(access_token),
            json={"status": status},
        )

    # -- Subscriptions ---------------------------------------------------------

    async def create_subscription(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/subscriptions",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create subscription")
        return response.json()

    async def get_subscription(self, access_token: str, subscription_id: str) -> dict:
        response = await self._client.get(
            f"/api/v1/subscriptions/{subscription_id}",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "get subscription")
        return response.json()

    async def use_lesson(self, access_token: str, subscription_id: str, lesson_id: str) -> dict:
        response = await self._client.patch(
            f"/api/v1/subscriptions/{subscription_id}/use-lesson",
            headers=self._auth_headers(access_token),
            json={"lesson_id": lesson_id},
        )
        assert response.status_code == 200, _response_error(response, "use lesson")
        return response.json()

    # -- Schedule Changes ------------------------------------------------------

    async def create_schedule_change(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/schedule-changes",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create schedule change")
        return response.json()

    async def get_pending_schedule_changes(self, access_token: str) -> dict:
        response = await self._client.get(
            "/api/v1/schedule-changes/pending",
            headers=self._auth_headers(access_token),
        )
        assert response.status_code == 200, _response_error(response, "pending schedule changes")
        return response.json()

    async def respond_to_schedule_change(self, access_token: str, change_id: str, action: str, **payload: Any) -> dict:
        response = await self._client.patch(
            f"/api/v1/schedule-changes/{change_id}/respond",
            headers=self._auth_headers(access_token),
            json={"action": action, **payload},
        )
        assert response.status_code == 200, _response_error(response, f"respond to schedule change: {action}")
        return response.json()

    # -- No-Show ---------------------------------------------------------------

    async def create_no_show(self, access_token: str, **payload: Any) -> dict:
        response = await self._client.post(
            "/api/v1/groups/no-shows",
            headers=self._auth_headers(access_token),
            json=payload,
        )
        assert response.status_code == 201, _response_error(response, "create no-show record")
        return response.json()

    # -- Raw request (for error-path tests) ------------------------------------

    async def raw_get(self, path: str, headers: dict[str, str] | None = None) -> httpx.Response:
        """Issue a GET without asserting status — caller inspects response."""
        return await self._client.get(path, headers=headers or {})

    async def raw_patch(
        self, path: str, headers: dict[str, str] | None = None, json: dict | None = None
    ) -> httpx.Response:
        """Issue a PATCH without asserting status — caller inspects response."""
        return await self._client.patch(path, headers=headers or {}, json=json or {})

    @staticmethod
    def _auth_headers(access_token: str) -> dict[str, str]:
        return {"Authorization": f"Bearer {access_token}"}


def _response_error(response: httpx.Response, label: str) -> str:
    body = response.text[:500]
    return f"{label} failed: status={response.status_code}, body={body}"
