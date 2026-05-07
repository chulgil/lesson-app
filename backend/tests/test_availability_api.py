"""Tests for the legacy /availability API."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_availability_mutations_are_scoped_to_owner(
    client: AsyncClient,
    create_test_user,
):
    """Teachers cannot mutate another teacher's availability or time slots."""
    await create_test_user(user_id="teacher-a-id", role="teacher", email="teacher-a-availability@test.com")
    await create_test_user(user_id="teacher-b-id", role="teacher", email="teacher-b-availability@test.com")

    create_response = await client.post(
        "/api/v1/availability/",
        headers=_headers("teacher-b-id"),
        json={
            "day_of_week": 1,
            "time_slots": [
                {
                    "start_time": "10:00",
                    "end_time": "11:00",
                    "is_available": True,
                }
            ],
        },
    )
    assert create_response.status_code == 201
    availability = create_response.json()
    availability_id = availability["id"]
    slot_id = availability["time_slots"][0]["id"]

    update_response = await client.put(
        f"/api/v1/availability/{availability_id}",
        headers=_headers("teacher-a-id"),
        json={
            "day_of_week": 2,
            "time_slots": [
                {
                    "start_time": "12:00",
                    "end_time": "13:00",
                    "is_available": True,
                }
            ],
        },
    )
    assert update_response.status_code == 403

    add_slot_response = await client.post(
        f"/api/v1/availability/{availability_id}/slots",
        headers=_headers("teacher-a-id"),
        json={
            "start_time": "14:00",
            "end_time": "15:00",
            "is_available": True,
        },
    )
    assert add_slot_response.status_code == 403

    remove_slot_response = await client.delete(
        f"/api/v1/availability/slots/{slot_id}",
        headers=_headers("teacher-a-id"),
    )
    assert remove_slot_response.status_code == 403

    delete_response = await client.delete(
        f"/api/v1/availability/{availability_id}",
        headers=_headers("teacher-a-id"),
    )
    assert delete_response.status_code == 403

    owner_list = await client.get(
        "/api/v1/availability/?teacher_id=teacher-b-id-prof",
        headers=_headers("teacher-b-id"),
    )
    assert owner_list.status_code == 200
    assert owner_list.json()[0]["day_of_week"] == 1


@pytest.mark.asyncio
async def test_availability_update_rejects_overlapping_time_slots(client: AsyncClient, create_test_user):
    """Updating availability with overlapping slots should fail early."""
    await create_test_user(user_id="teacher-owner", role="teacher")

    create_response = await client.post(
        "/api/v1/availability/",
        headers=_headers("teacher-owner"),
        json={
            "day_of_week": 2,
            "time_slots": [
                {
                    "start_time": "10:00",
                    "end_time": "11:00",
                    "is_available": True,
                }
            ],
        },
    )
    assert create_response.status_code == 201
    availability_id = create_response.json()["id"]

    update_response = await client.put(
        f"/api/v1/availability/{availability_id}",
        headers=_headers("teacher-owner"),
        json={
            "time_slots": [
                {
                    "start_time": "10:30",
                    "end_time": "12:00",
                    "is_available": True,
                },
                {
                    "start_time": "11:30",
                    "end_time": "13:00",
                    "is_available": True,
                },
            ],
        },
    )

    assert update_response.status_code == 422


@pytest.mark.asyncio
async def test_availability_add_time_slot_rejects_overlap(client: AsyncClient, create_test_user):
    """Adding an overlapping time slot should be rejected."""
    await create_test_user(user_id="teacher-slot-owner", role="teacher")

    create_response = await client.post(
        "/api/v1/availability/",
        headers=_headers("teacher-slot-owner"),
        json={
            "day_of_week": 3,
            "time_slots": [
                {
                    "start_time": "10:00",
                    "end_time": "11:00",
                    "is_available": True,
                }
            ],
        },
    )
    assert create_response.status_code == 201
    availability_id = create_response.json()["id"]

    add_response = await client.post(
        f"/api/v1/availability/{availability_id}/slots",
        headers=_headers("teacher-slot-owner"),
        json={
            "start_time": "10:30",
            "end_time": "11:30",
            "is_available": True,
        },
    )

    assert add_response.status_code == 422
