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

    req_id = await student.send_connection_request(
        "test-user-id", method="inviteCode", invite_code=code
    )

    pending = await teacher.list_pending_requests()
    assert_total(pending, 1)

    await teacher.accept_connection(req_id)
    conns = await teacher.list_connections()
    assert_total(conns, 1)

    booking_id = await student.book_trial("test-user-id", instrument="violin")
    result = await teacher.approve_booking(booking_id)
    assert_status(result, "approved")


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
        lessons.append(
            await teacher.create_lesson(sid, date="2026-03-20", start_time=time)
        )

    # Complete first two
    await teacher.complete_lesson(lessons[0])
    await teacher.complete_lesson(lessons[1])
    await teacher.write_feedback(lessons[0], feedback="잘 했어요!")
    await teacher.write_feedback(lessons[1], feedback="많이 좋아졌어요!")

    # Cancel third
    await teacher.cancel_lesson(lessons[2])
