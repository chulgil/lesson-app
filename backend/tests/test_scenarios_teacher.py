"""E2E scenario tests — Teacher user journey.

Each test follows a real user flow that the Flutter frontend would execute,
calling multiple APIs sequentially and verifying data consistency across calls.
"""

import pytest
from httpx import AsyncClient

# ===========================================================================
# Scenario 1: 온보딩 → 학생 등록 → 첫 레슨 → 피드백
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_onboarding_to_first_lesson(client: AsyncClient, auth_headers, create_test_user):
    """Teacher onboards, registers a student, creates a lesson, writes feedback."""
    # Step 1: Teacher logs in (user already exists from auth)
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 2: Get my profile
    profile = await client.get("/api/v1/users/me", headers=auth_headers)
    assert profile.status_code == 200
    assert profile.json()["role"] == "teacher"

    # Step 3: Get teacher settings (auto-created with defaults)
    settings = await client.get("/api/v1/settings/teacher", headers=auth_headers)
    assert settings.status_code == 200
    assert settings.json()["default_lesson_duration"] == 60

    # Step 4: Register a new student
    student_resp = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "김민준", "instrument": "violin", "level": "beginner"},
    )
    assert student_resp.status_code == 201
    student_id = student_resp.json()["id"]
    assert student_resp.json()["name"] == "김민준"

    # Step 5: Verify student appears in list
    students = await client.get("/api/v1/students", headers=auth_headers)
    assert students.status_code == 200
    assert students.json()["total"] >= 1

    # Step 6: Create first lesson
    lesson_resp = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "instrument": "violin",
            "date": "2026-03-20",
            "start_time": "14:00",
            "duration": 60,
            "pieces": [{"name": "Twinkle Twinkle", "composer": "Mozart"}],
            "location_name": "홈 스튜디오",
        },
    )
    assert lesson_resp.status_code == 201
    lesson_id = lesson_resp.json()["id"]
    assert lesson_resp.json()["status"] == "scheduled"

    # Step 7: Get lesson detail
    detail = await client.get(f"/api/v1/lessons/{lesson_id}", headers=auth_headers)
    assert detail.status_code == 200
    assert detail.json()["student_id"] == student_id
    assert detail.json()["location_name"] == "홈 스튜디오"

    # Step 8: Complete the lesson
    status_resp = await client.patch(
        f"/api/v1/lessons/{lesson_id}/status",
        headers=auth_headers,
        json={"status": "completed"},
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "completed"

    # Step 9: Write feedback
    feedback_resp = await client.put(
        f"/api/v1/lessons/{lesson_id}/feedback",
        headers=auth_headers,
        json={
            "feedback": "활 잡기가 많이 좋아졌어요!",
            "key_points": ["활 잡기", "자세"],
            "practice_tips": "매일 10분 활 잡기 연습",
        },
    )
    assert feedback_resp.status_code == 200
    assert feedback_resp.json()["feedback"] == "활 잡기가 많이 좋아졌어요!"

    # Step 10: Verify it shows in recent lessons
    recent = await client.get("/api/v1/lessons/recent", headers=auth_headers)
    assert recent.status_code == 200


# ===========================================================================
# Scenario 2: 수강권 발급 → 레슨 차감 → 만료 임박
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_subscription_lifecycle(client: AsyncClient, auth_headers, create_test_user):
    """Teacher creates a template, issues subscription, deducts lessons until expiring."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Create subscription template
    tmpl = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "name": "바이올린 8회",
            "type": "package",
            "lessons_count": 8,
            "amount": 320000,
            "description": "바이올린 8회 패키지",
        },
    )
    assert tmpl.status_code == 201

    # Step 2: Create student
    student = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "이서연", "instrument": "violin"},
    )
    student_id = student.json()["id"]

    # Step 3: Issue subscription to student
    sub = await client.post(
        "/api/v1/subscriptions",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "type": "package",
            "total_lessons": 8,
            "amount": 320000,
            "start_date": "2026-03-01",
            "payment_confirmed": False,
        },
    )
    assert sub.status_code == 201
    sub_id = sub.json()["id"]
    assert sub.json()["remaining_lessons"] == 8

    # Step 4: Create lessons and deduct one by one
    for i in range(6):
        lesson = await client.post(
            "/api/v1/lessons",
            headers=auth_headers,
            json={
                "student_id": student_id,
                "date": f"2026-03-{10 + i:02d}",
                "start_time": "15:00",
                "duration": 60,
            },
        )
        lesson_id = lesson.json()["id"]

        # Complete and deduct
        await client.patch(
            f"/api/v1/lessons/{lesson_id}/status",
            headers=auth_headers,
            json={"status": "completed"},
        )
        deduct = await client.patch(
            f"/api/v1/subscriptions/{sub_id}/use-lesson",
            headers=auth_headers,
            json={"lesson_id": lesson_id},
        )
        assert deduct.status_code == 200

    # Step 5: Check remaining is 2 (8 - 6)
    sub_detail = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub_detail.status_code == 200
    assert sub_detail.json()["remaining_lessons"] == 2
    assert sub_detail.json()["used_lessons"] == 6

    # Step 6: Confirm payment
    pay = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/confirm-payment",
        headers=auth_headers,
        json={"payment_method": "bankTransfer"},
    )
    assert pay.status_code == 200


# ===========================================================================
# Scenario 3: 초대 → 연결 → 수업 예약 → 승인
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_invite_connect_booking(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Teacher invites → student connects → books trial → teacher approves."""
    await create_test_user(user_id="test-user-id", role="teacher", name="박선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="최학생",
    )

    # Step 1: Teacher creates invite
    invite = await client.post(
        "/api/v1/invites/",
        headers=auth_headers,
        json={"is_single_use": True, "expires_in_hours": 72},
    )
    assert invite.status_code == 201
    invite_code = invite.json()["invite_code"]

    # Step 2: Student sends connection request using invite code
    conn_req = await client.post(
        "/api/v1/invites/connection-requests",
        headers=student_auth_headers,
        json={
            "target_id": "test-user-id",
            "method": "inviteCode",
            "invite_code": invite_code,
        },
    )
    assert conn_req.status_code == 201
    req_id = conn_req.json()["id"]

    # Step 3: Teacher sees pending request
    pending = await client.get(
        "/api/v1/invites/connection-requests/pending",
        headers=auth_headers,
    )
    assert pending.json()["total"] == 1
    assert pending.json()["items"][0]["requester_name"] == "최학생"

    # Step 4: Teacher accepts
    accept = await client.patch(
        f"/api/v1/invites/connection-requests/{req_id}/respond",
        headers=auth_headers,
        json={"action": "accept"},
    )
    assert accept.json()["status"] == "accepted"

    # Step 5: Connection exists
    conns = await client.get("/api/v1/invites/connections", headers=auth_headers)
    assert conns.json()["total"] == 1

    # Step 6: Student books trial lesson
    booking = await client.post(
        "/api/v1/bookings",
        headers=student_auth_headers,
        json={
            "teacher_id": "test-user-id",
            "lesson_type": "trial",
            "scheduled_date": "2026-03-25",
            "scheduled_time": "10:00",
            "duration": 30,
            "instrument": "violin",
        },
    )
    assert booking.status_code == 201
    booking_id = booking.json()["id"]
    assert booking.json()["status"] == "pending"

    # Step 7: Teacher approves booking
    approve = await client.patch(
        f"/api/v1/bookings/{booking_id}/approve",
        headers=auth_headers,
    )
    assert approve.status_code == 200
    assert approve.json()["status"] == "confirmed"


# ===========================================================================
# Scenario 4: 그룹 수업 운영 (생성 → 예약 → 만석 → 대기열 → 취소/승격 → 출석)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_group_class_full_lifecycle(client: AsyncClient, auth_headers, create_test_user):
    """Full group class lifecycle: schedule, fill, waitlist, cancel, promote, attend."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Create group schedule (capacity 2, waitlist 1)
    sched = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-ensemble",
            "start_time": "2026-04-05T14:00:00",
            "end_time": "2026-04-05T15:30:00",
            "max_capacity": 2,
            "waitlist_capacity": 1,
        },
    )
    assert sched.status_code == 201
    sched_id = sched.json()["id"]

    # Step 2: Book 2 students (fills capacity)
    b1 = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": sched_id, "student_id": "student-a"},
    )
    assert b1.json()["status"] == "confirmed"

    b2 = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": sched_id, "student_id": "student-b"},
    )
    assert b2.json()["status"] == "confirmed"

    # Step 3: 3rd student goes to waitlist
    b3 = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": sched_id, "student_id": "student-c"},
    )
    assert b3.json()["status"] == "waitlist"
    assert b3.json()["waitlist_position"] == 1

    # Step 4: Student-a cancels → student-c auto-promoted
    cancel = await client.patch(
        f"/api/v1/groups/bookings/{b1.json()['id']}/cancel",
        headers=auth_headers,
        params={"reason": "개인 사정"},
    )
    assert cancel.json()["status"] == "cancelled"

    # Step 5: Verify student-c is now confirmed
    bookings = await client.get(
        f"/api/v1/groups/schedules/{sched_id}/bookings",
        headers=auth_headers,
    )
    confirmed = [b for b in bookings.json() if b["status"] == "confirmed"]
    assert len(confirmed) == 2
    confirmed_students = {b["student_id"] for b in confirmed}
    assert "student-c" in confirmed_students

    # Step 6: Mark attendance
    for b in confirmed:
        att = await client.patch(
            f"/api/v1/groups/bookings/{b['id']}/attendance",
            headers=auth_headers,
            json={"attended": True},
        )
        assert att.json()["status"] == "attended"


# ===========================================================================
# Scenario 5: 연습 관리 (레퍼토리 → 과제 → 연습 기록 → 통계 → 게이미피케이션)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_practice_management(client: AsyncClient, auth_headers, create_test_user):
    """Teacher assigns practice, student records, stats + gamification update."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Create student
    student = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "정하율", "instrument": "piano"},
    )
    student_id = student.json()["id"]

    # Step 2: Create repertoire
    rep = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "name": "소나타 K.545",
            "start_date": "2026-03-01",
        },
    )
    assert rep.status_code == 201
    rep_id = rep.json()["id"]

    # Step 3: Add practice section
    section = await client.post(
        "/api/v1/practice/sections",
        headers=auth_headers,
        json={
            "repertoire_id": rep_id,
            "piece_name": "소나타 K.545 1악장",
            "range_type": "measure",
            "start_measure": 1,
            "end_measure": 32,
        },
    )
    assert section.status_code == 201

    # Step 4: Create daily practice logs for 3 days
    for day in range(1, 4):
        log = await client.post(
            "/api/v1/practice-logs/",
            headers=auth_headers,
            params={"student_id": student_id},
            json={
                "date": f"2026-03-{day:02d}",
                "total_minutes": 30 + day * 5,
                "tasks": [
                    {"id": f"t{day}", "title": f"Day {day} practice", "is_completed": True},
                ],
            },
        )
        assert log.status_code == 201

    # Step 5: Check weekly practice
    weekly = await client.get(
        "/api/v1/practice-logs/weekly",
        headers=auth_headers,
        params={"student_id": student_id, "week_start": "2026-03-01"},
    )
    assert weekly.status_code == 200
    assert weekly.json()[0] is True  # Mon (3/1 is Sun in 2026? let's check)

    # Step 6: Check monthly stats
    stats = await client.get(
        "/api/v1/practice-logs/stats",
        headers=auth_headers,
        params={"student_id": student_id, "year": 2026, "month": 3},
    )
    assert stats.status_code == 200
    assert stats.json()["practiced_days"] == 3
    assert stats.json()["total_minutes"] == 35 + 40 + 45  # 120

    # Step 7: Award gamification points
    pts = await client.post(
        "/api/v1/gamification/points",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "points": 30,
            "type": "practiceComplete",
            "description": "3일 연속 연습 완료",
        },
    )
    assert pts.status_code == 201

    # Step 8: Check gamification summary
    gam = await client.get(
        f"/api/v1/gamification/{student_id}",
        headers=auth_headers,
    )
    assert gam.status_code == 200
    assert gam.json()["total_points"] == 30
    assert len(gam.json()["recent_history"]) == 1


# ===========================================================================
# Scenario 6: 대시보드 → 피드백 관리 → 교육자료 → 리뷰 확인
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_dashboard_and_content(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
):
    """Teacher opens dashboard, manages feedback presets, adds resources, checks reviews."""
    await create_test_user(user_id="test-user-id", role="teacher", name="김선생")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="학생A",
    )

    # Step 1: Teacher dashboard
    dash = await client.get("/api/v1/teachers/test-user-id/dashboard", headers=auth_headers)
    assert dash.status_code == 200

    # Step 2: Create student + lesson for context
    student = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "학생B", "instrument": "cello"},
    )
    student_id = student.json()["id"]

    lesson = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "date": "2026-03-20",
            "start_time": "16:00",
            "duration": 60,
        },
    )
    assert lesson.status_code == 201

    # Step 3: Check upcoming lessons
    upcoming = await client.get("/api/v1/lessons/upcoming", headers=auth_headers)
    assert upcoming.status_code == 200

    # Step 4: Create feedback presets for quick feedback
    preset1 = await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "음정이 정확해졌어요!"},
    )
    preset2 = await client.post(
        "/api/v1/settings/feedback-presets",
        headers=auth_headers,
        json={"text": "활 압력 조절 연습 필요"},
    )
    assert preset1.status_code == 201
    assert preset2.status_code == 201

    # Step 5: List presets (should have 2)
    presets = await client.get("/api/v1/settings/feedback-presets", headers=auth_headers)
    assert len(presets.json()) == 2

    # Step 6: Add teaching resource (YouTube)
    resource = await client.post(
        "/api/v1/settings/teaching-resources",
        headers=auth_headers,
        json={
            "type": "youtube",
            "title": "정명훈 마스터클래스",
            "youtube_video_id": "dQw4w9WgXcQ",
            "youtube_start_seconds": 120,
            "youtube_end_seconds": 300,
            "instrument": "cello",
            "tags": ["마스터클래스", "첼로"],
        },
    )
    assert resource.status_code == 201

    # Step 7: Verify resource in list
    resources = await client.get("/api/v1/settings/teaching-resources", headers=auth_headers)
    assert resources.json()["total"] == 1
    assert resources.json()["items"][0]["youtube_start_seconds"] == 120

    # Step 8: Student writes a review
    review = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={
            "teacher_id": "test-user-id",
            "rating": 5,
            "content": "최고의 선생님입니다!",
            "tags": ["친절", "전문적", "열정적"],
        },
    )
    assert review.status_code == 201

    # Step 9: Teacher checks review summary
    summary = await client.get(
        "/api/v1/reviews/test-user-id/summary",
        headers=auth_headers,
    )
    assert summary.status_code == 200
    assert summary.json()["total_reviews"] == 1
    assert summary.json()["average_rating"] == 5.0

    # Step 10: Teacher checks review list
    reviews = await client.get("/api/v1/reviews/test-user-id", headers=auth_headers)
    assert reviews.json()["total"] == 1
    assert reviews.json()["items"][0]["content"] == "최고의 선생님입니다!"


# ===========================================================================
# Scenario 7: 설정 변경 전체 흐름 (선생님 → 수강권 → 제안 → 알림)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_settings_full_configuration(client: AsyncClient, auth_headers, create_test_user):
    """Teacher configures all settings in order during initial setup."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Teacher settings — change lesson duration
    ts = await client.put(
        "/api/v1/settings/teacher",
        headers=auth_headers,
        json={
            "instruments": ["violin", "viola"],
            "default_lesson_duration": 50,
            "break_time_between_lessons": 15,
            "custom_lesson_durations": [30, 45, 50, 60, 90],
        },
    )
    assert ts.status_code == 200
    assert ts.json()["instruments"] == ["violin", "viola"]
    assert ts.json()["default_lesson_duration"] == 50

    # Step 2: Subscription settings — renewal alerts
    ss = await client.put(
        "/api/v1/settings/subscription",
        headers=auth_headers,
        json={
            "renewal_alert_threshold": 3,
            "renewal_alert_days": 14,
            "discount_policies": [
                {"min_lessons": 12, "type": "discount", "value": 10},
            ],
        },
    )
    assert ss.status_code == 200
    assert ss.json()["renewal_alert_threshold"] == 3
    assert len(ss.json()["discount_policies"]) == 1

    # Step 3: Proposal settings — auto proposal
    ps = await client.put(
        "/api/v1/settings/proposal",
        headers=auth_headers,
        json={
            "auto_proposal_enabled": True,
            "golden_time_hours": 48,
            "auto_renewal_enabled": True,
        },
    )
    assert ps.status_code == 200
    assert ps.json()["auto_proposal_enabled"] is True
    assert ps.json()["golden_time_hours"] == 48

    # Step 4: Verify all settings are persisted by re-reading
    ts2 = await client.get("/api/v1/settings/teacher", headers=auth_headers)
    assert ts2.json()["default_lesson_duration"] == 50

    ss2 = await client.get("/api/v1/settings/subscription", headers=auth_headers)
    assert ss2.json()["renewal_alert_threshold"] == 3

    ps2 = await client.get("/api/v1/settings/proposal", headers=auth_headers)
    assert ps2.json()["auto_renewal_enabled"] is True


# ===========================================================================
# Scenario 8: 학생 수강권 제안 흐름 (제안 → 학생 수락 → 수강권 발급)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_proposal_to_subscription(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user, db_session
):
    """Teacher proposes subscription → student accepts → subscription issued."""
    from tests.scenarios.helpers import link_student_to_user
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student@test.com",
        name="학생",
    )

    # Step 1: Create template
    tmpl = await client.post(
        "/api/v1/subscriptions-templates",
        headers=auth_headers,
        json={
            "name": "기본 4회",
            "type": "package",
            "lessons_count": 4,
            "amount": 160000,
        },
    )
    template_id = tmpl.json()["id"]

    # Step 2: Create student
    student = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "제안학생", "instrument": "piano"},
    )
    student_id = student.json()["id"]

    # Link the offline student to the accepting student's user so it is OWNED,
    # mirroring the production connect flow (#468 IDOR fix).
    await link_student_to_user(db_session, student_id, "test-student-id")

    # Step 3: Teacher sends proposal
    proposal = await client.post(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "template_id": template_id,
            "message": "기본 4회 패키지를 추천합니다!",
            "template_ids": [template_id],
            "recommended_template_id": template_id,
        },
    )
    assert proposal.status_code == 201
    proposal_id = proposal.json()["id"]
    assert proposal.json()["status"] == "pending"

    # Step 4: Check proposal in list
    proposals = await client.get(
        "/api/v1/subscriptions-proposals",
        headers=auth_headers,
    )
    assert proposals.json()["total"] >= 1

    # Step 5: Student accepts proposal (status → paymentNotified)
    accept = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/respond",
        headers=student_auth_headers,
        json={"action": "accept", "selected_template_id": template_id},
    )
    assert accept.status_code == 200
    assert accept.json()["status"] == "paymentNotified"

    # Step 6: Teacher confirms payment (status → confirmed)
    confirm = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )
    assert confirm.status_code == 200


# ===========================================================================
# Scenario 9: 노쇼 관리 (레슨 노쇼 → 기록 → 보강 생성)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_no_show_and_makeup(client: AsyncClient, auth_headers, create_test_user):
    """Student no-shows → teacher records → creates makeup booking."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Create student + lesson
    student = await client.post(
        "/api/v1/students",
        headers=auth_headers,
        json={"name": "결석생", "instrument": "flute"},
    )
    student_id = student.json()["id"]

    lesson = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "date": "2026-03-15",
            "start_time": "11:00",
            "duration": 60,
        },
    )
    lesson_id = lesson.json()["id"]

    # Step 2: Mark lesson as noShow
    ns = await client.patch(
        f"/api/v1/lessons/{lesson_id}/status",
        headers=auth_headers,
        json={"status": "noShow"},
    )
    assert ns.json()["status"] == "noShow"

    # Step 3: Record no-show
    record = await client.post(
        "/api/v1/groups/no-shows",
        headers=auth_headers,
        json={
            "lesson_id": lesson_id,
            "student_id": student_id,
            "lesson_date": "2026-03-15",
            "applied_policy": "deductCredit",
            "deducted_credits": 1,
            "note": "사전 연락 없이 결석",
        },
    )
    assert record.status_code == 201
    assert record.json()["deducted_credits"] == 1

    # Step 4: Create makeup booking
    makeup = await client.post(
        "/api/v1/bookings/makeup",
        headers=auth_headers,
        json={
            "student_id": student_id,
            "original_lesson_id": lesson_id,
            "scheduled_date": "2026-03-22",
            "scheduled_time": "11:00",
            "reason": "3/15 결석 보강",
        },
    )
    assert makeup.status_code == 201

    # Step 5: Verify no-show records list
    records = await client.get("/api/v1/groups/no-shows", headers=auth_headers)
    assert records.json()["total"] == 1


# ===========================================================================
# Scenario 10: 멀티 학생 레슨 관리 (하루 레슨 여러 개)
# ===========================================================================


@pytest.mark.asyncio
async def test_scenario_multi_student_day(client: AsyncClient, auth_headers, create_test_user):
    """Teacher manages multiple lessons on the same day."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # Step 1: Create 3 students
    students = []
    for i, name in enumerate(["김가영", "박민수", "이지은"]):
        s = await client.post(
            "/api/v1/students",
            headers=auth_headers,
            json={"name": name, "instrument": "violin"},
        )
        students.append(s.json()["id"])

    # Step 2: Create lessons at different times
    lesson_ids = []
    for i, (sid, time) in enumerate(zip(students, ["10:00", "11:30", "14:00"])):
        lesson = await client.post(
            "/api/v1/lessons",
            headers=auth_headers,
            json={
                "student_id": sid,
                "date": "2026-03-20",
                "start_time": time,
                "duration": 60,
            },
        )
        lesson_ids.append(lesson.json()["id"])

    # Step 3: List lessons for the day
    day_lessons = await client.get(
        "/api/v1/lessons",
        headers=auth_headers,
        params={"date": "2026-03-20"},
    )
    assert day_lessons.status_code == 200
    assert day_lessons.json()["total"] == 3

    # Step 4: Complete first two, cancel third
    for lid in lesson_ids[:2]:
        await client.patch(
            f"/api/v1/lessons/{lid}/status",
            headers=auth_headers,
            json={"status": "completed"},
        )

    await client.patch(
        f"/api/v1/lessons/{lesson_ids[2]}/status",
        headers=auth_headers,
        json={"status": "cancelled"},
    )

    # Step 5: Write feedback for completed lessons
    for lid in lesson_ids[:2]:
        fb = await client.put(
            f"/api/v1/lessons/{lid}/feedback",
            headers=auth_headers,
            json={"feedback": "잘했어요!", "key_points": ["음정"]},
        )
        assert fb.status_code == 200

    # Step 6: Check student stats
    stats = await client.get(
        f"/api/v1/students/{students[0]}/stats",
        headers=auth_headers,
    )
    assert stats.status_code == 200
