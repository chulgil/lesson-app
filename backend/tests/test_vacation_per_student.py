"""per_student_disposition tests — #4 H-001 spec §4.2."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.schedule import VacationPeriod


def _headers(user_id: str = "test-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_register_stores_per_student_overrides(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """POST with per_student_disposition saves it onto the row + echoes in response."""
    await create_test_user(user_id="t-ps", role="teacher", email="tps@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-ps"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-05",
            "default_disposition": "rollForward",
            "per_student_disposition": {
                "student-A": "makeupCredit",
                "student-B": "freeCancel",
            },
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["per_student_disposition"] == {
        "student-A": "makeupCredit",
        "student-B": "freeCancel",
    }

    period = await db_session.get(VacationPeriod, body["id"])
    await db_session.refresh(period)
    assert period.per_student_disposition == {
        "student-A": "makeupCredit",
        "student-B": "freeCancel",
    }


@pytest.mark.asyncio
async def test_register_without_per_student_keeps_null(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """No overrides → null column. Listing returns it as null."""
    await create_test_user(user_id="t-noov", role="teacher", email="tno@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-noov"),
        json={
            "start_date": "2026-09-01",
            "end_date": "2026-09-03",
            "default_disposition": "rollForward",
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["per_student_disposition"] is None

    period = await db_session.get(VacationPeriod, body["id"])
    await db_session.refresh(period)
    assert period.per_student_disposition is None


@pytest.mark.asyncio
async def test_list_includes_per_student_disposition(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """GET /teacher/vacation returns per_student_disposition in each row."""
    await create_test_user(user_id="t-ls", role="teacher", email="tls@test.com")

    await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-ls"),
        json={
            "start_date": "2026-08-10",
            "end_date": "2026-08-12",
            "default_disposition": "rollForward",
            "per_student_disposition": {"student-X": "makeupCredit"},
        },
    )

    response = await client.get(
        "/api/v1/teacher/vacation",
        headers=_headers("t-ls"),
    )
    assert response.status_code == 200, response.text
    rows = response.json()["vacations"]
    assert len(rows) == 1
    assert rows[0]["per_student_disposition"] == {"student-X": "makeupCredit"}


@pytest.mark.asyncio
async def test_invalid_disposition_value_returns_422(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """Per-student disposition with an unknown value is rejected by validation."""
    await create_test_user(user_id="t-inv", role="teacher", email="tinv@test.com")

    response = await client.post(
        "/api/v1/teacher/vacation",
        headers=_headers("t-inv"),
        json={
            "start_date": "2026-08-01",
            "end_date": "2026-08-02",
            "per_student_disposition": {"student-A": "notARealOption"},
        },
    )
    assert response.status_code in (400, 422)
