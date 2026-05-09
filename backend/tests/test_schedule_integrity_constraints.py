"""Contract tests for schedule availability integrity constraints."""

from pathlib import Path

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory
from httpx import AsyncClient

from app.core.security import create_access_token
from app.models.base import Base


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_schedule_integrity_constraints_are_declared_in_model_metadata() -> None:
    teacher_availability = Base.metadata.tables["teacher_availabilities"]
    availability_slot = Base.metadata.tables["availability_time_slots"]
    lesson_bookings = Base.metadata.tables["lesson_bookings"]
    schedule_exceptions = Base.metadata.tables["schedule_exceptions"]

    teacher_availability_constraints = {constraint.name for constraint in teacher_availability.constraints}
    availability_slot_constraints = {constraint.name for constraint in availability_slot.constraints}
    schedule_exception_constraints = {constraint.name for constraint in schedule_exceptions.constraints}
    lesson_booking_indexes = {idx.name for idx in lesson_bookings.indexes}
    booking_subscription_fk = {
        fk.target_fullname for fk in lesson_bookings.c["subscription_id"].foreign_keys
    }

    assert "ck_teacher_availabilities_day_of_week" in teacher_availability_constraints
    assert "ck_availability_time_slots_temporal_order" in availability_slot_constraints
    assert "ck_sched_exc_owner_scope" in schedule_exception_constraints
    assert "idx_booking_subscription" in lesson_booking_indexes
    assert "subscriptions.id" in booking_subscription_fk


def test_schedule_integrity_migration_declares_constraints() -> None:
    script = _script()
    rev = script.get_revision("add_schedule_availability_time_constraints")
    assert rev is not None
    assert rev.down_revision == "add_notification_user_fks"

    source = Path(rev.module.__file__).read_text()
    assert "ck_teacher_availabilities_day_of_week" in source
    assert "ck_availability_time_slots_temporal_order" in source


def test_schedule_exception_owner_scope_migration_declares_constraints() -> None:
    script = _script()
    rev = script.get_revision("add_schedule_exception_owner_scope")
    assert rev is not None
    assert rev.down_revision == "add_booking_subscription_origin"

    source = Path(rev.module.__file__).read_text()
    assert "ck_sched_exc_owner_scope" in source
    assert "idx_sched_exc_teacher" in source
    assert "teacher_id" in source


def test_booking_subscription_origin_migration_declares_fk_and_index() -> None:
    script = _script()
    rev = script.get_revision("add_booking_subscription_origin")
    assert rev is not None
    assert rev.down_revision == "add_schedule_availability_time_constraints"

    source = Path(rev.module.__file__).read_text()
    assert "fk_lesson_bookings_subscription_id_subscriptions" in source
    assert "idx_booking_subscription" in source


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
    await client.put(
        "/api/v1/schedule/availability",
        headers=auth_headers,
        json={
            "availabilities": [
                {
                    "day_of_week": 0,
                    "time_slots": [
                        {"start_time": "09:00", "end_time": "18:00"},
                    ],
                }
            ]
        },
    )

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


@pytest.mark.asyncio
async def test_schedule_exception_update_requires_ownership(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(
        user_id="teacher-owner-id",
        role="teacher",
        email="owner-update@test.com",
    )
    await create_test_user(
        user_id="teacher-other-id",
        role="teacher",
        email="other-update@test.com",
    )
    await client.put(
        "/api/v1/schedule/availability",
        headers=_headers("teacher-owner-id"),
        json={
            "availabilities": [
                {
                    "day_of_week": 0,
                    "time_slots": [
                        {"start_time": "09:00", "end_time": "18:00"},
                    ],
                }
            ]
        },
    )

    create_response = await client.post(
        "/api/v1/schedule/exceptions",
        headers=_headers("teacher-owner-id"),
        json={
            "start_date": "2026-05-07",
            "type": "holiday",
        },
    )
    assert create_response.status_code == 201
    exc_id = create_response.json()["id"]

    update_response = await client.put(
        f"/api/v1/schedule/exceptions/{exc_id}",
        headers=_headers("teacher-other-id"),
        json={"reason": "blocked"},
    )

    assert update_response.status_code == 403


@pytest.mark.asyncio
async def test_schedule_exception_delete_requires_ownership(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(
        user_id="teacher-owner-id-2",
        role="teacher",
        email="owner-delete@test.com",
    )
    await create_test_user(
        user_id="teacher-other-id-2",
        role="teacher",
        email="other-delete@test.com",
    )
    await client.put(
        "/api/v1/schedule/availability",
        headers=_headers("teacher-owner-id-2"),
        json={
            "availabilities": [
                {
                    "day_of_week": 0,
                    "time_slots": [
                        {"start_time": "09:00", "end_time": "18:00"},
                    ],
                }
            ]
        },
    )

    create_response = await client.post(
        "/api/v1/schedule/exceptions",
        headers=_headers("teacher-owner-id-2"),
        json={
            "start_date": "2026-05-08",
            "type": "holiday",
        },
    )
    assert create_response.status_code == 201
    exc_id = create_response.json()["id"]

    delete_response = await client.delete(
        f"/api/v1/schedule/exceptions/{exc_id}",
        headers=_headers("teacher-other-id-2"),
    )

    assert delete_response.status_code == 403
