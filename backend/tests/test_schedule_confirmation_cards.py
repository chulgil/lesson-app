"""Schedule confirmation card API contract tests."""

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_confirmation_card_response_includes_flutter_aliases(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Card responses expose the field names used by Flutter ScheduleConfirmationCard."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(
        ScheduleConfirmationCard(
            id="card-aliases",
            student_id="student-001",
            teacher_id="test-user-id",
            subscription_id="sub-001",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            proposed_day="1",
            proposed_time="15:00",
            proposed_duration=60,
            proposed_slots=[
                {"day": 1, "time": "15:00"},
                {"day": 2, "time": "16:00"},
                {"day": 3, "time": "17:00"},
            ],
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.get("/api/v1/schedule/confirmation-cards/card-aliases", headers=auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["suggestedDay"] == 1
    assert body["suggestedTime"] == "15:00"
    assert body["lessonDuration"] == 60
    assert body["suggestedDay2"] == 2
    assert body["suggestedTime2"] == "16:00"
    assert body["suggestedDay3"] == 3
    assert body["suggestedTime3"] == "17:00"


@pytest.mark.asyncio
async def test_parent_can_read_linked_child_pending_confirmation_cards(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Linked parents can read their child's pending schedule confirmation cards."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-001"),
            ScheduleConfirmationCard(
                id="linked-child-card",
                student_id="student-001",
                teacher_id="teacher-001",
                subscription_id="sub-001",
                card_type="afterTrial",
                title="Confirm schedule",
                status="pending",
                proposed_day="1",
                proposed_time="15:00",
                created_at=datetime.now(UTC),
            ),
            ScheduleConfirmationCard(
                id="other-child-card",
                student_id="student-002",
                teacher_id="teacher-001",
                subscription_id="sub-002",
                card_type="afterTrial",
                title="Other schedule",
                status="pending",
                created_at=datetime.now(UTC),
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/confirmation-cards",
        headers=_headers("parent-user-id", "parent"),
        params={"student_id": "student-001", "status": "pending"},
    )

    assert response.status_code == 200
    assert [item["id"] for item in response.json()] == ["linked-child-card"]

    forbidden = await client.get(
        "/api/v1/schedule/confirmation-cards/other-child-card",
        headers=_headers("parent-user-id", "parent"),
    )
    assert forbidden.status_code == 403


@pytest.mark.asyncio
async def test_confirmation_card_lookup_by_subscription_and_status_update(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
    db_session,
):
    """Student clients can lookup by subscription and update card status."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    db_session.add(
        ScheduleConfirmationCard(
            id="student-card",
            student_id="test-student-id",
            teacher_id="teacher-001",
            subscription_id="sub-student-001",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    lookup = await client.get(
        "/api/v1/schedule/confirmation-cards/by-subscription/sub-student-001",
        headers=student_auth_headers,
    )
    assert lookup.status_code == 200
    assert lookup.json()["id"] == "student-card"

    update = await client.patch(
        "/api/v1/schedule/confirmation-cards/student-card/status",
        headers=student_auth_headers,
        json={"status": "changedTime"},
    )
    assert update.status_code == 200
    assert update.json()["status"] == "changedTime"
    assert update.json()["responded_at"] is not None


@pytest.mark.asyncio
async def test_dismiss_all_only_updates_visible_pending_cards(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """dismiss-all only affects pending cards for the current user's visible student."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-001"),
            ScheduleConfirmationCard(
                id="pending-visible",
                student_id="student-001",
                teacher_id="teacher-001",
                title="Visible",
                status="pending",
                created_at=datetime.now(UTC),
            ),
            ScheduleConfirmationCard(
                id="confirmed-visible",
                student_id="student-001",
                teacher_id="teacher-001",
                title="Already confirmed",
                status="confirmed",
                created_at=datetime.now(UTC),
            ),
            ScheduleConfirmationCard(
                id="pending-hidden",
                student_id="student-002",
                teacher_id="teacher-001",
                title="Hidden",
                status="pending",
                created_at=datetime.now(UTC),
            ),
        ]
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/schedule/confirmation-cards/dismiss-all",
        headers=_headers("parent-user-id", "parent"),
        json={"student_id": "student-001"},
    )

    assert response.status_code == 200
    assert response.json() == {"success": True, "message": "Dismissed 1 pending card"}

    visible = await client.get(
        "/api/v1/schedule/confirmation-cards",
        headers=_headers("parent-user-id", "parent"),
        params={"student_id": "student-001"},
    )
    statuses = {item["id"]: item["status"] for item in visible.json()}
    assert statuses == {
        "pending-visible": "dismissed",
        "confirmed-visible": "confirmed",
    }
