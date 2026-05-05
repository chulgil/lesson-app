from __future__ import annotations

from httpx import AsyncClient

from app.core.config import settings


async def test_scheduler_attendance_endpoint_requires_internal_api_key(
    client: AsyncClient,
    monkeypatch,
) -> None:
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")

    response = await client.post("/api/v1/scheduler/attendance/run-all")

    assert response.status_code == 401


async def test_scheduler_attendance_endpoint_rejects_wrong_internal_api_key(
    client: AsyncClient,
    monkeypatch,
) -> None:
    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")

    response = await client.post(
        "/api/v1/scheduler/attendance/run-all",
        headers={"X-Internal-API-Key": "wrong-key"},
    )

    assert response.status_code == 401
