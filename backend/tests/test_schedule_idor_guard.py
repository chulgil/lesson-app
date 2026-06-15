"""Schedule IDOR guard tests (#737, #738).

Before these guards:
- #737: Any authenticated teacher could PATCH /{change_id}/respond and mutate
  another teacher's LessonScheduleChange with no ownership check.
- #738: Any authenticated teacher could POST /schedule-exceptions/ and insert a
  ScheduleException under another teacher's TeacherAvailability slot.

These tests pin the new ownership-check contracts:
- Teacher B gets 403 when responding to teacher A's schedule change.
- Teacher A (owner) succeeds responding to their own schedule change.
- Teacher B gets 403 when creating an exception on teacher A's availability.
- Teacher A (owner) succeeds creating an exception on their own availability.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _auth_for(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _make_availability(db: AsyncSession, *, avail_id: str, teacher_id: str) -> None:
    """Insert a minimal TeacherAvailability row."""
    from app.models.schedule import TeacherAvailability

    avail = TeacherAvailability(
        id=avail_id,
        teacher_id=teacher_id,
        day_of_week=1,
    )
    db.add(avail)
    await db.flush()


async def _make_schedule_change(
    db: AsyncSession,
    *,
    change_id: str,
    teacher_id: str,
    student_id: str = "student-placeholder",
) -> None:
    """Insert a minimal LessonScheduleChange row owned by teacher_id."""
    import datetime

    from app.models.schedule_ext import LessonScheduleChange, ScheduleChangeType

    change = LessonScheduleChange(
        id=change_id,
        teacher_id=teacher_id,
        student_id=student_id,
        change_type=ScheduleChangeType.singleLesson,
        effective_from=datetime.date(2026, 7, 1),
    )
    db.add(change)
    await db.flush()


# ---------------------------------------------------------------------------
# #737 — respond_to_schedule_change IDOR
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_respond_to_other_teachers_change_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Teacher B must get 403 when responding to teacher A's schedule change."""
    teacher_a = await create_test_user(user_id="sc-a", role="teacher", email="sca@test.com")
    await create_test_user(user_id="sc-b", role="teacher", email="scb@test.com")

    await _make_schedule_change(
        db_session,
        change_id="change-owned-by-a",
        teacher_id=f"{teacher_a.id}-prof",  # teacher A's profile id
    )
    await db_session.commit()

    response = await client.patch(
        "/api/v1/schedule/lesson-schedule-changes/change-owned-by-a/respond",
        json={"action": "approved", "response_message": "ok"},
        headers=_auth_for("sc-b"),
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_respond_to_own_schedule_change_succeeds(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Owner teacher must be able to respond to their own schedule change."""
    teacher_a = await create_test_user(user_id="sc-owner", role="teacher", email="scowner@test.com")

    await _make_schedule_change(
        db_session,
        change_id="change-owned-by-owner",
        teacher_id=f"{teacher_a.id}-prof",
    )
    await db_session.commit()

    response = await client.patch(
        "/api/v1/schedule/lesson-schedule-changes/change-owned-by-owner/respond",
        json={"action": "approved", "response_message": "looks good"},
        headers=_auth_for("sc-owner"),
    )

    assert response.status_code == 200, response.text


# ---------------------------------------------------------------------------
# #738 — create_exception missing owner check
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_exception_on_other_teachers_availability_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Teacher B must get 403 when creating an exception on teacher A's availability."""
    teacher_a = await create_test_user(user_id="exc-a", role="teacher", email="exca@test.com")
    await create_test_user(user_id="exc-b", role="teacher", email="excb@test.com")

    await _make_availability(
        db_session,
        avail_id="avail-owned-by-a",
        teacher_id=f"{teacher_a.id}-prof",
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/schedule-exceptions/",
        params={"teacher_availability_id": "avail-owned-by-a"},
        json={
            "type": "vacation",
            "start_date": "2026-07-10",
            "end_date": "2026-07-10",
        },
        headers=_auth_for("exc-b"),
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_create_exception_on_own_availability_succeeds(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Owner teacher must be able to create an exception on their own availability."""
    teacher_a = await create_test_user(user_id="exc-owner", role="teacher", email="excowner@test.com")

    await _make_availability(
        db_session,
        avail_id="avail-owned-by-exc-owner",
        teacher_id=f"{teacher_a.id}-prof",
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/schedule-exceptions/",
        params={"teacher_availability_id": "avail-owned-by-exc-owner"},
        json={
            "type": "vacation",
            "start_date": "2026-07-10",
            "end_date": "2026-07-10",
        },
        headers=_auth_for("exc-owner"),
    )

    assert response.status_code == 201, response.text
