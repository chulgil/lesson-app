"""Scenario tests using the scenario framework (helpers + fixtures).

Demonstrates how to write concise, readable E2E tests with TeacherActions/StudentActions.
Each test is a complete user journey written in ~10-20 lines instead of ~50-80.
"""

import pytest

from tests.scenarios.assertions import (
    assert_status,
    assert_subscription_remaining,
    assert_total,
)
from tests.scenarios.helpers import StudentActions, TeacherActions

# ===========================================================================
# Scenario A: 신규 선생님 온보딩 (프레임워크 버전)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_teacher_onboarding(teacher: TeacherActions):
    """Teacher onboards → creates student → first lesson → feedback."""
    # Verify profile
    profile = await teacher.get_profile()
    assert profile["role"] == "teacher"

    # Defaults loaded
    settings = await teacher.get_settings()
    assert settings["default_lesson_duration"] == 60

    # Register student
    sid = await teacher.create_student("김민준", instrument="violin")

    # Create & complete lesson
    lid = await teacher.create_lesson(sid, date="2026-03-20", instrument="violin")
    lesson = await teacher.get_lesson(lid)
    assert_status(lesson, "scheduled")

    await teacher.complete_lesson(lid)
    await teacher.write_feedback(lid, feedback="활 잡기가 좋아졌어요!")


# ===========================================================================
# Scenario B: 수강권 전체 생명주기 (발급 → 사용 → 만료 임박)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_subscription_lifecycle(teacher: TeacherActions):
    """Template → subscription → deduct 6/8 → verify remaining → payment."""
    tmpl_id = await teacher.create_template("바이올린 8회", lessons_count=8, amount=320000)
    sid = await teacher.create_student("이서연")
    sub_id = await teacher.create_subscription(sid, total_lessons=8, amount=320000)

    # Deduct 6 lessons
    for i in range(6):
        lid = await teacher.create_lesson(sid, date=f"2026-03-{10 + i:02d}")
        await teacher.complete_lesson(lid)
        await teacher.use_lesson(sub_id, lid)

    # Verify remaining
    sub = await teacher.get_subscription(sub_id)
    assert_subscription_remaining(sub, 2)

    # Confirm payment
    await teacher.confirm_payment(sub_id)


# ===========================================================================
# Scenario C: 초대 → 연결 → 체험 → 승인 (선생님 + 학생 협업)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_invite_connect_book(teacher: TeacherActions, student: StudentActions):
    """Teacher invites → student connects → books trial → teacher approves."""
    invite = await teacher.create_invite(is_single_use=True)
    code = invite["invite_code"]

    req_id = await student.send_connection_request("test-user-id", method="inviteCode", invite_code=code)

    pending = await teacher.list_pending_requests()
    assert_total(pending, 1)

    await teacher.accept_connection(req_id)
    conns = await teacher.list_connections()
    assert_total(conns, 1)

    booking_id = await student.book_trial("test-user-id", instrument="violin")
    result = await teacher.approve_booking(booking_id)
    assert_status(result, "confirmed")


# ===========================================================================
# Scenario D: 그룹 수업 (생성 → 만석 → 대기열 → 승격 → 출석)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_group_class_lifecycle(teacher: TeacherActions):
    """Create schedule → fill → waitlist → cancel → auto-promote → attend."""
    sched_id = await teacher.create_group_schedule(
        "gc-ensemble",
        start_time="2026-04-05T14:00:00",
        end_time="2026-04-05T15:30:00",
        max_capacity=2,
        waitlist_capacity=1,
    )

    b1 = await teacher.book_group_student(sched_id, "s-a")
    b2 = await teacher.book_group_student(sched_id, "s-b")
    b3 = await teacher.book_group_student(sched_id, "s-c")

    assert_status(b1, "confirmed")
    assert_status(b2, "confirmed")
    assert_status(b3, "waitlist")

    # Cancel b1 → s-c promoted
    await teacher.cancel_group_booking(b1["id"])

    # Attend remaining
    await teacher.mark_group_attendance(b2["id"])
    r = await teacher.mark_group_attendance(b3["id"])
    assert_status(r, "attended")


# ===========================================================================
# Scenario E: 연습 관리 → 통계 → 게이미피케이션
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_practice_gamification(teacher: TeacherActions):
    """Practice logs → monthly stats → award points → check level."""
    sid = await teacher.create_student("정하율", instrument="piano")
    await teacher.create_repertoire(sid, "소나타 K.545")

    # 3 days of practice
    for day in range(1, 4):
        await teacher.create_practice_log(sid, f"2026-03-{day:02d}", 30 + day * 5)

    stats = await teacher.get_practice_stats(sid, 2026, 3)
    assert stats["practiced_days"] == 3
    assert stats["total_minutes"] == 120  # 35 + 40 + 45

    # Award points
    await teacher.award_points(sid, 150, "streakBonus", "3일 연속 연습!")
    gam = await teacher.get_gamification(sid)
    assert gam["total_points"] == 150
    assert gam["level"] == 2  # passes 100 threshold


# ===========================================================================
# Scenario F: 수강권 제안 플로우 (제안 → 수락 → 확인)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_proposal_flow(teacher: TeacherActions, student: StudentActions):
    """Teacher proposes → student accepts → teacher confirms."""
    tmpl_id = await teacher.create_template("기본 4회", lessons_count=4, amount=160000)
    sid = await teacher.create_student("제안학생", instrument="piano")

    proposal_id = await teacher.send_proposal(sid, tmpl_id, message="추천합니다!")
    await student.accept_proposal(proposal_id, tmpl_id)
    result = await teacher.confirm_proposal(proposal_id)
    assert_status(result, "confirmed")


# ===========================================================================
# Scenario G: 노쇼 → 기록 → 보강
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_no_show_management(teacher: TeacherActions):
    """Student no-shows → record → verify in no-show list."""
    sid = await teacher.create_student("결석생", instrument="flute")
    lid = await teacher.create_lesson(sid, date="2026-03-15", start_time="11:00")

    await teacher.mark_no_show(lid)
    record = await teacher.record_no_show(lid, sid, "2026-03-15")
    assert record["deducted_credits"] == 1


# ===========================================================================
# Scenario H: 선생님 콘텐츠 관리 (프리셋 + 교육자료 + 리뷰)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_content_management(teacher: TeacherActions, student: StudentActions):
    """Teacher creates content, student writes review, teacher checks."""
    await teacher.create_feedback_preset("음정 정확!")
    await teacher.create_feedback_preset("활 압력 조절 필요")
    await teacher.create_teaching_resource(
        "정명훈 마스터클래스",
        youtube_video_id="dQw4w9WgXcQ",
        instrument="cello",
    )

    # Student writes review
    await student.write_review("test-user-id", 5, "최고입니다!")
    await student.write_review("test-user-id", 4, "좋아요")

    summary = await teacher.get_review_summary("test-user-id")
    assert summary["total_reviews"] == 2
    assert summary["average_rating"] == 4.5


# ===========================================================================
# Scenario I: 설정 전체 구성 (선생님 + 수강권 + 제안)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_full_settings(teacher: TeacherActions):
    """Configure all settings and verify persistence."""
    await teacher.update_settings(
        instruments=["violin", "viola"],
        default_lesson_duration=50,
        break_time_between_lessons=15,
    )

    # Read back
    s = await teacher.get_settings()
    assert s["instruments"] == ["violin", "viola"]
    assert s["default_lesson_duration"] == 50
    assert s["break_time_between_lessons"] == 15


# ===========================================================================
# Scenario J: 하루 멀티 학생 레슨
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_multi_student_day(teacher: TeacherActions):
    """3 students, 3 lessons on same day: 2 complete + 1 cancel."""
    students = []
    for name in ["김가영", "박민수", "이지은"]:
        students.append(await teacher.create_student(name))

    lessons = []
    for sid, time in zip(students, ["10:00", "11:30", "14:00"]):
        lessons.append(await teacher.create_lesson(sid, date="2026-03-20", start_time=time))

    # Complete first two
    await teacher.complete_lesson(lessons[0])
    await teacher.complete_lesson(lessons[1])
    await teacher.write_feedback(lessons[0], feedback="잘 했어요!")
    await teacher.write_feedback(lessons[1], feedback="많이 좋아졌어요!")

    # Cancel third
    await teacher.cancel_lesson(lessons[2])


# ===========================================================================
# Scenario K: 수강권 만료 후 재등록
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_subscription_renewal_after_expiry(teacher: TeacherActions, student: StudentActions):
    """수강권 4회 모두 사용 → 만료 확인 → 선생님 재제안 → 학생 수락 → 새 수강권."""
    # Step 1: 학생 + 첫 수강권 발급 (4회)
    sid = await teacher.create_student("재등록학생", instrument="violin")
    sub_id = await teacher.create_subscription(sid, total_lessons=4, amount=160000)

    sub = await teacher.get_subscription(sub_id)
    assert_subscription_remaining(sub, 4)

    # Step 2: 4회 레슨 모두 완료 + 차감
    for i in range(4):
        lid = await teacher.create_lesson(sid, date=f"2026-04-{i + 1:02d}", start_time="15:00")
        await teacher.complete_lesson(lid)
        await teacher.use_lesson(sub_id, lid)

    # Step 3: 잔여 0 확인 (만료 상태)
    sub = await teacher.get_subscription(sub_id)
    assert_subscription_remaining(sub, 0)
    assert sub["used_lessons"] == 4

    # Step 4: 선생님이 재등록 제안 (새 템플릿)
    tmpl_id = await teacher.create_template("재등록 8회", lessons_count=8, amount=300000)
    proposal_id = await teacher.send_proposal(sid, tmpl_id, message="수강권이 만료되었습니다. 재등록을 추천합니다!")

    # Step 5: 학생이 수락
    result = await student.accept_proposal(proposal_id, tmpl_id)
    assert_status(result, "paymentNotified")

    # Step 6: 선생님이 결제 확인
    confirmed = await teacher.confirm_proposal(proposal_id)
    assert_status(confirmed, "confirmed")

    # Step 7: 새 수강권 발급 + 사용 시작
    new_sub_id = await teacher.create_subscription(sid, total_lessons=8, amount=300000)
    new_sub = await teacher.get_subscription(new_sub_id)
    assert_subscription_remaining(new_sub, 8)

    # Step 8: 새 수강권에서 첫 레슨 차감
    lid = await teacher.create_lesson(sid, date="2026-04-10", start_time="15:00")
    await teacher.complete_lesson(lid)
    await teacher.use_lesson(new_sub_id, lid)

    new_sub = await teacher.get_subscription(new_sub_id)
    assert_subscription_remaining(new_sub, 7)


# ===========================================================================
# Scenario K: 통합 레슨 신청 — 승인 플로우
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_unified_lesson_request_approve(teacher: TeacherActions, student: StudentActions):
    """Student submits unified lesson request → Teacher approves."""
    # Step 1: 학생이 통합 레슨 신청 (체험, 바이올린, 초급)
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,  # 화요일
        preferred_time="14:00",
        preferred_duration=60,
        message="바이올린을 배우고 싶습니다",
    )

    # Step 2: 신청 데이터 확인
    req = await student.get_lesson_request(request_id)
    assert_status(req, "pending")
    assert req["request_type"] == "trial"
    assert req["instrument"] == "violin"
    assert req["goal"] == "hobby"
    assert req["experience_level"] == "beginner"
    assert req["preferred_day"] == 1
    assert req["preferred_time"] == "14:00"
    assert req["message"] == "바이올린을 배우고 싶습니다"

    # Step 3: 선생님이 요청 목록에서 확인
    requests = await teacher.list_lesson_requests("test-user-id")
    assert_total(requests, 1)

    # Step 4: 선생님이 승인
    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "approved")

    # Step 5: 학생이 상태 확인
    req = await student.get_lesson_request(request_id)
    assert_status(req, "approved")


# ===========================================================================
# Scenario L: 통합 레슨 신청 — 거절 플로우
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_unified_lesson_request_reject(teacher: TeacherActions, student: StudentActions):
    """Student submits unified lesson request → Teacher rejects with reason."""
    # Step 1: 학생이 정규 레슨 신청
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="piano",
        goal="exam",
        experience_level="intermediate",
        preferred_day=3,  # 목요일
        preferred_time="16:00",
        message="입시 준비 중입니다",
    )

    # Step 2: 선생님이 거절 (사유 포함)
    rejected = await teacher.reject_lesson_request(request_id, reason="스케줄이 꽉 차서 다음에 신청해주세요")
    assert_status(rejected, "rejected")
    assert rejected["decline_reason"] == "스케줄이 꽉 차서 다음에 신청해주세요"

    # Step 3: 학생이 거절 상태 확인
    req = await student.get_lesson_request(request_id)
    assert_status(req, "rejected")
    assert req["decline_reason"] == "스케줄이 꽉 차서 다음에 신청해주세요"


# ===========================================================================
# Scenario M: 통합 레슨 신청 — 복귀 학생 프리필
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_unified_lesson_request_returning_student(teacher: TeacherActions, student: StudentActions):
    """Returning student sends request with previous lesson info prefilled."""
    # Step 1: 복귀 학생이 이전 정보 포함하여 신청
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="violin",
        goal="hobby",
        experience_level="intermediate",
        preferred_day=2,  # 수요일
        preferred_time="15:00",
        preferred_duration=60,
        is_returning_student=True,
        message="다시 시작하고 싶습니다",
    )

    # Step 2: 복귀 학생 정보 확인
    req = await student.get_lesson_request(request_id)
    assert req["is_returning_student"] is True
    assert req["request_type"] == "regular"

    # Step 3: 선생님이 승인
    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "approved")


# ===========================================================================
# Scenario N: 시간 협상 — 대안 제안 → 학생 수락 → 시간 확정
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_negotiation_accept_alternative(teacher: TeacherActions, student: StudentActions):
    """Teacher proposes 3 alternatives → Student accepts one → timeConfirmed."""
    # Step 1: 학생이 레슨 신청
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
        message="화요일 2시 가능할까요?",
    )

    # Step 2: 선생님이 대안 3개 제안
    alternatives = [
        {"day_of_week": 1, "start_time": "15:00", "end_time": "16:00"},
        {"day_of_week": 3, "start_time": "14:00", "end_time": "15:00"},
        {"day_of_week": 5, "start_time": "10:00", "end_time": "11:00"},
    ]
    result = await teacher.propose_alternatives(request_id, alternatives, message="화요일 2시는 다른 레슨이 있어요")
    assert_status(result, "negotiating")
    assert result["current_round"] == 1
    assert len(result["time_proposals"]) == 1

    # Step 3: 학생이 두 번째 대안(목요일 2시) 수락
    confirmed = await student.accept_alternative(request_id, 1, message="목요일 2시로 할게요!")
    assert_status(confirmed, "timeConfirmed")
    assert confirmed["preferred_day"] == 3  # Thursday
    assert confirmed["preferred_time"] == "14:00"
    assert len(confirmed["time_proposals"]) == 2


# ===========================================================================
# Scenario O: 시간 협상 — 학생 역제안 → 선생님 승인
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_negotiation_counter_propose_then_approve(teacher: TeacherActions, student: StudentActions):
    """Teacher proposes alternatives → Student counter-proposes → Teacher approves."""
    # Step 1: 학생이 레슨 신청
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="piano",
        goal="exam",
        experience_level="intermediate",
        preferred_day=0,
        preferred_time="10:00",
    )

    # Step 2: 선생님이 대안 제안
    alternatives = [
        {"day_of_week": 2, "start_time": "14:00", "end_time": "15:00"},
    ]
    result = await teacher.propose_alternatives(request_id, alternatives, message="월요일은 어려워요")
    assert_status(result, "negotiating")

    # Step 3: 학생이 역제안
    counter_slot = {"day_of_week": 4, "start_time": "16:00", "end_time": "17:00"}
    countered = await student.counter_propose(request_id, counter_slot, message="금요일 4시는 어떨까요?")
    assert_status(countered, "negotiating")
    assert len(countered["time_proposals"]) == 2

    # Step 4: 선생님이 승인 (기존 status update 엔드포인트)
    approved = await teacher.approve_lesson_request(request_id)
    assert_status(approved, "approved")


# ===========================================================================
# Scenario P: 시간 협상 — 2라운드 (대안 → 역제안 → 재대안 → 수락)
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_negotiation_two_rounds(teacher: TeacherActions, student: StudentActions):
    """Round 1: propose → counter. Round 2: propose → accept."""
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=0,
        preferred_time="09:00",
    )

    # Round 1: 선생님 대안 → 학생 역제안
    await teacher.propose_alternatives(
        request_id,
        [{"day_of_week": 1, "start_time": "10:00", "end_time": "11:00"}],
    )
    await student.counter_propose(
        request_id,
        {"day_of_week": 2, "start_time": "11:00", "end_time": "12:00"},
    )

    req = await student.get_lesson_request(request_id)
    assert req["current_round"] == 1  # round 1 done

    # Round 2: 선생님 재대안 → 학생 수락
    result = await teacher.propose_alternatives(
        request_id,
        [
            {"day_of_week": 2, "start_time": "14:00", "end_time": "15:00"},
            {"day_of_week": 3, "start_time": "14:00", "end_time": "15:00"},
        ],
    )
    assert result["current_round"] == 2

    confirmed = await student.accept_alternative(request_id, 0)
    assert_status(confirmed, "timeConfirmed")
    assert confirmed["preferred_day"] == 2
    assert confirmed["preferred_time"] == "14:00"


# ===========================================================================
# Scenario Q: 시간 협상 — 3라운드 미합의 → 만료
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_negotiation_expire_after_three_rounds(teacher: TeacherActions, student: StudentActions):
    """3 rounds of negotiation without agreement → request expires."""
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="cello",
        goal="major",
        experience_level="advanced",
        preferred_day=0,
        preferred_time="09:00",
    )

    # Round 1
    await teacher.propose_alternatives(
        request_id,
        [{"day_of_week": 1, "start_time": "10:00", "end_time": "11:00"}],
    )
    await student.counter_propose(
        request_id,
        {"day_of_week": 2, "start_time": "11:00", "end_time": "12:00"},
    )

    # Round 2
    await teacher.propose_alternatives(
        request_id,
        [{"day_of_week": 3, "start_time": "14:00", "end_time": "15:00"}],
    )
    await student.counter_propose(
        request_id,
        {"day_of_week": 4, "start_time": "16:00", "end_time": "17:00"},
    )

    # Round 3
    await teacher.propose_alternatives(
        request_id,
        [{"day_of_week": 5, "start_time": "10:00", "end_time": "11:00"}],
    )

    # Student tries counter-propose at round 3 → should expire
    result = await student.counter_propose(
        request_id,
        {"day_of_week": 0, "start_time": "09:00", "end_time": "10:00"},
    )
    assert_status(result, "expired")


# ===========================================================================
# Scenario R: 시간 협상 — 만료 후 추가 제안 불가
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_negotiation_no_propose_after_expire(teacher: TeacherActions, student: StudentActions):
    """After expiration, teacher cannot propose alternatives."""
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=0,
        preferred_time="09:00",
    )

    # Exhaust all 3 rounds
    for i in range(3):
        await teacher.propose_alternatives(
            request_id,
            [{"day_of_week": i + 1, "start_time": "10:00", "end_time": "11:00"}],
        )
        if i < 2:
            await student.counter_propose(
                request_id,
                {"day_of_week": i + 2, "start_time": "11:00", "end_time": "12:00"},
            )

    # Last counter triggers expire
    result = await student.counter_propose(
        request_id,
        {"day_of_week": 5, "start_time": "09:00", "end_time": "10:00"},
    )
    assert_status(result, "expired")

    # Teacher tries to propose after expiration → should fail (400)
    r = await teacher.client.post(
        f"{teacher._base}/schedule/lesson-requests/{request_id}/propose-alternatives",
        headers=teacher.headers,
        json={"slots": [{"day_of_week": 0, "start_time": "10:00", "end_time": "11:00"}]},
    )
    assert r.status_code == 400


# ===========================================================================
# Scenario S: 가격표 설정 + 자동 매칭
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_price_table_auto_match(teacher: TeacherActions, student: StudentActions):
    """Teacher sets price table → Student request auto-matches suggested price."""
    # Step 1: 선생님이 가격표 설정
    await teacher.update_settings(
        lesson_price_table={
            "violin": {"beginner": 40000, "intermediate": 50000, "advanced": 70000},
            "piano": {"beginner": 45000, "intermediate": 55000, "advanced": 75000},
        },
    )

    # Step 2: 가격표 영속성 확인
    settings = await teacher.get_settings()
    assert settings["lesson_price_table"]["violin"]["beginner"] == 40000
    assert settings["lesson_price_table"]["piano"]["advanced"] == 75000

    # Step 3: 학생이 바이올린 초급으로 신청 → 가격 자동 매칭
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
    )
    req = await student.get_lesson_request(request_id)
    assert req["suggested_price"] == 40000

    # Step 4: 가격표에 없는 악기 → suggested_price=null
    request_id2 = await student.create_lesson_request(
        "test-user-id",
        request_type="trial",
        instrument="cello",
        goal="hobby",
        experience_level="beginner",
        preferred_day=2,
        preferred_time="15:00",
    )
    req2 = await student.get_lesson_request(request_id2)
    assert req2["suggested_price"] is None


# ===========================================================================
# Scenario T: 체험 무료 설정
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_trial_lesson_free_setting(teacher: TeacherActions):
    """Teacher toggles trial lesson free setting."""
    # Step 1: 기본값 확인 (유료)
    settings = await teacher.get_settings()
    assert settings["trial_lesson_free"] is False

    # Step 2: 무료로 변경
    await teacher.update_settings(trial_lesson_free=True)
    settings = await teacher.get_settings()
    assert settings["trial_lesson_free"] is True

    # Step 3: 다시 유료로 변경
    await teacher.update_settings(trial_lesson_free=False)
    settings = await teacher.get_settings()
    assert settings["trial_lesson_free"] is False


# ===========================================================================
# Scenario U: 시간 확정 후 수강권 제안 연동
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_time_confirmed_to_subscription_proposal(teacher: TeacherActions, student: StudentActions):
    """Time confirmed → Teacher sends subscription proposal → Student accepts."""
    # Step 1: 학생 등록 + 수강권 템플릿 생성
    sid = await teacher.create_student("협상학생", instrument="violin")
    tmpl_id = await teacher.create_template("4회권", lessons_count=4, amount=200000)

    # Step 2: 학생이 정규 레슨 신청
    request_id = await student.create_lesson_request(
        "test-user-id",
        request_type="regular",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=1,
        preferred_time="14:00",
    )

    # Step 3: 시간 협상 → 확정
    await teacher.propose_alternatives(
        request_id,
        [{"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}],
    )
    confirmed = await student.accept_alternative(request_id, 0)
    assert_status(confirmed, "timeConfirmed")

    # Step 4: 선생님이 수강권 제안 발송 (lesson_request_id 연결)
    proposal_id = await teacher.send_proposal(sid, tmpl_id, lesson_request_id=request_id)

    # Step 5: 레슨 요청 상태를 proposalSent로 업데이트
    updated = await teacher.update_lesson_request_status(request_id, "proposalSent", proposal_id=proposal_id)
    assert_status(updated, "proposalSent")

    # Step 6: 학생이 수강권 수락
    await student.accept_proposal(proposal_id, tmpl_id)

    # Step 7: 선생님이 입금 확인 → 수강권 발급
    await teacher.confirm_proposal(proposal_id)

    # Step 8: 레슨 요청 완료 처리
    completed = await teacher.update_lesson_request_status(request_id, "completed")
    assert_status(completed, "completed")


# ===========================================================================
# Scenario V: 복수 입금 계좌 관리
# ===========================================================================


@pytest.mark.asyncio
async def test_fw_multiple_bank_accounts(teacher: TeacherActions):
    """Teacher registers multiple bank accounts, sets default, deletes one."""
    my_profile = await teacher.get_my_teacher_profile()
    teacher_id = my_profile["id"]

    # Step 1: 계좌 2개 등록
    accounts = [
        {
            "id": "ba_1",
            "bank_name": "국민은행",
            "account_number": "123-456-789",
            "account_holder": "김선생",
            "is_default": True,
            "created_at": "2026-03-27T00:00:00Z",
        },
        {
            "id": "ba_2",
            "bank_name": "신한은행",
            "account_number": "987-654-321",
            "account_holder": "김선생",
            "is_default": False,
            "created_at": "2026-03-27T00:00:00Z",
        },
    ]
    result = await teacher.update_teacher_profile(teacher_id, bank_accounts=accounts)
    assert len(result["bank_accounts"]) == 2

    # Step 2: 영속성 확인
    profile = await teacher.get_my_teacher_profile()
    assert len(profile["bank_accounts"]) == 2
    assert profile["bank_accounts"][0]["bank_name"] == "국민은행"
    assert profile["bank_accounts"][0]["is_default"] is True
    assert profile["bank_accounts"][1]["bank_name"] == "신한은행"
    assert profile["bank_accounts"][1]["is_default"] is False

    # Step 3: 디폴트 변경 (신한은행을 기본으로)
    accounts[0]["is_default"] = False
    accounts[1]["is_default"] = True
    result = await teacher.update_teacher_profile(teacher_id, bank_accounts=accounts)
    assert result["bank_accounts"][1]["is_default"] is True

    # Step 4: 계좌 1개 삭제 (국민은행)
    updated_accounts = [accounts[1]]
    result = await teacher.update_teacher_profile(teacher_id, bank_accounts=updated_accounts)
    assert len(result["bank_accounts"]) == 1
    assert result["bank_accounts"][0]["bank_name"] == "신한은행"
