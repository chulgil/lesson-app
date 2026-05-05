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
async def test_confirmation_card_response_aliases_fallback_without_proposed_slots(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Response aliases fall back to proposed_* fields when proposed_slots is absent."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="alias-fallback-teacher", role="teacher", email="alias-fallback-teacher@test.com")
    db_session.add(
        ScheduleConfirmationCard(
            id="card-alias-fallback",
            student_id="alias-fallback-student",
            teacher_id="alias-fallback-teacher",
            subscription_id="sub-alias-fallback",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            proposed_day="4",
            proposed_time="18:30",
            proposed_duration=45,
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/confirmation-cards/card-alias-fallback",
        headers=_headers("alias-fallback-teacher", "teacher"),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["suggestedDay"] == 4
    assert body["suggestedTime"] == "18:30"
    assert body["lessonDuration"] == 45
    assert body["suggestedDay2"] is None
    assert body["suggestedTime2"] is None
    assert body["suggestedDay3"] is None
    assert body["suggestedTime3"] is None


@pytest.mark.asyncio
async def test_confirmation_card_response_aliases_preserve_only_available_partial_slots(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Partial proposed_slots populate only available suggested* aliases."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="partial-slots-teacher", role="teacher", email="partial-slots-teacher@test.com")
    db_session.add(
        ScheduleConfirmationCard(
            id="card-partial-slots",
            student_id="partial-slots-student",
            teacher_id="partial-slots-teacher",
            subscription_id="sub-partial-slots",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            proposed_day="1",
            proposed_time="15:00",
            proposed_duration=60,
            proposed_slots=[
                {"day": 5},
                {"time": "19:00"},
            ],
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/confirmation-cards/card-partial-slots",
        headers=_headers("partial-slots-teacher", "teacher"),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["suggestedDay"] == 5
    assert body["suggestedTime"] is None
    assert body["lessonDuration"] == 60
    assert body["suggestedDay2"] is None
    assert body["suggestedTime2"] == "19:00"
    assert body["suggestedDay3"] is None
    assert body["suggestedTime3"] is None


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


@pytest.mark.parametrize(
    ("actor_id", "role", "expected_status"),
    [
        ("access-owner-teacher", "teacher", 200),
        ("access-other-teacher", "teacher", 403),
        ("access-owner-student", "student", 200),
        ("access-other-student", "student", 403),
    ],
)
@pytest.mark.asyncio
async def test_confirmation_card_get_by_id_respects_teacher_and_student_access_filter(
    actor_id: str,
    role: str,
    expected_status: int,
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """GET by card id is visible only to the owning teacher or student."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="access-owner-teacher", role="teacher", email="access-owner-teacher@test.com")
    await create_test_user(user_id="access-other-teacher", role="teacher", email="access-other-teacher@test.com")
    await create_test_user(
        user_id="access-owner-student",
        role="student",
        name="Access Owner Student",
        email="access-owner-student@test.com",
    )
    await create_test_user(
        user_id="access-other-student",
        role="student",
        name="Access Other Student",
        email="access-other-student@test.com",
    )
    db_session.add(
        ScheduleConfirmationCard(
            id="access-filter-card",
            student_id="access-owner-student",
            teacher_id="access-owner-teacher",
            subscription_id="sub-access-filter",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/confirmation-cards/access-filter-card",
        headers=_headers(actor_id, role),
    )

    assert response.status_code == expected_status
    if expected_status == 200:
        assert response.json()["id"] == "access-filter-card"


@pytest.mark.asyncio
async def test_confirmation_card_lookup_by_subscription_rejects_other_teacher(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Lookup by subscription applies the same access filter as card id lookup."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(user_id="by-sub-owner-teacher", role="teacher", email="by-sub-owner-teacher@test.com")
    await create_test_user(user_id="by-sub-other-teacher", role="teacher", email="by-sub-other-teacher@test.com")
    db_session.add(
        ScheduleConfirmationCard(
            id="by-sub-access-card",
            student_id="by-sub-access-student",
            teacher_id="by-sub-owner-teacher",
            subscription_id="sub-by-sub-access",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/schedule/confirmation-cards/by-subscription/sub-by-sub-access",
        headers=_headers("by-sub-other-teacher", "teacher"),
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_confirmation_card_status_update_accepts_dismissed(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
    db_session,
):
    """Student clients can dismiss a pending confirmation card through /status."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    db_session.add(
        ScheduleConfirmationCard(
            id="status-dismissed-card",
            student_id="test-student-id",
            teacher_id="teacher-001",
            subscription_id="sub-status-dismissed-001",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.patch(
        "/api/v1/schedule/confirmation-cards/status-dismissed-card/status",
        headers=student_auth_headers,
        json={"status": "dismissed"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "dismissed"
    assert body["responded_at"] is not None


@pytest.mark.parametrize(
    ("card_id", "action"),
    [
        ("confirm-changed-time-card", "changedTime"),
        ("confirm-dismissed-card", "dismissed"),
    ],
)
@pytest.mark.asyncio
async def test_confirmation_card_confirm_accepts_changed_time_and_dismissed(
    card_id: str,
    action: str,
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
    db_session,
):
    """Student clients can change time or dismiss a pending card through /confirm."""
    from app.models.policy import ScheduleConfirmationCard

    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    db_session.add(
        ScheduleConfirmationCard(
            id=card_id,
            student_id="test-student-id",
            teacher_id="teacher-001",
            subscription_id=f"sub-{card_id}",
            card_type="afterTrial",
            title="Confirm schedule",
            status="pending",
            created_at=datetime.now(UTC),
        )
    )
    await db_session.flush()

    response = await client.patch(
        f"/api/v1/schedule/confirmation-cards/{card_id}/confirm",
        headers=student_auth_headers,
        json={"action": action},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == action
    assert body["responded_at"] is not None


@pytest.mark.asyncio
async def test_confirmation_card_rejects_updates_after_confirmed(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
    db_session,
):
    """Confirmed cards cannot be changed through /status or /confirm."""
    from app.models.policy import ConfirmationCardStatus, ScheduleConfirmationCard

    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    status_card = ScheduleConfirmationCard(
        id="status-confirmed-card",
        student_id="test-student-id",
        teacher_id="teacher-001",
        subscription_id="sub-status-confirmed-001",
        card_type="afterTrial",
        title="Confirmed schedule",
        status=ConfirmationCardStatus.confirmed,
        created_at=datetime.now(UTC),
    )
    confirm_card = ScheduleConfirmationCard(
        id="confirm-confirmed-card",
        student_id="test-student-id",
        teacher_id="teacher-001",
        subscription_id="sub-confirm-confirmed-001",
        card_type="afterTrial",
        title="Confirmed schedule",
        status=ConfirmationCardStatus.confirmed,
        created_at=datetime.now(UTC),
    )
    db_session.add_all([status_card, confirm_card])
    await db_session.flush()

    status_response = await client.patch(
        "/api/v1/schedule/confirmation-cards/status-confirmed-card/status",
        headers=student_auth_headers,
        json={"status": "dismissed"},
    )
    confirm_response = await client.patch(
        "/api/v1/schedule/confirmation-cards/confirm-confirmed-card/confirm",
        headers=student_auth_headers,
        json={"action": "dismissed"},
    )

    assert status_response.status_code == 400
    assert confirm_response.status_code == 400
    await db_session.refresh(status_card)
    await db_session.refresh(confirm_card)
    assert status_card.status == ConfirmationCardStatus.confirmed
    assert confirm_card.status == ConfirmationCardStatus.confirmed


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
