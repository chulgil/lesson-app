"""Practice endpoint tests: repertoires, sections, stats."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_repertoire(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/practice/repertoires creates a repertoire and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Bach Partita No.2",
            "start_date": "2026-03-01",
            "sections": [
                {
                    "repertoire_id": "placeholder",
                    "piece_name": "Allemanda",
                    "range_type": "measures",
                    "start_measure": 1,
                    "end_measure": 16,
                },
            ],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Bach Partita No.2"
    assert data["student_id"] == "student-001"
    assert "id" in data


@pytest.mark.asyncio
async def test_list_repertoires(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/practice/repertoires returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a repertoire first
    await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Mozart Sonata K.304",
        },
    )

    response = await client.get("/api/v1/practice/repertoires", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_create_section(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/practice/sections creates a section and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a repertoire first
    rep_resp = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Vivaldi Concerto",
        },
    )
    repertoire_id = rep_resp.json()["id"]

    response = await client.post(
        "/api/v1/practice/sections",
        headers=auth_headers,
        json={
            "repertoire_id": repertoire_id,
            "piece_name": "Allegro",
            "range_type": "measures",
            "start_measure": 1,
            "end_measure": 32,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["repertoire_id"] == repertoire_id
    assert data["piece_name"] == "Allegro"
    assert data["start_measure"] == 1
    assert data["end_measure"] == 32


@pytest.mark.asyncio
async def test_toggle_section_complete(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/practice/sections/{id}/complete toggles completion."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create repertoire and section
    rep_resp = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "name": "Paganini Caprice",
        },
    )
    repertoire_id = rep_resp.json()["id"]

    sec_resp = await client.post(
        "/api/v1/practice/sections",
        headers=auth_headers,
        json={
            "repertoire_id": repertoire_id,
            "piece_name": "No.24",
            "start_measure": 1,
            "end_measure": 20,
        },
    )
    section_id = sec_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/practice/sections/{section_id}/complete",
        headers=auth_headers,
        json={
            "date": "2026-03-02",
            "is_completed": True,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == section_id


@pytest.mark.asyncio
async def test_get_practice_stats(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/practice/stats returns practice statistics."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/practice/stats", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_practice_minutes" in data
    assert "total_practice_days" in data
    assert "completed_sections" in data
    assert "current_streak" in data
    assert "longest_streak" in data
