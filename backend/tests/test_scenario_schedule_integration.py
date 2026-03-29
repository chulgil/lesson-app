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

from tests.scenarios.assertions import assert_status, assert_total
from tests.scenarios.helpers import StudentActions, TeacherActions


# ─────────────────────────────────────────────────────────────────────────
# 1. Trial lesson full lifecycle
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_trial_lesson_full_lifecycle(
    teacher: TeacherActions, student: StudentActions
):
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

    req_id = await student.send_connection_request(
        "test-user-id", method="inviteCode", invite_code=invite_code
    )

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
    assert_status(approved, "approved")

    # ── Phase 5: 학생 등록 + 체험레슨 생성 ───────────────────
    sid = await teacher.create_student(
        "체험학생", instrument="violin", level="beginner"
    )

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
    tmpl_id = await teacher.create_template(
        "바이올린 4회권", lessons_count=4, amount=200000
    )

    proposal_id = await teacher.send_proposal(
        sid, tmpl_id, lesson_request_id=request_id
    )

    # 레슨 요청 상태를 proposalSent로
    updated = await teacher.update_lesson_request_status(
        request_id, "proposalSent", proposal_id=proposal_id
    )
    assert_status(updated, "proposalSent")

    # 학생이 수강권 수락
    await student.accept_proposal(proposal_id, tmpl_id)

    # 선생님이 입금 확인
    await teacher.confirm_proposal(proposal_id)

    # 레슨 요청 완료
    completed_req = await teacher.update_lesson_request_status(
        request_id, "completed"
    )
    assert_status(completed_req, "completed")


# ─────────────────────────────────────────────────────────────────────────
# 2. Regular lesson with time negotiation
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_regular_lesson_time_negotiation(
    teacher: TeacherActions, student: StudentActions
):
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

    confirmed = await student.accept_alternative(
        request_id, 0, message="수요일 3시로 할게요!"
    )
    assert_status(confirmed, "timeConfirmed")
    assert confirmed["preferred_day"] == 2  # 수요일
    assert confirmed["preferred_time"] == "15:00"

    # ── Phase 5: 학생 등록 + 수강권 발급 ─────────────────────
    sid = await teacher.create_student(
        "입시생", instrument="piano", level="intermediate",
        monthly_fee=240000, lessons_per_week=1, lesson_duration=60,
    )

    tmpl_id = await teacher.create_template(
        "피아노 월정액", lessons_count=4, amount=240000
    )

    sub_id = await teacher.create_subscription(
        sid, total_lessons=4, amount=240000, type="monthly"
    )
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

    await teacher.complete_lesson(lesson_id)
    await teacher.use_lesson(sub_id, lesson_id)

    sub_after = await teacher.get_subscription(sub_id)
    assert sub_after["remaining_lessons"] == 3
    assert sub_after["used_lessons"] == 1

    # 레슨 요청 완료
    await teacher.update_lesson_request_status(request_id, "completed")


# ─────────────────────────────────────────────────────────────────────────
# 3. Rejection and re-request flow
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_rejection_and_rerequest(
    teacher: TeacherActions, student: StudentActions
):
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

    rejected = await teacher.reject_lesson_request(
        request_id1, reason="토요일은 레슨이 없습니다"
    )
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
    assert_status(approved, "approved")

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
async def test_student_requests_to_multiple_teachers(
    teacher: TeacherActions, student: StudentActions
):
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
async def test_withdraw_approval_and_redecide(
    teacher: TeacherActions, student: StudentActions
):
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
    assert_status(approved, "approved")
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
async def test_accept_preferred_slot_from_schedule(
    teacher: TeacherActions, student: StudentActions
):
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
    assert_status(approved, "approved")

    # ── Phase 3: 확인 ────────────────────────────────────────
    req = await student.get_lesson_request(request_id)
    assert_status(req, "approved")
    assert req["confirmed_at"] is not None


# ─────────────────────────────────────────────────────────────────────────
# 8. Full E2E: request → negotiate → confirm → subscription → lesson
# ─────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_full_e2e_request_to_lesson(
    teacher: TeacherActions, student: StudentActions
):
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
        request_id, 0, message="수요일 4시로 할게요!",
    )
    assert_status(confirmed, "timeConfirmed")

    # ── Phase 4: 학생 등록 + 수강권 ──────────────────────────
    sid = await teacher.create_student(
        "신규학생", instrument="violin", level="beginner",
        monthly_fee=200000, lessons_per_week=1,
    )

    tmpl_id = await teacher.create_template(
        "바이올린 4회", lessons_count=4, amount=200000,
    )

    sub_id = await teacher.create_subscription(
        sid, total_lessons=4, amount=200000,
    )

    # ── Phase 5: 수강권 제안 연결 ────────────────────────────
    proposal_id = await teacher.send_proposal(
        sid, tmpl_id, lesson_request_id=request_id,
    )
    await teacher.update_lesson_request_status(
        request_id, "proposalSent", proposal_id=proposal_id,
    )

    await student.accept_proposal(proposal_id, tmpl_id)
    await teacher.confirm_proposal(proposal_id)
    await teacher.update_lesson_request_status(request_id, "completed")

    # ── Phase 6: 첫 레슨 생성 + 차감 ────────────────────────
    lesson_id = await teacher.create_lesson(
        sid, date="2026-04-02", start_time="16:00",
        duration=60, instrument="violin",
    )
    await teacher.complete_lesson(lesson_id)
    await teacher.use_lesson(sub_id, lesson_id)

    sub = await teacher.get_subscription(sub_id)
    assert sub["remaining_lessons"] == 3
    assert sub["used_lessons"] == 1

    # ── Phase 7: 최종 확인 ────────────────────────────────────
    req = await student.get_lesson_request(request_id)
    assert_status(req, "completed")
