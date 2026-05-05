"""Subscription, template, and proposal endpoint tests."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


async def _create_membership(
    db_session: AsyncSession,
    *,
    teacher_id: str = "test-user-id",
    student_id: str = "student-001",
) -> str:
    from app.models.lesson import ClassMembership, LessonClass

    lesson_class = LessonClass(teacher_id=teacher_id, name="구독 테스트 클래스", type="private")
    db_session.add(lesson_class)
    await db_session.flush()

    membership = ClassMembership(
        lesson_class_id=lesson_class.id,
        student_id=student_id,
        instrument="piano",
        status="active",
    )
    db_session.add(membership)
    await db_session.flush()
    return membership.id


@pytest.mark.asyncio
async def test_create_subscription(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions creates a subscription (teacher only) and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 8,
            "amount": 200000,
            "start_date": "2026-03-01",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "student-001"
    assert data["total_lessons"] == 8
    assert data["remaining_lessons"] == 8
    assert "id" in data


@pytest.mark.asyncio
async def test_create_subscription_preserves_pending_deposit_status(
    client: AsyncClient, auth_headers, create_test_user
):
    """Immediate issue can create a subscription waiting for deposit confirmation."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "monthly",
            "total_lessons": 8,
            "amount": 200000,
            "payment_confirmed": False,
            "payment_method": "bankTransfer",
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["payment_confirmed"] is False
    assert data["payment_method"] == "bankTransfer"
    assert data["payment_status"] == "pending"


@pytest.mark.asyncio
async def test_list_subscriptions(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/subscriptions returns a paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Create a subscription first
    await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 4,
            "amount": 100000,
        },
    )

    response = await client.get("/api/v1/subscriptions", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_use_lesson_deduction(client: AsyncClient, auth_headers, create_test_user):
    """PATCH /api/v1/subscriptions/{id}/use-lesson deducts a lesson."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    sub_id = create_resp.json()["id"]

    response = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/use-lesson",
        headers=auth_headers,
        json={"lesson_id": "lesson-001", "type": "lesson"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["used_lessons"] == 1
    assert data["remaining_lessons"] == 7


@pytest.mark.asyncio
async def test_subscription_events_preserve_schedule_change_snapshot(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Subscription events keep schedule-change credit/session snapshots."""
    await create_test_user(user_id="test-user-id", role="teacher")
    membership_id = await _create_membership(db_session)

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    sub_id = create_resp.json()["id"]

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": f"req-{sub_id}",
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "scheduleChanged",
            "subscription_id": sub_id,
            "session_number": 3,
            "schedule_change_type": "singleLesson",
            "changeCreditUsed": 1,
            "changeCreditRemainingAfter": 2,
            "keepsSessionNumber": True,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["changeCreditUsed"] == 1
    assert body["changeCreditRemainingAfter"] == 2
    assert body["keepsSessionNumber"] is True

    list_response = await client.get(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        params={"session_number": 3},
    )
    assert list_response.status_code == 200
    assert list_response.json()[0]["changeCreditUsed"] == 1
    assert list_response.json()[0]["changeCreditRemainingAfter"] == 2
    assert list_response.json()[0]["keepsSessionNumber"] is True


@pytest.mark.asyncio
async def test_subscription_schedule_change_accept_preserves_source_slots(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Accepted subscription schedule changes can render the original proposal."""
    await create_test_user(user_id="test-user-id", role="teacher")
    membership_id = await _create_membership(db_session)

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    sub_id = create_resp.json()["id"]
    request_id = f"req-{sub_id}"

    proposed = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "scheduleChangeProposed",
            "subscription_id": sub_id,
            "session_number": 2,
            "schedule_change_type": "singleLesson",
            "suggested_slots": [
                {
                    "id": "slot-a",
                    "dayOfWeek": 2,
                    "startTime": "15:00",
                    "endTime": "16:00",
                }
            ],
        },
    )
    assert proposed.status_code == 201

    accepted = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "student-001",
            "event_type": "scheduleChangeAccepted",
            "subscription_id": sub_id,
            "session_number": 2,
            "selected_slot_index": 0,
        },
    )

    assert accepted.status_code == 201
    body = accepted.json()
    assert body["schedule_change_type"] == "singleLesson"
    assert body["suggested_slots"][0]["id"] == "slot-a"
    assert body["suggested_slots"][0]["day_of_week"] == 2
    assert body["suggested_slots"][0]["start_time"] == "15:00"
    assert body["suggested_slots"][0]["end_time"] == "16:00"

    withdrawn = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "student-001",
            "event_type": "withdrawApproval",
            "subscription_id": sub_id,
            "session_number": 2,
        },
    )

    assert withdrawn.status_code == 201
    withdraw_body = withdrawn.json()
    assert withdraw_body["suggested_slots"][0]["id"] == "slot-a"
    assert withdraw_body["selected_slot_index"] == 0


@pytest.mark.asyncio
async def test_subscription_schedule_change_events_enforce_turn_order(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Schedule-change accepts/rejects require a pending event from the other side."""
    await create_test_user(user_id="test-user-id", role="teacher")
    membership_id = await _create_membership(db_session)

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert create_resp.status_code == 201
    sub_id = create_resp.json()["id"]
    request_id = f"req-{sub_id}"

    no_pending = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "student-001",
            "event_type": "scheduleChangeAccepted",
            "subscription_id": sub_id,
            "session_number": 3,
            "selected_slot_index": 0,
        },
    )
    assert no_pending.status_code == 400

    proposed = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "scheduleChangeProposed",
            "subscription_id": sub_id,
            "session_number": 3,
            "suggested_slots": [{"id": "slot-a", "dayOfWeek": 2, "startTime": "15:00", "endTime": "16:00"}],
        },
    )
    assert proposed.status_code == 201

    self_accept = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "scheduleChangeAccepted",
            "subscription_id": sub_id,
            "session_number": 3,
            "selected_slot_index": 0,
        },
    )
    assert self_accept.status_code == 400

    accepted = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "student-001",
            "event_type": "scheduleChangeAccepted",
            "subscription_id": sub_id,
            "session_number": 3,
            "selected_slot_index": 0,
        },
    )
    assert accepted.status_code == 201

    duplicate = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "student-001",
            "event_type": "scheduleChangeRejected",
            "subscription_id": sub_id,
            "session_number": 3,
        },
    )
    assert duplicate.status_code == 400


@pytest.mark.asyncio
async def test_parent_cannot_create_subscription_schedule_change_event(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Parents can read child subscription events but cannot create them."""
    from app.models.parent import Parent, ParentChildRelation

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent-event@test.com",
    )
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="student-001"),
        ]
    )
    await db_session.flush()
    membership_id = await _create_membership(db_session)

    create_resp = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert create_resp.status_code == 201
    sub_id = create_resp.json()["id"]
    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }

    response = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=parent_headers,
        json={
            "request_id": sub_id,
            "actor_type": "parent",
            "actor_id": "parent-profile-id",
            "event_type": "scheduleChangeProposed",
            "subscription_id": sub_id,
            "session_number": 1,
        },
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_subscription_template(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions-templates creates a template and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "name": "Basic Monthly",
            "type": "monthly",
            "lessons_count": 4,
            "amount": 100000,
            "description": "4 lessons per month",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Basic Monthly"
    assert data["lessons_count"] == 4
    assert data["teacher_id"] == "test-user-id-prof"


@pytest.mark.asyncio
async def test_subscription_template_frontend_contract_aliases_and_actions(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend template repository sends/receives owner/price/total aliases and uses detail actions."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "owner_id": "test-user-id-prof",
            "owner_type": "teacher",
            "name": "8회권",
            "total_lessons": 8,
            "lesson_duration_minutes": 50,
            "validity_days": 90,
            "price": 400000,
            "display_order": 2,
            "reschedule_allowance": 1,
            "is_auto_proposal_enabled": True,
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["owner_id"] == "test-user-id-prof"
    assert created["owner_type"] == "teacher"
    assert created["total_lessons"] == 8
    assert created["price"] == 400000

    template_id = created["id"]
    detail_response = await client.get(
        f"/api/v1/subscriptions-templates/{template_id}",
        headers=auth_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == template_id

    toggle_response = await client.patch(
        f"/api/v1/subscriptions-templates/{template_id}/toggle-active",
        headers=auth_headers,
    )
    assert toggle_response.status_code == 200
    assert toggle_response.json()["is_active"] is False

    reorder_response = await client.patch(
        "/api/v1/subscriptions-templates/reorder",
        headers=auth_headers,
        json={"ordered_ids": [template_id]},
    )
    assert reorder_response.status_code == 204


@pytest.mark.asyncio
async def test_subscription_template_actions_reject_other_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Template detail and mutations are scoped to the owning teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="Other Teacher",
        email="other-template@test.com",
    )

    create_response = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={"name": "Owner Only", "type": "package", "lessons_count": 4, "amount": 100000},
    )
    assert create_response.status_code == 201
    template_id = create_response.json()["id"]
    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher', 'role': 'teacher'})}"
    }

    assert (
        await client.get(f"/api/v1/subscriptions-templates/{template_id}", headers=other_headers)
    ).status_code == 403
    assert (
        await client.put(
            f"/api/v1/subscriptions-templates/{template_id}",
            headers=other_headers,
            json={"name": "Hijacked"},
        )
    ).status_code == 403
    assert (
        await client.patch(
            f"/api/v1/subscriptions-templates/{template_id}/toggle-active",
            headers=other_headers,
        )
    ).status_code == 403
    assert (
        await client.delete(f"/api/v1/subscriptions-templates/{template_id}", headers=other_headers)
    ).status_code == 403
    assert (
        await client.patch(
            "/api/v1/subscriptions-templates/reorder",
            headers=other_headers,
            json={"ordered_ids": [template_id]},
        )
    ).status_code == 403


@pytest.mark.asyncio
async def test_create_subscription_proposal(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/subscriptions-proposals creates a proposal and returns 201."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "message": "Please review this subscription plan",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["student_id"] == "student-001"
    assert data["status"] == "pending"
    assert data["teacher_id"] == "test-user-id-prof"


@pytest.mark.asyncio
async def test_subscription_proposals_are_scoped_to_current_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Teachers only list and read proposals they own."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="Other Teacher",
        email="other-proposal@test.com",
    )
    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher', 'role': 'teacher'})}"
    }

    owned = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "student-owned", "message": "owned"},
    )
    assert owned.status_code == 201
    foreign = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=other_headers,
        json={"student_id": "student-foreign", "message": "foreign"},
    )
    assert foreign.status_code == 201

    listed = await client.get("/api/v1/subscriptions-proposals", headers=auth_headers)
    assert listed.status_code == 200
    ids = {item["id"] for item in listed.json()["items"]}
    assert owned.json()["id"] in ids
    assert foreign.json()["id"] not in ids

    forbidden = await client.get(
        f"/api/v1/subscriptions-proposals/{foreign.json()['id']}",
        headers=auth_headers,
    )
    assert forbidden.status_code == 403


@pytest.mark.asyncio
async def test_subscription_proposal_notify_payment_action_marks_deposit_notified(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Student can notify manual deposit without using the legacy accept action."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )

    create_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "test-student-id",
            "message": "입금 안내를 확인해주세요.",
        },
    )
    proposal_id = create_response.json()["id"]

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "notify_payment"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "paymentNotified"
    assert data["payment_notified_at"] is not None


@pytest.mark.asyncio
async def test_subscription_proposal_actions_require_owned_teacher_or_linked_student(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Only the proposal teacher or linked student can mutate proposal state."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="Other Teacher",
        email="other-confirm@test.com",
    )
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Linked Student",
        email="linked-student@test.com",
    )
    await create_test_user(
        user_id="other-student",
        role="student",
        name="Other Student",
        email="other-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "입금 안내"},
    )
    assert create_response.status_code == 201
    proposal_id = create_response.json()["id"]
    other_student_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-student', 'role': 'student'})}"
    }
    other_teacher_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher', 'role': 'teacher'})}"
    }

    other_student_response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=other_student_headers,
        json={"action": "notify_payment"},
    )
    assert other_student_response.status_code == 403

    linked_student_response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "notify_payment"},
    )
    assert linked_student_response.status_code == 200

    other_teacher_response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=other_teacher_headers,
        json={},
    )
    assert other_teacher_response.status_code == 403


@pytest.mark.asyncio
async def test_subscription_proposal_frontend_contract_detail_and_expire(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend proposal repository can fetch one proposal and trigger expiry processing."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "template_ids": ["template-a", "template-b"],
            "recommended_template_id": "template-a",
            "message": "수강권을 선택해주세요.",
        },
    )
    assert create_response.status_code == 201
    proposal_id = create_response.json()["id"]

    detail_response = await client.get(
        f"/api/v1/subscriptions-proposals/{proposal_id}",
        headers=auth_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == proposal_id

    expire_response = await client.post(
        "/api/v1/subscriptions-proposals/expire",
        headers=auth_headers,
    )
    assert expire_response.status_code == 200
    assert "message" in expire_response.json()


@pytest.mark.asyncio
async def test_subscription_proposal_frontend_contract_action_aliases(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
):
    """Frontend proposal repository sends template_id/reason aliases and cancel action."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student-proposal-alias@test.com",
    )

    select_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": "test-student-id",
            "template_ids": ["template-a", "template-b"],
            "recommended_template_id": "template-a",
            "message": "수강권을 선택해주세요.",
        },
    )
    select_proposal_id = select_response.json()["id"]
    selected = await client.patch(
        f"/api/v1/subscriptions-proposals/{select_proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "select_template", "template_id": "template-b"},
    )
    assert selected.status_code == 200
    assert selected.json()["status"] == "paymentNotified"
    assert selected.json()["selected_template_id"] == "template-b"

    reject_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "거절 테스트"},
    )
    reject_proposal_id = reject_response.json()["id"]
    rejected = await client.patch(
        f"/api/v1/subscriptions-proposals/{reject_proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "reject", "reason": "다음 달에 할게요"},
    )
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "rejected"
    assert rejected.json()["rejection_reason"] == "다음 달에 할게요"

    cancel_response = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={"student_id": "test-student-id", "message": "취소 테스트"},
    )
    cancel_proposal_id = cancel_response.json()["id"]
    cancelled = await client.patch(
        f"/api/v1/subscriptions-proposals/{cancel_proposal_id}/respond",
        headers=auth_headers,
        json={"action": "cancel"},
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"


@pytest.mark.asyncio
async def test_subscription_usage_frontend_contract_paginated_and_usage_type(
    client: AsyncClient, auth_headers, create_test_user
):
    """Frontend usage repository expects {items: [...]} and usage_type/created_at fields."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    subscription_id = create_response.json()["id"]

    usage_response = await client.post(
        f"/api/v1/subscriptions/{subscription_id}/usage",
        headers=auth_headers,
        json={
            "lesson_id": "lesson-001",
            "usage_type": "lateCancellation",
            "teacher_name": "김선생",
            "instrument": "violin",
            "note": "당일 취소",
            "deducted": True,
        },
    )
    assert usage_response.status_code == 201
    usage = usage_response.json()
    assert usage["usage_type"] == "lateCancellation"
    assert usage["created_at"] is not None
    assert usage["teacher_name"] == "김선생"
    assert usage["instrument"] == "violin"
    assert usage["note"] == "당일 취소"

    history_response = await client.get(
        f"/api/v1/subscriptions/{subscription_id}/usage",
        headers=auth_headers,
    )
    assert history_response.status_code == 200
    history = history_response.json()
    assert "items" in history
    assert history["items"][0]["usage_type"] == "lateCancellation"
    assert history["items"][0]["teacher_name"] == "김선생"


@pytest.mark.asyncio
async def test_subscription_detail_and_mutations_reject_other_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A teacher cannot read or mutate another teacher's subscription by ID."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="Other Teacher",
        email="other-teacher@test.com",
    )
    membership_id = await _create_membership(db_session, teacher_id="test-user-id")

    created = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "type": "package",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert created.status_code == 201
    sub_id = created.json()["id"]
    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher', 'role': 'teacher'})}"
    }

    assert (await client.get(f"/api/v1/subscriptions/{sub_id}", headers=other_headers)).status_code == 403
    assert (
        await client.put(
            f"/api/v1/subscriptions/{sub_id}",
            headers=other_headers,
            json={"amount": 1},
        )
    ).status_code == 403
    assert (
        await client.patch(
            f"/api/v1/subscriptions/{sub_id}/confirm-payment",
            headers=other_headers,
            json={"payment_method": "cash"},
        )
    ).status_code == 403
    assert (
        await client.post(f"/api/v1/subscriptions/{sub_id}/renew", headers=other_headers)
    ).status_code == 403


@pytest.mark.asyncio
async def test_linked_student_user_can_read_profile_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Student users access subscriptions by their linked Student profile id."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Linked Student",
        email="student-profile@test.com",
    )
    student = Student(
        id="student-profile-id",
        user_id="student-user-id",
        teacher_id="test-user-id-prof",
        name="Linked Student",
        instrument="piano",
    )
    db_session.add(student)
    await db_session.flush()
    membership_id = await _create_membership(
        db_session,
        teacher_id="test-user-id",
        student_id="student-profile-id",
    )
    created = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-profile-id",
            "membership_id": membership_id,
            "type": "package",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert created.status_code == 201
    sub_id = created.json()["id"]
    student_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'student-user-id', 'role': 'student'})}"
    }

    listed = await client.get(
        "/api/v1/subscriptions",
        headers=student_headers,
        params={"student_id": "student-profile-id"},
    )
    assert listed.status_code == 200
    assert listed.json()["total"] == 1
    assert listed.json()["items"][0]["id"] == sub_id

    detail = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=student_headers)
    assert detail.status_code == 200
    assert detail.json()["id"] == sub_id


@pytest.mark.asyncio
async def test_parent_can_read_linked_child_subscription_history_and_events(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A linked parent can read child subscriptions and related read-only history."""
    from app.models.parent import Parent, ParentChildRelation

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent-subscription@test.com",
    )
    parent = Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent")
    relation = ParentChildRelation(parent_id="parent-profile-id", student_id="student-001")
    db_session.add_all([parent, relation])
    await db_session.flush()
    membership_id = await _create_membership(
        db_session,
        teacher_id="test-user-id",
        student_id="student-001",
    )

    created = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "type": "package",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert created.status_code == 201
    sub_id = created.json()["id"]

    usage = await client.post(
        f"/api/v1/subscriptions/{sub_id}/usage",
        headers=auth_headers,
        json={"lesson_id": "lesson-001", "type": "lesson"},
    )
    assert usage.status_code == 201
    event = await client.post(
        f"/api/v1/subscriptions/{sub_id}/events",
        headers=auth_headers,
        json={
            "request_id": sub_id,
            "actor_type": "teacher",
            "actor_id": "test-user-id",
            "event_type": "scheduleChangeProposed",
            "subscription_id": sub_id,
            "session_number": 1,
            "suggested_slots": [{"id": "slot-a", "dayOfWeek": 2, "startTime": "15:00", "endTime": "16:00"}],
        },
    )
    assert event.status_code == 201
    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }

    listed = await client.get(
        "/api/v1/subscriptions",
        headers=parent_headers,
        params={"student_id": "student-001"},
    )
    assert listed.status_code == 200
    assert listed.json()["total"] == 1
    assert listed.json()["items"][0]["id"] == sub_id

    detail = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=parent_headers)
    assert detail.status_code == 200
    assert detail.json()["id"] == sub_id

    usage_history = await client.get(f"/api/v1/subscriptions/{sub_id}/usage", headers=parent_headers)
    assert usage_history.status_code == 200
    assert usage_history.json()["items"][0]["lesson_id"] == "lesson-001"

    events = await client.get(f"/api/v1/subscriptions/{sub_id}/events", headers=parent_headers)
    assert events.status_code == 200
    assert events.json()[0]["event_type"] == "scheduleChangeProposed"


@pytest.mark.asyncio
async def test_parent_cannot_read_unlinked_child_subscription(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A parent cannot read subscriptions for a child without an active relation."""
    from app.models.parent import Parent

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent-unlinked-subscription@test.com",
    )
    db_session.add(Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"))
    await db_session.flush()
    membership_id = await _create_membership(
        db_session,
        teacher_id="test-user-id",
        student_id="student-001",
    )
    created = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "membership_id": membership_id,
            "type": "package",
            "total_lessons": 8,
            "amount": 200000,
        },
    )
    assert created.status_code == 201
    sub_id = created.json()["id"]
    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }

    listed = await client.get(
        "/api/v1/subscriptions",
        headers=parent_headers,
        params={"student_id": "student-001"},
    )
    assert listed.status_code == 200
    assert listed.json()["total"] == 0
    assert (await client.get(f"/api/v1/subscriptions/{sub_id}", headers=parent_headers)).status_code == 403


@pytest.mark.asyncio
async def test_subscription_remaining_lessons_matches_frontend_hybrid_calculation(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """remaining_lessons follows Flutter's package/monthly/trial + bonus rules."""
    await create_test_user(user_id="test-user-id", role="teacher")

    package_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-package",
            "type": "package",
            "total_lessons": 8,
            "used_lessons": 3,
            "bonus_count": 2,
            "amount": 200000,
        },
    )
    assert package_response.status_code == 201
    assert package_response.json()["remaining_lessons"] == 7

    monthly_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-monthly",
            "type": "monthly",
            "lessons_per_month": 4,
            "used_lessons": 1,
            "bonus_count": 1,
            "amount": 200000,
        },
    )
    assert monthly_response.status_code == 201
    assert monthly_response.json()["remaining_lessons"] == 4

    trial_response = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-trial",
            "type": "trial",
            "used_lessons": 0,
            "amount": 0,
        },
    )
    assert trial_response.status_code == 201
    assert trial_response.json()["remaining_lessons"] == 1


@pytest.mark.asyncio
async def test_use_reschedule_increments_counter_and_rejects_exhausted_credit(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """use-reschedule consumes the same counter the frontend renders."""
    await create_test_user(user_id="test-user-id", role="teacher")

    created = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": "student-001",
            "type": "package",
            "total_lessons": 8,
            "amount": 200000,
            "total_reschedule_allowance": 1,
            "used_reschedule_count": 0,
        },
    )
    assert created.status_code == 201
    sub_id = created.json()["id"]

    first = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/use-reschedule",
        headers=auth_headers,
    )
    assert first.status_code == 200
    assert first.json()["used_reschedule_count"] == 1

    second = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/use-reschedule",
        headers=auth_headers,
    )
    assert second.status_code == 400
