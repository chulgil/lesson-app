"""Contract tests for schedule availability integrity constraints."""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory
from httpx import AsyncClient
import pytest

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_schedule_integrity_constraints_are_declared_in_model_metadata() -> None:
    teacher_availability = Base.metadata.tables["teacher_availabilities"]
    availability_slot = Base.metadata.tables["availability_time_slots"]

    teacher_availability_constraints = {constraint.name for constraint in teacher_availability.constraints}
    availability_slot_constraints = {constraint.name for constraint in availability_slot.constraints}

    assert "ck_teacher_availabilities_day_of_week" in teacher_availability_constraints
    assert "ck_availability_time_slots_temporal_order" in availability_slot_constraints


def test_schedule_integrity_migration_declares_constraints() -> None:
    script = _script()
    rev = script.get_revision("add_schedule_availability_time_constraints")
    assert rev is not None
    assert rev.down_revision == "add_notification_user_fks"

    source = Path(rev.module.__file__).read_text()
    assert "ck_teacher_availabilities_day_of_week" in source
    assert "ck_availability_time_slots_temporal_order" in source


@pytest.mark.asyncio
async def test_schedule_availability_rejects_invalid_slot_range(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 1,
                    "time_slots": [
                        {"start_time": "15:00", "end_time": "14:00"},
                    ],
                }
            ],
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_legacy_availability_rejects_overlapping_slots(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/availability/",
        headers=auth_headers,
        json={
            "day_of_week": 2,
            "time_slots": [
                {"start_time": "10:00", "end_time": "13:00"},
                {"start_time": "12:00", "end_time": "14:00"},
            ],
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_schedule_exception_rejects_invalid_date_range(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/schedule/exceptions",
        headers=auth_headers,
        json={
            "start_date": "2026-05-10",
            "end_date": "2026-05-05",
            "type": "holiday",
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_schedule_exception_rejects_invalid_time_range(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/schedule/exceptions",
        headers=auth_headers,
        json={
            "start_date": "2026-05-05",
            "type": "vacation",
            "start_time": "14:00",
            "end_time": "14:00",
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_schedule_exception_update_rejects_partial_time_payload(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    created = await client.post(
        "/api/v1/schedule/exceptions",
        headers=auth_headers,
        json={
            "start_date": "2026-05-06",
            "type": "vacation",
        },
    )
    assert created.status_code == 201
    exc_id = created.json()["id"]

    response = await client.put(
        f"/api/v1/schedule/exceptions/{exc_id}",
        headers=auth_headers,
        json={"start_time": "10:00"},
    )

    assert response.status_code == 422
