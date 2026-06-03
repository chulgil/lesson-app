"""End-to-end schedule integration scenarios.

Tests the full lifecycle from teacher/student signup through schedule
negotiation to subscription issuance.

Scenarios:
    1. Trial lesson: signup → connect → request → approve → lesson → subscription
    2. Regular lesson: signup → request → time negotiation (2 rounds) → confirm → subscription
    3. Rejection flow: request → teacher rejects → student re-requests
    4. Group class: teacher creates group → students book → attendance

Usage:
    uv run python -m pytest tests/test_scenario_schedule_integration.py -v
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from tests.scenarios.assertions import assert_status, assert_total
from tests.scenarios.helpers import StudentActions, TeacherActions, link_student_to_user


async def _dev_login_headers(
    client: AsyncClient,
    *,
    email: str,
    role: str,
    name: str,
) -> tuple[dict[str, str], dict]:
    response = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": email, "role": role, "name": name},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    return {"Authorization": f"Bearer {body['access_token']}"}, body["user"]


# ─────────────────────────────────────────────────────────────────────────
# 0. Signup → settings → schedule negotiation
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_signup_settings_connection_to_schedule_confirmation_card(
    client: AsyncClient,
    db_session,
):
    """
    Real user journey from API signup to schedule adjustment:
    선생님 가입/프로필/설정/가용시간 → 학생 가입/자기 프로필 →
    초대 연결 → 요청/협상/확정 → 수강권 제안/입금확인 →
    학생이 스케줄 확인 카드를 조회하고 확정한다.
    """
    teacher_headers, teacher_user = await _dev_login_headers(
        client,
        email="scenario-teacher@test.com",
        role="teacher",
        name="시나리오 선생님",
    )
    teacher_user_id = teacher_user["id"]
    assert teacher_user["role"] == "teacher"

    locale = await client.put(
        "/api/v1/users/me/locale",
        headers=teacher_headers,
        json={"locale": "ko", "country": "KR", "timezone": "Asia/Seoul", "currency": "KRW"},
    )
    assert locale.status_code == 200, locale.text

    teacher_profile = await client.put(
        "/api/v1/teachers/me/profile",
        headers=teacher_headers,
        json={
            "instruments": ["violin", "piano"],
            "introduction": "입문부터 입시까지 레슨합니다.",
            "experience_years": 8,
            "fee_min": 50000,
            "fee_max": 80000,
        },
    )
    assert teacher_profile.status_code == 200, teacher_profile.text
    teacher_profile_id = teacher_profile.json()["id"]

    settings = await client.put(
        "/api/v1/settings/teacher",
        headers=teacher_headers,
        json={
            "lesson_price_table": {
                "violin": {"beginner": 50000, "intermediate": 65000},
            },
            "auto_proposal_enabled": False,
        },
    )
    assert settings.status_code == 200, settings.text

    availability = await client.put(
        "/api/v1/schedule/availability",
        headers=teacher_headers,
        json={
            "weekly_schedules": [
                {
                    "day_of_week": 0,
                    "start_time": "15:00",
                    "end_time": "18:00",
                    "is_active": True,
                }
            ],
            "slot_duration_minutes": 60,
        },
    )
    assert availability.status_code == 200, availability.text

    student_headers, _ = await _dev_login_headers(
        client,
        email="scenario-student@test.com",
        role="student",
        name="시나리오 학생",
    )

    student_profile = await client.post(
        "/api/v1/students/me/profile",
        headers=student_headers,
        json={"name": "시나리오 학생", "instrument": "violin", "level": "beginner"},
    )
    assert student_profile.status_code == 201, student_profile.text

    public_availability = await client.get(
        f"/api/v1/schedule/availability/{teacher_user_id}",
        headers=student_headers,
    )
    assert public_availability.status_code == 200, public_availability.text
    assert public_availability.json()["weekly_schedules"][0]["start_time"] == "15:00"

    invite = await client.post(
        "/api/v1/invites/",
        headers=teacher_headers,
        json={"is_single_use": True},
    )
    assert invite.status_code == 201, invite.text

    connection_request = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_headers,
        json={
            "target_id": teacher_user_id,
            "method": "inviteCode",
            "invite_code": invite.json()["invite_code"],
        },
    )
    assert connection_request.status_code == 201, connection_request.text

    accepted_connection = await client.patch(
        f"/api/v1/invites/connection-requests/{connection_request.json()['id']}/respond",
        headers=teacher_headers,
        json={"action": "accept"},
    )
    assert accepted_connection.status_code == 200, accepted_connection.text

    linked_student = await client.get("/api/v1/students/me/profile", headers=student_headers)
    assert linked_student.status_code == 200, linked_student.text
    student_profile_id = linked_student.json()["id"]
    assert linked_student.json()["teacher_id"] == teacher_profile_id

    request = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers=student_headers,
        json={
            "teacher_id": teacher_user_id,
            "request_type": "regular",
            "instrument": "violin",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_day": 0,
            "preferred_time": "15:00",
            "preferred_duration": 60,
            "message": "월요일 3시에 정규 레슨을 받고 싶어요.",
        },
    )
    assert request.status_code == 201, request.text
    request_body = request.json()
    assert request_body["suggested_price"] == 50000

    proposal = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_body['id']}/propose-alternatives",
        headers=teacher_headers,
        json={
            "slots": [{"day_of_week": 0, "start_time": "16:00", "end_time": "17:00"}],
            "message": "같은 요일 4시는 어떨까요?",
        },
    )
    assert proposal.status_code == 200, proposal.text
    assert_status(proposal.json(), "negotiating")

    confirmed_time = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_body['id']}/accept-alternative",
        headers=student_headers,
        json={"selected_slot_index": 0, "message": "네, 4시로 할게요."},
    )
    assert confirmed_time.status_code == 200, confirmed_time.text
    assert_status(confirmed_time.json(), "timeConfirmed")

    template = await client.post(
        "/api/v1/subscriptions-templates",
        headers=teacher_headers,
        json={"name": "바이올린 4회권", "type": "package", "lessons_count": 4, "amount": 200000},
    )
    assert template.status_code == 201, template.text
    template_id = template.json()["id"]

    subscription_proposal = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=teacher_headers,
        json={
            "student_id": student_profile_id,
            "template_id": template_id,
            "template_ids": [template_id],
            "recommended_template_id": template_id,
            "lesson_request_id": request_body["id"],
            "message": "확정한 시간으로 4회권을 제안합니다.",
        },
    )
    assert subscription_proposal.status_code == 201, subscription_proposal.text
    subscription_proposal_id = subscription_proposal.json()["id"]

    accepted_proposal = await client.patch(
        f"/api/v1/subscriptions-proposals/{subscription_proposal_id}/respond",
        headers=student_headers,
        json={"action": "accept", "selected_template_id": template_id},
    )
    assert accepted_proposal.status_code == 200, accepted_proposal.text
    assert accepted_proposal.json()["status"] == "paymentNotified"

    # #10 A-C2 — confirm_proposal hits the phone-verification hard gate. The
    # dev-login flow does not auto-verify, so flip the teacher row before
    # exercising the issuance path.
    from sqlalchemy import select as _select

    from app.models.teacher import Teacher as _Teacher

    _teacher_row = await db_session.scalar(_select(_Teacher).where(_Teacher.user_id == teacher_user_id))
    if _teacher_row is not None and not _teacher_row.is_phone_verified:
        _teacher_row.is_phone_verified = True
        from datetime import UTC as _UTC
        from datetime import datetime as _datetime

        _teacher_row.phone_verified_at = _datetime.now(_UTC)
        await db_session.flush()

    confirmed_proposal = await client.patch(
        f"/api/v1/subscriptions-proposals/{subscription_proposal_id}/confirm",
        headers=teacher_headers,
        json={},
    )
    assert confirmed_proposal.status_code == 200, confirmed_proposal.text
    subscription_id = confirmed_proposal.json()["subscription_id"]
    assert subscription_id is not None

    confirmation_cards = await client.get(
        "/api/v1/schedule/confirmation-cards",
        headers=student_headers,
        params={"student_id": student_profile_id, "status": "pending"},
    )
    assert confirmation_cards.status_code == 200, confirmation_cards.text
    assert len(confirmation_cards.json()) == 1
    card = confirmation_cards.json()[0]
    assert card["subscription_id"] == subscription_id
    assert card["suggested_time"] == "16:00"

    confirmed_card = await client.patch(
        f"/api/v1/schedule/confirmation-cards/{card['id']}/confirm",
        headers=student_headers,
        json={"action": "confirmed", "response_message": "이 시간으로 진행할게요."},
    )
    assert confirmed_card.status_code == 200, confirmed_card.text
    assert confirmed_card.json()["status"] == "confirmed"

    schedule_change_request_id = f"{subscription_id}-session-1"
    student_change_request = await client.post(
        f"/api/v1/subscriptions/{subscription_id}/events",
        headers=student_headers,
        json={
            "request_id": schedule_change_request_id,
            "actor_type": "student",
            "actor_id": student_profile_id,
            "event_type": "scheduleChanged",
            "subscription_id": subscription_id,
            "session_number": 1,
            "schedule_change_type": "singleLesson",
            "suggested_slots": [
                {
                    "id": "student-alt-1",
                    "dayOfWeek": 2,
                    "startTime": "17:00",
                    "endTime": "18:00",
                }
            ],
            "message": "1회차만 수요일 5시로 조정하고 싶어요.",
        },
    )
    assert student_change_request.status_code == 201, student_change_request.text

    teacher_pending_changes = await client.get(
        "/api/v1/subscriptions/schedule-change-events/pending",
        headers=teacher_headers,
    )
    assert teacher_pending_changes.status_code == 200, teacher_pending_changes.text
    assert [event["id"] for event in teacher_pending_changes.json()] == [student_change_request.json()["id"]]

    teacher_accepts_change = await client.post(
        f"/api/v1/subscriptions/{subscription_id}/events",
        headers=teacher_headers,
        json={
            "request_id": schedule_change_request_id,
            "actor_type": "teacher",
            "actor_id": teacher_profile_id,
            "event_type": "scheduleChangeAccepted",
            "subscription_id": subscription_id,
            "session_number": 1,
            "selected_slot_index": 0,
        },
    )
    assert teacher_accepts_change.status_code == 201, teacher_accepts_change.text
    assert teacher_accepts_change.json()["suggested_slots"][0]["start_time"] == "17:00"

    reschedule_credit = await client.patch(
        f"/api/v1/subscriptions/{subscription_id}/use-reschedule",
        headers=teacher_headers,
    )
    assert reschedule_credit.status_code == 200, reschedule_credit.text
    assert reschedule_credit.json()["used_reschedule_count"] == 1
    assert reschedule_credit.json()["total_reschedule_allowance"] >= 1

    student_change_history = await client.get(
        f"/api/v1/subscriptions/{subscription_id}/events",
        headers=student_headers,
        params={"session_number": 1},
    )
    assert student_change_history.status_code == 200, student_change_history.text
    assert [event["event_type"] for event in student_change_history.json()] == [
        "scheduleChanged",
        "scheduleChangeAccepted",
    ]

    final_request = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_body['id']}",
        headers=student_headers,
    )
    assert final_request.status_code == 200, final_request.text
    assert_status(final_request.json(), "subscriptionIssued")

    event_history = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_body['id']}/events",
        headers=student_headers,
    )
    assert event_history.status_code == 200, event_history.text
    event_types = [event["event_type"] for event in event_history.json()]
    assert event_types == [
        "initialRequest",
        "proposeAlternative",
        "acceptAlternative",
        "proposalSent",
        "paymentNotified",
        "subscriptionIssued",
    ]

    me_after_setup = await client.get("/api/v1/users/me", headers=teacher_headers)
    assert me_after_setup.status_code == 200, me_after_setup.text
    assert me_after_setup.json()["role"] == "teacher"


# ─────────────────────────────────────────────────────────────────────────
# 1. Trial lesson full lifecycle
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_trial_lesson_full_lifecycle(teacher: TeacherActions, student: StudentActions, db_session):
    """
    Complete trial lesson flow:
    선생님 가입 → 학생 가입 → 초대/연결 → 체험레슨 요청 →
    선생님 승인 → 학생 등록 → 레슨 생성/완료 → 수강권 제안 → 정규 전환.
    """
    # ── Phase 1: 프로필 확인 ────────────────────────────────
    teacher_profile = await teacher.get_profile()
    assert teacher_profile["role"] == "teacher"

    student_profile = await student.get_profile()
    assert student_profile["role"] == "student"

    # ── Phase 2: 초대 → 연결 ────────────────────────────────
    invite = await teacher.create_invite(is_single_use=True)
    invite_code = invite["invite_code"]
    assert invite_code is not None

    req_id = await student.send_connection_request("test-user-id", method="inviteCode", invite_code=invite_code)

    pending = await teacher.list_pending_requests()
    assert_total(pending, 1)

    await teacher.accept_connection(req_id)
    conns = await teacher.list_connections()
    assert_total(conns, 1)

    # ── Phase 3: 체험레슨 요청 ────────────────────────────────
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=2,  # 수요일
        preferred_time="14:00",
        preferred_duration=30,
        message="바이올린 체험레슨 신청합니다",
    )

    req = await student.get_lesson_request(request_id)
    assert_status(req, "pending")
    assert req["request_type"] == "trial"
    assert req["preferred_duration"] == 30

    # ── Phase 4: 선생님 확인 및 승인 ────────────────────────────
    requests = await teacher.list_lesson_requests("test-user-id")
    assert_total(requests, 1)

    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "timeConfirmed")

    # ── Phase 5: 학생 등록 + 체험레슨 생성 ───────────────────
    sid = await teacher.create_student("체험학생", instrument="violin", level="beginner")
    # Student must OWN the profile to accept the proposal (#468 IDOR fix).
    await link_student_to_user(db_session, sid, "test-student-id")

    lesson_id = await teacher.create_lesson(
        sid,
        date="2026-04-02",
        start_time="14:00",
        duration=30,
        instrument="violin",
    )

    lesson = await teacher.get_lesson(lesson_id)
    assert_status(lesson, "scheduled")
    assert lesson["duration"] == 30

    # ── Phase 6: 레슨 완료 + 피드백 ──────────────────────────
    await teacher.complete_lesson(lesson_id)
    completed = await teacher.get_lesson(lesson_id)
    assert_status(completed, "completed")

    await teacher.write_feedback(
        lesson_id,
        feedback="음감이 좋아요! 정규 레슨 추천합니다",
        key_points=["음정", "리듬감"],
        practice_tips="매일 15분 기본 연습",
    )

    # ── Phase 7: 수강권 제안 → 정규 전환 ────────────────────
    tmpl_id = await teacher.create_template("바이올린 4회권", lessons_count=4, amount=200000)

    proposal_id = await teacher.send_proposal(sid, tmpl_id, lesson_request_id=request_id)

    # 레슨 요청 상태를 proposalSent로
    updated = await teacher.update_lesson_request_status(request_id, "proposalSent", proposal_id=proposal_id)
    assert_status(updated, "proposalSent")

    # 학생이 수강권 수락
    await student.accept_proposal(proposal_id, tmpl_id)

    # 선생님이 입금 확인
    await teacher.confirm_proposal(proposal_id)

    # 레슨 요청 완료
    completed_req = await teacher.update_lesson_request_status(request_id, "completed")
    assert_status(completed_req, "completed")


# ─────────────────────────────────────────────────────────────────────────
# 2. Regular lesson with time negotiation
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_regular_lesson_time_negotiation(teacher: TeacherActions, student: StudentActions):
    """
    Regular lesson with 2-round time negotiation:
    학생 요청 → 선생님 대안 제시 → 학생 역제안 →
    선생님 재대안 → 학생 수락 → 수강권 발급.
    """
    # ── Phase 1: 가격표 설정 ────────────────────────────────
    await teacher.update_settings(
        lesson_price_table={
            "piano": {
                "beginner": 50000,
                "intermediate": 60000,
                "advanced": 80000,
            },
        },
    )

    # ── Phase 2: 정규 레슨 요청 ────────────────────────────
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="piano",
        goal="exam",
        experience_level="intermediate",
        preferred_day=0,  # 월요일
        preferred_time="16:00",
        preferred_duration=60,
        message="입시 준비로 정규 레슨 신청합니다",
    )

    req = await student.get_lesson_request(request_id)
    assert_status(req, "pending")
    assert req["suggested_price"] == 60000  # auto-matched

    # ── Phase 3: Round 1 — 선생님 대안 → 학생 역제안 ────────
    alternatives = [
        {"day_of_week": 1, "start_time": "17:00", "end_time": "18:00"},
        {"day_of_week": 3, "start_time": "16:00", "end_time": "17:00"},
    ]
    round1 = await teacher.propose_alternatives(
        request_id, alternatives, message="월요일 4시는 어려워요. 다른 시간 확인해주세요"
    )
    assert_status(round1, "negotiating")
    assert round1["current_round"] == 1

    counter = await student.counter_propose(
        request_id,
        {"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"},
        message="수요일 3시는 가능할까요?",
    )
    assert_status(counter, "negotiating")

    # ── Phase 4: Round 2 — 선생님 재대안 → 학생 수락 ────────
    round2 = await teacher.propose_alternatives(
        request_id,
        [
            {"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"},
            {"day_of_week": 2, "start_time": "16:00", "end_time": "17:00"},
        ],
        message="수요일 가능합니다! 3시나 4시 중 선택해주세요",
    )
    assert round2["current_round"] == 2

    confirmed = await student.accept_alternative(request_id, 0, message="수요일 3시로 할게요!")
    assert_status(confirmed, "timeConfirmed")
    assert confirmed["preferred_day"] == 2  # 수요일
    assert confirmed["preferred_time"] == "15:00"

    # ── Phase 5: 학생 등록 + 수강권 발급 ─────────────────────
    sid = await teacher.create_student(
        "입시생",
        instrument="piano",
        level="intermediate",
        monthly_fee=240000,
        lessons_per_week=1,
        lesson_duration=60,
    )

    await teacher.create_template("피아노 월정액", lessons_count=4, amount=240000)

    sub_id = await teacher.create_subscription(sid, total_lessons=4, amount=240000, type="monthly")
    sub = await teacher.get_subscription(sub_id)
    assert sub["total_lessons"] == 4
    assert sub["remaining_lessons"] == 4

    # ── Phase 6: 첫 레슨 생성 + 수강권 차감 ──────────────────
    lesson_id = await teacher.create_lesson(
        sid,
        date="2026-04-02",
        start_time="15:00",
        duration=60,
        instrument="piano",
    )

    # 완료 시 자동 1회 차감 (2026-06-04 통합 규칙) — 별도 use_lesson 불필요
    await teacher.complete_lesson(lesson_id)

    sub_after = await teacher.get_subscription(sub_id)
    assert sub_after["remaining_lessons"] == 3
    assert sub_after["used_lessons"] == 1

    # 레슨 요청 완료
    await teacher.update_lesson_request_status(request_id, "completed")


# ─────────────────────────────────────────────────────────────────────────
# 3. Rejection and re-request flow
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_rejection_and_rerequest(teacher: TeacherActions, student: StudentActions):
    """
    Teacher rejects → student re-requests with different time:
    첫 요청 거절 → 재신청 → 승인.
    """
    # ── Phase 1: 첫 번째 요청 (거절됨) ──────────────────────
    request_id1 = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="cello",
        goal="hobby",
        experience_level="beginner",
        preferred_day=5,  # 토요일
        preferred_time="09:00",
        message="토요일 오전 가능할까요?",
    )

    rejected = await teacher.reject_lesson_request(request_id1, reason="토요일은 레슨이 없습니다")
    assert_status(rejected, "rejected")
    assert rejected["decline_reason"] == "토요일은 레슨이 없습니다"

    # ── Phase 2: 학생이 거절 확인 ────────────────────────────
    req = await student.get_lesson_request(request_id1)
    assert_status(req, "rejected")

    # ── Phase 3: 재신청 (다른 시간) ──────────────────────────
    request_id2 = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="cello",
        goal="hobby",
        experience_level="beginner",
        preferred_day=2,  # 수요일
        preferred_time="15:00",
        message="수요일은 가능할까요?",
    )

    req2 = await student.get_lesson_request(request_id2)
    assert_status(req2, "pending")
    assert req2["preferred_day"] == 2

    # ── Phase 4: 승인 ────────────────────────────────────────
    approved = await teacher.approve_lesson_request(request_id2)
    assert_status(approved, "timeConfirmed")

    # ── Phase 5: 선생님 요청 목록 확인 (2건) ──────────────────
    all_requests = await teacher.list_lesson_requests("test-user-id")
    assert_total(all_requests, 2)


# ─────────────────────────────────────────────────────────────────────────
# 4. Group class schedule + attendance
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_group_class_schedule_attendance(teacher: TeacherActions):
    """
    Group class scheduling with full attendance tracking:
    그룹 수업 생성 → 학생 3명 예약 → 출석/결석/지각 처리.
    """
    # ── Phase 1: 그룹 스케줄 생성 ────────────────────────────
    sched_id = await teacher.create_group_schedule(
        "gc-chamber",
        start_time="2026-04-05T10:00:00",
        end_time="2026-04-05T11:30:00",
        max_capacity=4,
        waitlist_capacity=2,
    )

    # ── Phase 2: 학생 3명 예약 ────────────────────────────────
    students = []
    for name in ["김현수", "이수진", "박영호"]:
        students.append(await teacher.create_student(name, instrument="violin"))

    bookings = []
    for sid in students:
        b = await teacher.book_group_student(sched_id, sid)
        assert_status(b, "confirmed")
        bookings.append(b)

    # ── Phase 3: 출석 처리 ────────────────────────────────────
    # 김현수: 출석
    att1 = await teacher.mark_group_attendance(bookings[0]["id"], attended=True)
    assert_status(att1, "attended")

    # 이수진: 출석
    att2 = await teacher.mark_group_attendance(bookings[1]["id"], attended=True)
    assert_status(att2, "attended")

    # 박영호: 결석
    att3 = await teacher.mark_group_attendance(bookings[2]["id"], attended=False)
    assert_status(att3, "noShow")


# ─────────────────────────────────────────────────────────────────────────
# 5. Multiple teachers, one student requesting
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_student_requests_to_multiple_teachers(teacher: TeacherActions, student: StudentActions):
    """
    Student sends requests to the same teacher with different instruments:
    한 학생이 같은 선생님에게 악기별 요청.
    """
    # ── Phase 1: 바이올린 요청 ────────────────────────────────
    req1 = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
    )

    # ── Phase 2: 피아노 요청 ─────────────────────────────────
    req2 = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="piano",
        goal="hobby",
        experience_level="beginner",
        preferred_day=3,
        preferred_time="16:00",
    )

    # ── Phase 3: 선생님이 두 건 확인 ─────────────────────────
    all_requests = await teacher.list_lesson_requests("test-user-id")
    assert_total(all_requests, 2)

    instruments = {r["instrument"] for r in all_requests["items"]}
    assert instruments == {"violin", "piano"}

    # ── Phase 4: 바이올린 승인, 피아노 시간 협상 ──────────────
    await teacher.approve_lesson_request(req1)

    alt = await teacher.propose_alternatives(
        req2,
        [{"day_of_week": 4, "start_time": "15:00", "end_time": "16:00"}],
        message="목요일 3시는 어떤가요?",
    )
    assert_status(alt, "negotiating")

    confirmed = await student.accept_alternative(req2, 0)
    assert_status(confirmed, "timeConfirmed")


# ─────────────────────────────────────────────────────────────────────────
# 6. Withdraw approval and re-decide
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_withdraw_approval_and_redecide(teacher: TeacherActions, student: StudentActions):
    """
    Teacher approves → withdraws → proposes alternative instead:
    승인 → 철회 → 대안 제안 → 학생 수락.
    """
    # ── Phase 1: 요청 + 승인 ────────────────────────────────
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
        preferred_duration=60,
        message="화요일 2시 가능할까요?",
    )

    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "timeConfirmed")
    assert approved["confirmed_at"] is not None

    # ── Phase 2: 승인 철회 ────────────────────────────────────
    withdrawn = await teacher.withdraw_approval(request_id)
    assert_status(withdrawn, "pending")
    assert withdrawn["confirmed_at"] is None

    # ── Phase 3: 대안 제안으로 변경 ──────────────────────────
    alt = await teacher.propose_alternatives(
        request_id,
        [
            {"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"},
            {"day_of_week": 4, "start_time": "14:00", "end_time": "15:00"},
        ],
        message="다시 생각해보니 수요일이나 금요일이 좋겠어요",
    )
    assert_status(alt, "negotiating")

    # ── Phase 4: 학생 수락 ────────────────────────────────────
    confirmed = await student.accept_alternative(request_id, 0)
    assert_status(confirmed, "timeConfirmed")
    assert confirmed["preferred_day"] == 2
    assert confirmed["preferred_time"] == "15:00"


# ─────────────────────────────────────────────────────────────────────────
# 7. Student accepts preferred slot directly from schedule comparison
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_accept_preferred_slot_from_schedule(teacher: TeacherActions, student: StudentActions):
    """
    Teacher views student's preferred slots on schedule grid,
    selects one directly → approved without negotiation:
    학생 선호 슬롯 확인 → 스케줄 비교 화면에서 바로 수락.
    """
    # ── Phase 1: 학생이 3개 선호 시간으로 요청 ────────────────
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="piano",
        goal="exam",
        experience_level="intermediate",
        preferred_day=2,  # 수요일
        preferred_time="15:00",
        preferred_duration=60,
        message="수요일 3시가 제일 좋아요",
    )

    req = await student.get_lesson_request(request_id)
    assert_status(req, "pending")

    # ── Phase 2: 선생님이 학생 선호 슬롯을 바로 승인 ──────────
    # (프론트엔드에서는 SuggestAlternativeScreen에서 선호 슬롯 탭 → 수락)
    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "timeConfirmed")

    # ── Phase 3: 확인 ────────────────────────────────────────
    req = await student.get_lesson_request(request_id)
    assert_status(req, "timeConfirmed")
    assert req["confirmed_at"] is not None


# ─────────────────────────────────────────────────────────────────────────
# 8. Full E2E: request → negotiate → confirm → subscription → lesson
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_full_e2e_request_to_lesson(teacher: TeacherActions, student: StudentActions, db_session):
    """
    Complete flow matching current frontend:
    요청 → 일정비교 → 대안제시 → 학생수락 → 학생등록 → 수강권 → 레슨 → 완료.
    """
    # ── Phase 1: 레슨 요청 ────────────────────────────────────
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
        preferred_duration=60,
        message="바이올린을 배우고 싶어요",
    )

    # ── Phase 2: 선생님이 일정비교 후 대안 제시 ──────────────
    alt = await teacher.propose_alternatives(
        request_id,
        [
            {"day_of_week": 2, "start_time": "16:00", "end_time": "17:00"},
            {"day_of_week": 4, "start_time": "15:00", "end_time": "16:00"},
        ],
        message="화요일은 꽉 차서 수요일이나 금요일 어때요?",
    )
    assert_status(alt, "negotiating")

    # ── Phase 3: 학생이 수요일 4시 수락 ──────────────────────
    confirmed = await student.accept_alternative(
        request_id,
        0,
        message="수요일 4시로 할게요!",
    )
    assert_status(confirmed, "timeConfirmed")

    # ── Phase 4: 학생 등록 + 수강권 ──────────────────────────
    sid = await teacher.create_student(
        "신규학생",
        instrument="violin",
        level="beginner",
        monthly_fee=200000,
        lessons_per_week=1,
    )
    # Student must OWN the profile to accept the proposal (#468 IDOR fix).
    await link_student_to_user(db_session, sid, "test-student-id")

    tmpl_id = await teacher.create_template(
        "바이올린 4회",
        lessons_count=4,
        amount=200000,
    )

    sub_id = await teacher.create_subscription(
        sid,
        total_lessons=4,
        amount=200000,
    )

    # ── Phase 5: 수강권 제안 연결 ────────────────────────────
    proposal_id = await teacher.send_proposal(
        sid,
        tmpl_id,
        lesson_request_id=request_id,
    )
    await teacher.update_lesson_request_status(
        request_id,
        "proposalSent",
        proposal_id=proposal_id,
    )

    await student.accept_proposal(proposal_id, tmpl_id)
    await teacher.confirm_proposal(proposal_id)
    await teacher.update_lesson_request_status(request_id, "completed")

    # ── Phase 6: 첫 레슨 생성 + 차감 ────────────────────────
    lesson_id = await teacher.create_lesson(
        sid,
        date="2026-04-02",
        start_time="16:00",
        duration=60,
        instrument="violin",
    )
    await teacher.complete_lesson(lesson_id)
    await teacher.use_lesson(sub_id, lesson_id)

    sub = await teacher.get_subscription(sub_id)
    assert sub["remaining_lessons"] == 3
    assert sub["used_lessons"] == 1

    # ── Phase 7: 최종 확인 ────────────────────────────────────
    req = await student.get_lesson_request(request_id)
    assert_status(req, "completed")


# ─────────────────────────────────────────────────────────────────────────
# 9. Teacher vacation setting blocks student-visible slots
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_teacher_vacation_setting_blocks_student_slot_search(teacher: TeacherActions, student: StudentActions):
    """
    Teacher sets weekly availability with vacation mode →
    student searches slots inside/outside vacation period.
    """
    availability = await teacher.client.post(
        "/api/v1/availability/",
        headers=teacher.headers,
        json={
            "day_of_week": 0,
            "time_slots": [
                {"start_time": "09:00", "end_time": "10:00", "is_available": True},
                {"start_time": "10:00", "end_time": "11:00", "is_available": True},
            ],
            "vacation_mode": True,
            "vacation_start_date": "2026-07-01",
            "vacation_end_date": "2026-08-31",
            "vacation_reason": "여름방학",
        },
    )
    assert availability.status_code == 201

    blocked = await student.client.get(
        "/api/v1/schedule/slots",
        headers=student.headers,
        params={"teacher_id": "test-user-id", "date": "2026-07-06"},
    )
    assert blocked.status_code == 200
    blocked_slots = blocked.json()["slots"]
    assert blocked_slots
    assert {slot["status"] for slot in blocked_slots} == {"unavailable"}

    outside = await student.client.get(
        "/api/v1/schedule/slots",
        headers=student.headers,
        params={"teacher_id": "test-user-id", "date": "2026-06-29"},
    )
    assert outside.status_code == 200
    outside_slots = outside.json()["slots"]
    assert outside_slots
    assert {slot["status"] for slot in outside_slots} == {"available"}


@pytest.mark.asyncio
async def test_teacher_vacation_disable_reopens_student_slot_search(teacher: TeacherActions, student: StudentActions):
    """
    Teacher disables vacation mode →
    student can book slots in the previously blocked period again.
    """
    availability = await teacher.client.post(
        "/api/v1/availability/",
        headers=teacher.headers,
        json={
            "day_of_week": 0,
            "time_slots": [
                {"start_time": "13:00", "end_time": "14:00", "is_available": True},
            ],
            "vacation_mode": True,
            "vacation_start_date": "2026-07-01",
            "vacation_end_date": "2026-08-31",
            "vacation_reason": "여름방학",
        },
    )
    assert availability.status_code == 201
    availability_id = availability.json()["id"]

    blocked = await student.client.get(
        "/api/v1/schedule/slots",
        headers=student.headers,
        params={"teacher_id": "test-user-id", "date": "2026-07-06"},
    )
    assert blocked.status_code == 200
    assert {slot["status"] for slot in blocked.json()["slots"]} == {"unavailable"}

    disabled = await teacher.client.put(
        f"/api/v1/availability/{availability_id}",
        headers=teacher.headers,
        json={"vacation_mode": False},
    )
    assert disabled.status_code == 200
    assert disabled.json()["vacation_mode"] is False

    reopened = await student.client.get(
        "/api/v1/schedule/slots",
        headers=student.headers,
        params={"teacher_id": "test-user-id", "date": "2026-07-06"},
    )
    assert reopened.status_code == 200
    reopened_slots = reopened.json()["slots"]
    assert reopened_slots
    assert {slot["status"] for slot in reopened_slots} == {"available"}


# ─────────────────────────────────────────────────────────────────────────
# 10. Subscription preserves travel context from class membership
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_subscription_creation_preserves_membership_location_and_travel_time(
    teacher: TeacherActions,
):
    """
    Teacher creates a location-aware membership →
    creates subscription → subscription keeps location/travel context.
    """
    student_id = await teacher.create_student("방문레슨학생", instrument="violin")

    class_response = await teacher.client.post(
        "/api/v1/lessons-classes",
        headers=teacher.headers,
        json={"name": "방문 레슨반", "type": "private"},
    )
    assert class_response.status_code == 201
    class_id = class_response.json()["id"]

    location_response = await teacher.client.post(
        "/api/v1/locations",
        headers=teacher.headers,
        json={
            "lesson_class_id": class_id,
            "name": "학생 자택",
            "type": "studentHome",
            "address": "서울시 강남구 테헤란로",
            "is_default": True,
        },
    )
    assert location_response.status_code == 201
    location_id = location_response.json()["id"]

    membership_response = await teacher.client.post(
        f"/api/v1/lessons-classes/{class_id}/memberships",
        headers=teacher.headers,
        json={
            "student_id": student_id,
            "instrument": "violin",
            "lesson_day": "monday",
            "lesson_time": "15:00",
            "lesson_duration": 60,
            "lesson_location_id": location_id,
            "travel_time_minutes": 25,
        },
    )
    assert membership_response.status_code == 201
    membership_id = membership_response.json()["id"]

    subscription_response = await teacher.client.post(
        "/api/v1/subscriptions",
        headers=teacher.headers,
        json={
            "student_id": student_id,
            "membership_id": membership_id,
            "type": "package",
            "total_lessons": 4,
            "amount": 200000,
            "payment_confirmed": False,
        },
    )
    assert subscription_response.status_code == 201
    created = subscription_response.json()
    assert created["membership_id"] == membership_id
    assert created["lesson_location_id"] == location_id
    assert created["travel_time_minutes"] == 25

    detail_response = await teacher.client.get(
        f"/api/v1/subscriptions/{created['id']}",
        headers=teacher.headers,
    )
    assert detail_response.status_code == 200
    detail = detail_response.json()
    assert detail["lesson_location_id"] == location_id
    assert detail["travel_time_minutes"] == 25

    list_response = await teacher.client.get(
        "/api/v1/subscriptions",
        headers=teacher.headers,
        params={"student_id": student_id},
    )
    assert list_response.status_code == 200
    listed = list_response.json()["items"][0]
    assert listed["lesson_location_id"] == location_id
    assert listed["travel_time_minutes"] == 25

    confirm_response = await teacher.client.patch(
        f"/api/v1/subscriptions/{created['id']}/confirm-payment",
        headers=teacher.headers,
        json={"payment_method": "bankTransfer"},
    )
    assert confirm_response.status_code == 200
    confirmed = confirm_response.json()
    assert confirmed["payment_confirmed"] is True
    assert confirmed["lesson_location_id"] == location_id
    assert confirmed["travel_time_minutes"] == 25

    lesson_id = await teacher.create_lesson(
        student_id,
        date="2026-05-04",
        start_time="15:00",
        duration=60,
        instrument="violin",
    )
    # 완료 시 자동 1회 차감 (2026-06-04 통합 규칙). 위치/이동시간은 그대로 유지.
    await teacher.complete_lesson(lesson_id)
    used = await teacher.get_subscription(created["id"])
    assert used["used_lessons"] == 1
    assert used["lesson_location_id"] == location_id
    assert used["travel_time_minutes"] == 25
