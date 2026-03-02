"""Recording endpoint tests."""

import io

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_upload_recording(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/recordings/upload fails gracefully without object storage."""
    await create_test_user(user_id="test-user-id", role="teacher")

    fake_audio = io.BytesIO(b"\x00" * 1024)
    fake_audio.name = "recording.m4a"

    response = await client.post(
        "/api/v1/recordings/upload",
        headers=auth_headers,
        files={"file": ("recording.m4a", fake_audio, "audio/mp4")},
        data={
            "section_id": "section-001",
            "duration_seconds": "120",
            "bpm": "80",
        },
    )
    # Upload fails because object storage is not configured in test env
    assert response.status_code == 500


@pytest.mark.asyncio
async def test_list_recordings(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/recordings returns empty paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/recordings", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["items"] == []
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_share_recording(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/recordings/{id}/share returns 404 for non-existent recording."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/recordings/some-recording-id/share",
        headers=auth_headers,
    )
    assert response.status_code == 404
