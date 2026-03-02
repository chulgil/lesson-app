"""Schedule endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_availability(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/schedule/availability returns teacher availability."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/schedule/availability", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_set_availability(client: AsyncClient, auth_headers, create_test_user):
    """PUT /api/v1/schedule/availability sets weekly availability."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,
                    "time_slots": [
                        {"start_time": "09:00", "end_time": "18:00"},
                    ],
                },
                {
                    "day_of_week": 3,
                    "time_slots": [
                        {"start_time": "10:00", "end_time": "17:00"},
                    ],
                },
            ],
        },
    )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_get_weekly_schedule(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/schedule/weekly returns merged weekly schedule."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/schedule/weekly", headers=auth_headers)
    assert response.status_code == 200
