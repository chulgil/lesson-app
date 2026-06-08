"""Lesson request schedule negotiation chat-history scenarios."""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_teacher_student_schedule_negotiation_records_chat_history(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="teacher-chat", role="teacher", name="채팅 선생님")
    await create_test_user(
        user_id="student-chat",
        role="student",
        name="채팅 학생",
        email="student-chat@test.com",
    )

    teacher_headers = _headers("teacher-chat", "teacher")
    student_headers = _headers("student-chat", "student")

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=student_headers,
        json={
            "teacher_id": "teacher-chat",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "exam",
            "experience_level": "intermediate",
            "preferred_day": 0,
            "preferred_time": "16:00",
            "preferred_duration": 60,
            "message": "입시 준비로 정규 레슨 신청합니다",
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    round1 = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/propose-alternatives",
        headers=teacher_headers,
        json={
            "slots": [
                {"day_of_week": 1, "start_time": "17:00", "end_time": "18:00"},
                {"day_of_week": 3, "start_time": "16:00", "end_time": "17:00"},
            ],
            "message": "월요일 4시는 어렵고, 화/목 중 가능해요.",
        },
    )
    assert round1.status_code == 200

    counter = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/counter-propose",
        headers=student_headers,
        json={
            "slots": [{"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}],
            "message": "수요일 3시는 가능할까요?",
        },
    )
    assert counter.status_code == 200

    round2 = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/propose-alternatives",
        headers=teacher_headers,
        json={
            "slots": [
                {"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"},
                {"day_of_week": 2, "start_time": "16:00", "end_time": "17:00"},
            ],
            "message": "수요일 가능합니다. 3시나 4시 중 선택해주세요.",
        },
    )
    assert round2.status_code == 200

    confirmed = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/accept-alternative",
        headers=student_headers,
        json={"selected_slot_index": 0, "message": "수요일 3시로 할게요."},
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "timeConfirmed"
    assert confirmed.json()["preferred_day"] == 2
    assert confirmed.json()["preferred_time"] == "15:00"

    detail = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=student_headers,
    )
    assert detail.status_code == 200
    body = detail.json()
    assert body["events"] == [
        {
            **body["events"][0],
            "actor_type": "student",
            "actor_id": "student-chat",
            "event_type": "initialRequest",
            "message": "입시 준비로 정규 레슨 신청합니다",
        },
        {
            **body["events"][1],
            "actor_type": "teacher",
            "actor_id": "teacher-chat",
            "event_type": "proposeAlternative",
            "message": "월요일 4시는 어렵고, 화/목 중 가능해요.",
        },
        {
            **body["events"][2],
            "actor_type": "student",
            "actor_id": "student-chat",
            "event_type": "counterPropose",
            "message": "수요일 3시는 가능할까요?",
        },
        {
            **body["events"][3],
            "actor_type": "teacher",
            "actor_id": "teacher-chat",
            "event_type": "proposeAlternative",
            "message": "수요일 가능합니다. 3시나 4시 중 선택해주세요.",
        },
        {
            **body["events"][4],
            "actor_type": "student",
            "actor_id": "student-chat",
            "event_type": "acceptAlternative",
            "message": "수요일 3시로 할게요.",
        },
    ]
    assert body["events"][1]["suggested_slots"][0]["day_of_week"] == 1
    assert body["events"][4]["selected_slot_index"] == 0

    teacher_detail = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=teacher_headers,
    )
    assert teacher_detail.status_code == 200
    assert len(teacher_detail.json()["events"]) == 5


@pytest.mark.asyncio
async def test_lesson_request_chat_history_blocks_unrelated_users(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="owner-teacher", role="teacher", name="담당 선생님")
    await create_test_user(
        user_id="owner-student",
        role="student",
        name="담당 학생",
        email="owner-student@test.com",
    )
    await create_test_user(
        user_id="other-student",
        role="student",
        name="다른 학생",
        email="other-student@test.com",
    )
    await create_test_user(
        user_id="other-teacher",
        role="teacher",
        name="다른 선생님",
        email="other-teacher@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("owner-student", "student"),
        json={
            "teacher_id": "owner-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_day": 1,
            "preferred_time": "18:00",
            "preferred_duration": 60,
            "message": "레슨 요청합니다",
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    other_student_detail = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=_headers("other-student", "student"),
    )
    assert other_student_detail.status_code == 403

    other_teacher_action = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/propose-alternatives",
        headers=_headers("other-teacher", "teacher"),
        json={"slots": [{"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}]},
    )
    assert other_teacher_action.status_code == 403


@pytest.mark.asyncio
async def test_unified_lesson_request_actions_endpoint_records_events(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="action-teacher", role="teacher", name="액션 선생님")
    await create_test_user(
        user_id="action-student",
        role="student",
        name="액션 학생",
        email="action-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("action-student", "student"),
        json={
            "teacher_id": "action-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_day": 1,
            "preferred_time": "18:00",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    action_response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/actions",
        headers=_headers("action-teacher", "teacher"),
        json={
            "action": "proposeAlternative",
            "slots": [{"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}],
            "message": "수요일 3시가 가능합니다.",
        },
    )
    assert action_response.status_code == 200
    assert action_response.json()["status"] == "negotiating"

    detail = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=_headers("action-teacher", "teacher"),
    )
    assert detail.status_code == 200
    assert [event["event_type"] for event in detail.json()["events"]] == [
        "initialRequest",
        "proposeAlternative",
    ]


@pytest.mark.asyncio
async def test_lesson_request_events_endpoint_persists_remote_repository_events(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="event-teacher", role="teacher", name="이벤트 선생님")
    await create_test_user(
        user_id="event-student",
        role="student",
        name="이벤트 학생",
        email="event-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("event-student", "student"),
        json={
            "teacher_id": "event-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    post_response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("event-teacher", "teacher"),
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "event-teacher",
            "event_type": "subscriptionIssued",
            "message": "입금 확인 후 수강권을 발급했습니다.",
            "subscription_id": "subscription-001",
        },
    )
    assert post_response.status_code == 201
    assert post_response.json()["event_type"] == "subscriptionIssued"

    get_response = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("event-teacher", "teacher"),
    )
    assert get_response.status_code == 200
    assert [event["event_type"] for event in get_response.json()] == [
        "initialRequest",
        "subscriptionIssued",
    ]


@pytest.mark.asyncio
async def test_lesson_request_detail_events_expose_schedule_change_snapshot_aliases(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Nested detail events expose frontend snapshot aliases, not only DB names."""
    await create_test_user(user_id="snapshot-teacher", role="teacher", name="스냅샷 선생님")
    await create_test_user(
        user_id="snapshot-student",
        role="student",
        name="스냅샷 학생",
        email="snapshot-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("snapshot-student", "student"),
        json={
            "teacher_id": "snapshot-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    event_response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("snapshot-teacher", "teacher"),
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "snapshot-teacher",
            "event_type": "lessonCancelled",
            "subscription_id": "snapshot-sub-001",
            "session_number": 3,
            "changeCreditUsed": 1,
            "changeCreditRemainingAfter": 2,
            "keepsSessionNumber": True,
        },
    )
    assert event_response.status_code == 201
    assert event_response.json()["changeCreditUsed"] == 1

    detail_response = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=_headers("snapshot-teacher", "teacher"),
    )
    assert detail_response.status_code == 200
    event = detail_response.json()["events"][-1]
    assert event["event_type"] == "lessonCancelled"
    assert event["changeCreditUsed"] == 1
    assert event["changeCreditRemainingAfter"] == 2
    assert event["keepsSessionNumber"] is True


@pytest.mark.asyncio
async def test_schedule_change_accept_event_preserves_source_slots_for_history(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Accepted/withdrawn schedule-change events must replay the chosen slot label."""
    await create_test_user(user_id="change-teacher", role="teacher", name="변경 선생님")
    await create_test_user(
        user_id="change-student",
        role="student",
        name="변경 학생",
        email="change-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("change-student", "student"),
        json={
            "teacher_id": "change-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    proposal = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("change-teacher", "teacher"),
        json={
            "request_id": request_id,
            "actor_type": "teacher",
            "actor_id": "change-teacher",
            "event_type": "scheduleChangeProposed",
            "schedule_change_type": "singleLesson",
            "subscription_id": "sub-change-001",
            "session_number": 4,
            "suggested_slots": [
                {
                    "id": "slot-a",
                    "day_of_week": 1,
                    "start_time": "10:00",
                    "end_time": "11:00",
                },
                {
                    "id": "slot-b",
                    "day_of_week": 3,
                    "start_time": "14:00",
                    "end_time": "15:00",
                },
            ],
        },
    )
    assert proposal.status_code == 201

    accepted = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("change-student", "student"),
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "change-student",
            "event_type": "scheduleChangeAccepted",
            "subscription_id": "sub-change-001",
            "session_number": 4,
            "selected_slot_index": 1,
        },
    )
    assert accepted.status_code == 201
    body = accepted.json()
    assert body["event_type"] == "scheduleChangeAccepted"
    assert body["schedule_change_type"] == "singleLesson"
    assert body["suggested_slots"][1]["id"] == "slot-b"
    assert body["suggested_slots"][1]["day_of_week"] == 3
    assert body["selected_slot_index"] == 1

    withdrawn = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/events",
        headers=_headers("change-student", "student"),
        json={
            "request_id": request_id,
            "actor_type": "student",
            "actor_id": "change-student",
            "event_type": "withdrawApproval",
            "subscription_id": "sub-change-001",
            "session_number": 4,
        },
    )
    assert withdrawn.status_code == 201
    withdraw_body = withdrawn.json()
    assert withdraw_body["event_type"] == "withdrawApproval"
    assert withdraw_body["suggested_slots"][1]["id"] == "slot-b"
    assert withdraw_body["selected_slot_index"] == 1


@pytest.mark.asyncio
async def test_lesson_request_accepts_frontend_spec_keys_and_camel_case_actions(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="alias-teacher", role="teacher", name="별칭 선생님")
    await create_test_user(
        user_id="alias-student",
        role="student",
        name="별칭 학생",
        email="alias-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("alias-student", "student"),
        json={
            "teacherId": "alias-teacher",
            "type": "regular",
            "instrument": "piano",
            "goal": "exam",
            "experience": "intermediate",
            "preferredDay": 0,
            "preferredTime": "16:00",
            "preferredDuration": 60,
            "isReturningStudent": True,
            "message": "프론트 스펙 키로 요청합니다",
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["teacher_id"] == "alias-teacher"
    assert created["request_type"] == "regular"
    assert created["type"] == "regular"
    assert created["experience_level"] == "intermediate"
    assert created["experience"] == "intermediate"
    assert created["preferred_day"] == 0
    assert created["preferred_time"] == "16:00"
    assert created["is_returning_student"] is True

    request_id = created["id"]
    action_response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/actions",
        headers=_headers("alias-teacher", "teacher"),
        json={
            "action": "proposeAlternative",
            "suggestedSlots": [{"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}],
            "message": "camelCase 액션으로 제안합니다",
        },
    )
    assert action_response.status_code == 200
    assert action_response.json()["events"][-1]["event_type"] == "proposeAlternative"

    accept_response = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/actions",
        headers=_headers("alias-student", "student"),
        json={
            "action": "acceptAlternative",
            "selectedSlotIndex": 0,
            "message": "camelCase 인덱스로 수락합니다",
        },
    )
    assert accept_response.status_code == 200
    assert accept_response.json()["status"] == "timeConfirmed"
    assert accept_response.json()["events"][-1]["selected_slot_index"] == 0


@pytest.mark.asyncio
async def test_lesson_request_accepts_package_type_and_preferred_slots(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="package-teacher", role="teacher", name="회차권 선생님")
    await create_test_user(
        user_id="package-student",
        role="student",
        name="회차권 학생",
        email="package-student@test.com",
    )

    response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("package-student", "student"),
        json={
            "teacherId": "package-teacher",
            "type": "package",
            "instrument": "violin",
            "goal": "hobby",
            "experience": "beginner",
            "preferredSlots": [
                {
                    "priority": 1,
                    "dayOfWeek": 2,
                    "startTime": "15:00",
                    "endTime": "16:00",
                },
                {
                    "priority": 2,
                    "dayOfWeek": 4,
                    "startTime": "18:00",
                    "endTime": "19:00",
                },
            ],
            "preferredDuration": 60,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["request_type"] == "package"
    assert body["type"] == "package"
    assert body["preferred_day"] == 2
    assert body["preferred_time"] == "15:00"
    assert body["preferred_slots"] == [
        {
            "priority": 1,
            "date": None,
            "day_of_week": 2,
            "start_time": "15:00",
            "end_time": "16:00",
        },
        {
            "priority": 2,
            "date": None,
            "day_of_week": 4,
            "start_time": "18:00",
            "end_time": "19:00",
        },
    ]
    assert body["events"][0]["suggested_slots"][0]["day_of_week"] == 2


@pytest.mark.asyncio
async def test_lesson_request_status_endpoint_accepts_subscription_issued(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="issued-teacher", role="teacher", name="발급 선생님")
    await create_test_user(
        user_id="issued-student",
        role="student",
        name="발급 학생",
        email="issued-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("issued-student", "student"),
        json={
            "teacher_id": "issued-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    status_response = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("issued-teacher", "teacher"),
        json={
            "status": "subscriptionIssued",
            "proposal_id": "subscription-001",
        },
    )

    assert status_response.status_code == 200
    body = status_response.json()
    assert body["status"] == "subscriptionIssued"
    assert body["proposal_id"] == "subscription-001"
    assert body["events"][-1]["event_type"] == "subscriptionIssued"
    assert body["events"][-1]["subscription_id"] == "subscription-001"


@pytest.mark.asyncio
async def test_student_cannot_self_approve_lesson_request(
    client: AsyncClient,
    create_test_user,
) -> None:
    """Student must not be able to confirm their own request (GitHub #464)."""
    await create_test_user(user_id="approve-teacher", role="teacher", name="승인 선생님")
    await create_test_user(
        user_id="approve-student",
        role="student",
        name="승인 학생",
        email="approve-student@test.com",
    )

    create_response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=_headers("approve-student", "student"),
        json={
            "teacher_id": "approve-teacher",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
        },
    )
    assert create_response.status_code == 201
    request_id = create_response.json()["id"]

    # Student attempts self-approval (canonicalizes to timeConfirmed) → 403
    student_attempt = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("approve-student", "student"),
        json={"status": "approved"},
    )
    assert student_attempt.status_code == 403

    # Teacher approval succeeds
    teacher_attempt = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        headers=_headers("approve-teacher", "teacher"),
        json={"status": "approved"},
    )
    assert teacher_attempt.status_code == 200
    assert teacher_attempt.json()["status"] == "timeConfirmed"


@pytest.mark.asyncio
async def test_lesson_request_expire_endpoint_expires_pending_and_negotiating_requests(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
    monkeypatch,
) -> None:
    """`/expire` 는 cron 호출용 internal 라우트 — internal API key 로 게이팅된다.

    actor 검증 없이 전 pending/negotiating 요청을 일괄 expire 하므로 일반 사용자가
    호출 가능하면 데이터 손실 + 서비스 거부 가능.
    """
    from datetime import UTC, datetime, timedelta

    from app.core.config import settings
    from app.models.schedule import LessonRequest

    monkeypatch.setattr(settings, "INTERNAL_API_KEY", "test-internal-key")

    await create_test_user(user_id="expire-teacher", role="teacher", name="만료 선생님")
    await create_test_user(
        user_id="expire-student",
        role="student",
        name="만료 학생",
        email="expire-student@test.com",
    )
    headers = _headers("expire-student", "student")

    created_ids = []
    for status in ["pending", "negotiating"]:
        response = await client.post(
            "/api/v1/schedule/lesson-requests",
            headers=headers,
            json={
                "teacher_id": "expire-teacher",
                "request_type": "regular",
                "instrument": "piano",
                "goal": "hobby",
                "experience_level": "beginner",
                "preferred_duration": 60,
            },
        )
        assert response.status_code == 201
        request_id = response.json()["id"]
        request = await db_session.get(LessonRequest, request_id)
        assert request is not None
        request.status = status
        request.expires_at = datetime.now(UTC) - timedelta(days=1)
        created_ids.append(request_id)
    await db_session.flush()

    # 일반 사용자 (teacher) 호출은 401 — internal API key 가 없어서.
    teacher_attempt = await client.post(
        "/api/v1/schedule/lesson-requests/expire",
        headers=_headers("expire-teacher", "teacher"),
    )
    assert teacher_attempt.status_code == 401

    expire_response = await client.post(
        "/api/v1/schedule/lesson-requests/expire",
        headers={"X-Internal-API-Key": "test-internal-key"},
    )
    assert expire_response.status_code == 200
    assert expire_response.json()["message"] == "Processed 2 expired requests"

    for request_id in created_ids:
        detail = await client.get(
            f"/api/v1/schedule/lesson-requests/{request_id}",
            headers=headers,
        )
        assert detail.status_code == 200
        body = detail.json()
        assert body["status"] == "expired"
        assert body["events"][-1]["actor_type"] == "system"
        assert body["events"][-1]["event_type"] == "expire"


@pytest.mark.asyncio
async def test_lesson_request_calendar_counts_accessible_requests(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user(user_id="calendar-teacher", role="teacher", name="달력 선생님")
    await create_test_user(
        user_id="calendar-student",
        role="student",
        name="달력 학생",
        email="calendar-student@test.com",
    )

    student_headers = _headers("calendar-student", "student")
    teacher_headers = _headers("calendar-teacher", "teacher")

    for preferred_day, preferred_time in [(2, "15:00"), (2, "16:00"), (4, "18:00")]:
        response = await client.post(
            "/api/v1/schedule/lesson-requests",
            headers=student_headers,
            json={
                "teacher_id": "calendar-teacher",
                "request_type": "regular",
                "instrument": "piano",
                "goal": "hobby",
                "experience_level": "beginner",
                "preferred_day": preferred_day,
                "preferred_time": preferred_time,
                "preferred_duration": 60,
            },
        )
        assert response.status_code == 201

    calendar = await client.get(
        "/api/v1/schedule/lesson-requests/calendar",
        headers=teacher_headers,
    )
    assert calendar.status_code == 200
    assert calendar.json()["items"] == [
        {"day_of_week": 2, "count": 2},
        {"day_of_week": 4, "count": 1},
    ]
