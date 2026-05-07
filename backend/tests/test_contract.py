"""Contract tests — simulate frontend Remote Repository requests.

These tests verify that the backend accepts the exact request format
that frontend Remote Repositories send, and returns responses
in the format frontend expects.
"""

from datetime import UTC, date, datetime

import pytest

from app.core.security import create_access_token

# ---------------------------------------------------------------------------
# Auth contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_logout_no_body(client, auth_headers, create_test_user):
    """Frontend sends POST /auth/logout with no body."""
    await create_test_user()
    resp = await client.post("/api/v1/auth/logout", headers=auth_headers)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_logout_with_refresh_token(client, auth_headers, create_test_user):
    """Frontend may send refresh_token in body."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": "some-token"},
        headers=auth_headers,
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_refresh_returns_both_tokens(client, auth_headers, create_test_user):
    """Frontend expects both access_token and refresh_token in refresh response."""
    await create_test_user()
    # First, do dev-login to get a real refresh token
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "test@test.com", "role": "teacher"},
    )
    assert login_resp.status_code == 200
    refresh_token = login_resp.json()["refresh_token"]

    resp = await client.post(
        "/api/v1/auth/token/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_contract_dev_login_response_format(client):
    """Frontend expects {access_token, refresh_token, token_type, user: {...}}."""
    resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "contract@test.com", "role": "teacher"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user" in data
    user = data["user"]
    assert "id" in user
    assert "email" in user
    assert "name" in user


# ---------------------------------------------------------------------------
# Teacher Profile contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_get_my_profile(client, auth_headers, create_test_user):
    """Frontend calls GET /teachers/me/profile."""
    await create_test_user()
    # Auto-create teacher profile via dev-login
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "teacher@test.com", "role": "teacher"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/teachers/me/profile", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "id" in data
    assert "user_id" in data
    assert "instruments" in data
    # Should include enriched fields
    assert "education" in data
    assert "career" in data
    assert "certificates" in data
    assert "lesson_areas" in data
    assert "visibility_settings" in data


@pytest.mark.asyncio
async def test_contract_teacher_response_includes_user(client, auth_headers, create_test_user):
    """Frontend expects TeacherResponse.user to contain UserResponse."""
    await create_test_user()
    login_resp = await client.post(
        "/api/v1/auth/dev-login",
        json={"email": "teacher@test.com", "role": "teacher"},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/teachers/me/profile", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"] is not None
    assert data["user"]["name"] is not None


# ---------------------------------------------------------------------------
# Student contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_student_search_param(client, auth_headers, create_test_user):
    """Frontend sends ?search= instead of ?q=."""
    await create_test_user()
    resp = await client.get(
        "/api/v1/students?search=김",
        headers=auth_headers,
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_contract_student_status_update(client, auth_headers, create_test_user):
    """Frontend sends PATCH /students/{id}/status."""
    await create_test_user()
    # Create student first
    create_resp = await client.post(
        "/api/v1/students",
        json={"name": "테스트학생", "instrument": "piano"},
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    student_id = create_resp.json()["id"]

    resp = await client.patch(
        f"/api/v1/students/{student_id}/status",
        json={"status": "paused"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "paused"


@pytest.mark.asyncio
async def test_contract_student_create_all_fields(client, auth_headers, create_test_user):
    """Frontend sends many fields that backend should accept."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/students",
        json={
            "name": "김학생",
            "instrument": "violin",
            "level": "beginner",
            "email": "student@test.com",
            "parent_name": "김부모",
            "phone": "010-1234-5678",
            "parent_phone": "010-8765-4321",
            "lesson_day": "monday",
            "lesson_time": "14:00",
            "lesson_duration": 45,
            "notes": "특이사항 없음",
            "birth_date": "2015-03-15",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == "student@test.com"
    assert data["parent_name"] == "김부모"
    assert data["lesson_day"] == "monday"
    assert data["lesson_time"] == "14:00"
    assert data["lesson_duration"] == 45
    assert data["notes"] == "특이사항 없음"


@pytest.mark.asyncio
async def test_contract_student_create_preserves_frontend_full_json_fields(client, auth_headers, create_test_user):
    """RemoteStudentRepository sends Student.toJson(); backend should not drop persisted frontend fields."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/students",
        json={
            "id": "local-student-id",
            "name": "주소학생",
            "instrument": "piano",
            "level": "intermediate",
            "status": "trial",
            "monthly_fee": 210000,
            "lessons_per_week": 2,
            "profile_image_url": "https://cdn.example/profile.png",
            "background_image_url": "https://cdn.example/bg.png",
            "birth_date": "2014-01-02T00:00:00.000",
            "manual_age_group": "child",
            "postal_code": "06164",
            "address": "서울 강남구 테헤란로",
            "address_detail": "101동 202호",
            "district": "삼성동",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["background_image_url"] == "https://cdn.example/bg.png"
    assert data["age_group"] == "child"
    assert data["postal_code"] == "06164"
    assert data["address"] == "서울 강남구 테헤란로"
    assert data["address_detail"] == "101동 202호"
    assert data["district"] == "삼성동"

    update_resp = await client.put(
        f"/api/v1/students/{data['id']}",
        json={
            **data,
            "manual_age_group": "adult",
            "background_image_url": "https://cdn.example/bg2.png",
            "address_detail": "303호",
        },
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    updated = update_resp.json()
    assert updated["age_group"] == "adult"
    assert updated["background_image_url"] == "https://cdn.example/bg2.png"
    assert updated["address_detail"] == "303호"


@pytest.mark.asyncio
async def test_contract_student_response_all_fields(client, auth_headers, create_test_user):
    """Frontend expects many fields in StudentResponse."""
    await create_test_user()
    create_resp = await client.post(
        "/api/v1/students",
        json={"name": "필드테스트", "instrument": "piano"},
        headers=auth_headers,
    )
    student_id = create_resp.json()["id"]

    resp = await client.get(
        f"/api/v1/students/{student_id}",
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    # All fields should be present (even if null)
    expected_fields = [
        "id", "teacher_id", "name", "instrument", "level", "status",
        "phone", "parent_phone", "parent_name", "email",
        "lesson_day", "lesson_time", "lesson_duration",
        "birth_date", "age_group", "connection_status",
        "practice_level", "break_reason", "notes", "is_active",
    ]
    for field in expected_fields:
        assert field in data, f"Missing field: {field}"


@pytest.mark.asyncio
async def test_contract_membership_preserves_frontend_lesson_location_id(client, auth_headers, create_test_user):
    """ClassMembership.toJson includes lesson_location_id; backend should persist and return it."""
    await create_test_user()
    student_resp = await client.post(
        "/api/v1/students",
        json={"name": "위치학생", "instrument": "violin"},
        headers=auth_headers,
    )
    assert student_resp.status_code == 201
    class_resp = await client.post(
        "/api/v1/lessons-classes",
        json={"name": "화요반", "type": "academy", "payment_type": "parent"},
        headers=auth_headers,
    )
    assert class_resp.status_code == 201
    class_id = class_resp.json()["id"]
    location_resp = await client.post(
        "/api/v1/locations",
        json={
            "lesson_class_id": class_id,
            "name": "레슨실 A",
            "type": "academyRoom",
            "is_default": True,
        },
        headers=auth_headers,
    )
    assert location_resp.status_code == 201
    location_id = location_resp.json()["id"]

    create_resp = await client.post(
        f"/api/v1/lessons-classes/{class_id}/memberships",
        json={
            "student_id": student_resp.json()["id"],
            "instrument": "violin",
            "monthly_fee": 250000,
            "lesson_location_id": location_id,
            "travel_time_minutes": 15,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    data = create_resp.json()
    assert data["lesson_location_id"] == location_id
    assert data["travel_time_minutes"] == 15

    update_resp = await client.put(
        f"/api/v1/lessons-classes/{class_id}/memberships/{data['id']}",
        json={**data, "lesson_location_id": None},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["lesson_location_id"] is None


@pytest.mark.asyncio
async def test_contract_subscription_preserves_frontend_full_json_fields(client, auth_headers, create_test_user):
    """Subscription.toJson includes billing, discount, and reschedule policy fields."""
    await create_test_user()
    student_resp = await client.post(
        "/api/v1/students",
        json={"name": "수강권필드", "instrument": "piano"},
        headers=auth_headers,
    )
    assert student_resp.status_code == 201
    class_resp = await client.post(
        "/api/v1/lessons-classes",
        json={"name": "수강권 계약 클래스", "type": "private"},
        headers=auth_headers,
    )
    assert class_resp.status_code == 201
    membership_resp = await client.post(
        f"/api/v1/lessons-classes/{class_resp.json()['id']}/memberships",
        json={"student_id": student_resp.json()["id"], "instrument": "piano"},
        headers=auth_headers,
    )
    assert membership_resp.status_code == 201
    create_resp = await client.post(
        "/api/v1/subscriptions",
        json={
            "student_id": student_resp.json()["id"],
            "membership_id": membership_resp.json()["id"],
            "type": "package",
            "status": "active",
            "total_lessons": 8,
            "used_lessons": 2,
            "start_date": "2026-05-01T00:00:00.000",
            "end_date": "2026-06-30T00:00:00.000",
            "amount": 240000,
            "lessons_per_month": 4,
            "bonus_count": 1,
            "billing_type": "perPackage",
            "billing_day": 10,
            "fifth_week_policy": "bonus",
            "bonus_reason": "intro",
            "total_reschedule_allowance": 3,
            "used_reschedule_count": 1,
            "payment_confirmed": False,
            "payment_method": "bankTransfer",
            "discount_amount": 10000,
            "discount_reason": "family",
            "original_amount": 250000,
            "reschedule_deadline_hours": 24,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    created = create_resp.json()
    assert created["used_lessons"] == 2
    assert created["end_date"] == "2026-06-30"
    assert created["lessons_per_month"] == 4
    assert created["bonus_count"] == 1
    assert created["billing_type"] == "perPackage"
    assert created["billing_day"] == 10
    assert created["fifth_week_policy"] == "bonus"
    assert created["bonus_reason"] == "intro"
    assert created["total_reschedule_allowance"] == 3
    assert created["used_reschedule_count"] == 1
    assert created["payment_confirmed"] is False
    assert created["payment_method"] == "bankTransfer"
    assert created["discount_amount"] == 10000
    assert created["discount_reason"] == "family"
    assert created["original_amount"] == 250000
    assert created["reschedule_deadline_hours"] == 24

    update_resp = await client.put(
        f"/api/v1/subscriptions/{created['id']}",
        json={**created, "billing_day": 15, "reschedule_deadline_hours": 36},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    updated = update_resp.json()
    assert updated["billing_day"] == 15
    assert updated["reschedule_deadline_hours"] == 36


@pytest.mark.asyncio
async def test_contract_subscription_proposal_response_contains_required_frontend_fields(
    client, auth_headers, create_test_user
):
    """SubscriptionProposal.fromJson requires template_id and expires_at."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/subscriptions-proposals",
        json={
            "student_id": "student-proposal-required",
            "template_id": "template-required",
            "message": "다음 수강권을 제안합니다",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["template_id"] == "template-required"
    assert data["expires_at"] is not None
    assert "rejected_at" in data
    assert "academy_id" in data

    list_resp = await client.get(
        "/api/v1/subscriptions-proposals",
        params={"student_id": "student-proposal-required"},
        headers=auth_headers,
    )
    assert list_resp.status_code == 200
    listed = list_resp.json()["items"][0]
    assert listed["template_id"] == "template-required"
    assert listed["expires_at"] is not None


@pytest.mark.asyncio
async def test_contract_subscription_use_lesson_records_frontend_context(
    client, auth_headers, create_test_user
):
    """RemoteSubscriptionRepository.useLesson sends teacher_name and instrument for usage history."""
    await create_test_user()
    student_resp = await client.post(
        "/api/v1/students",
        json={"name": "사용내역학생", "instrument": "cello"},
        headers=auth_headers,
    )
    assert student_resp.status_code == 201
    class_resp = await client.post(
        "/api/v1/lessons-classes",
        json={"name": "사용내역 클래스", "type": "private"},
        headers=auth_headers,
    )
    assert class_resp.status_code == 201
    membership_resp = await client.post(
        f"/api/v1/lessons-classes/{class_resp.json()['id']}/memberships",
        json={"student_id": student_resp.json()["id"], "instrument": "cello"},
        headers=auth_headers,
    )
    assert membership_resp.status_code == 201
    create_resp = await client.post(
        "/api/v1/subscriptions",
        json={
            "student_id": student_resp.json()["id"],
            "membership_id": membership_resp.json()["id"],
            "type": "monthly",
            "total_lessons": 4,
            "amount": 120000,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    subscription_id = create_resp.json()["id"]

    use_resp = await client.patch(
        f"/api/v1/subscriptions/{subscription_id}/use-lesson",
        json={
            "lesson_id": "lesson-usage-context",
            "teacher_name": "박선생",
            "instrument": "cello",
        },
        headers=auth_headers,
    )
    assert use_resp.status_code == 200

    history_resp = await client.get(
        f"/api/v1/subscriptions/{subscription_id}/usage",
        headers=auth_headers,
    )
    assert history_resp.status_code == 200
    usage = history_resp.json()["items"][0]
    assert usage["lesson_id"] == "lesson-usage-context"
    assert usage["teacher_name"] == "박선생"
    assert usage["instrument"] == "cello"
    assert usage["usage_type"] == "normal"


@pytest.mark.asyncio
async def test_contract_lesson_request_proposals_are_frontend_parseable(
    client, auth_headers, student_auth_headers, create_test_user
):
    """UnifiedLessonRequest.fromJson reads normalized proposals with required IDs."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-request-proposals@test.com",
    )
    create_resp = await client.post(
        "/api/v1/schedule/lesson-requests",
        json={
            "teacher_id": "test-user-id",
            "type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience": "beginner",
            "preferred_duration": 60,
        },
        headers=student_auth_headers,
    )
    assert create_resp.status_code == 201
    request_id = create_resp.json()["id"]

    propose_resp = await client.post(
        f"/api/v1/schedule/lesson-requests/{request_id}/propose-alternatives",
        json={
            "slots": [
                {"day_of_week": 1, "start_time": "15:00", "end_time": "16:00"},
            ],
            "message": "화요일 가능",
        },
        headers=auth_headers,
    )
    assert propose_resp.status_code == 200
    data = propose_resp.json()
    proposal = data["proposals"][0]
    assert proposal["id"]
    assert proposal["proposer_id"] == "test-user-id"
    assert proposal["role"] == "teacher"
    assert proposal["action"] == "propose"
    assert proposal["slots"][0]["id"]
    assert proposal["slots"][0]["is_selected"] is False


# ---------------------------------------------------------------------------
# Location contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_location_crud(client, auth_headers, create_test_user):
    """Frontend expects full CRUD on /locations."""
    await create_test_user()

    # Create
    create_resp = await client.post(
        "/api/v1/locations",
        json={
            "name": "연습실 A",
            "type": "teacherStudio",
            "address": "서울시 강남구",
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    location_id = create_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/locations/{location_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "연습실 A"

    # List
    list_resp = await client.get("/api/v1/locations", headers=auth_headers)
    assert list_resp.status_code == 200

    # Update
    update_resp = await client.put(
        f"/api/v1/locations/{location_id}",
        json={"name": "연습실 B"},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["name"] == "연습실 B"

    # Deactivate
    deact_resp = await client.patch(
        f"/api/v1/locations/{location_id}/deactivate",
        headers=auth_headers,
    )
    assert deact_resp.status_code == 200

    # Reactivate
    react_resp = await client.patch(
        f"/api/v1/locations/{location_id}/reactivate",
        headers=auth_headers,
    )
    assert react_resp.status_code == 200


@pytest.mark.asyncio
async def test_location_crud_is_scoped_to_owner(client, create_test_user):
    """Teachers cannot read or mutate another teacher's locations."""
    await create_test_user(user_id="teacher-a-id", role="teacher", email="teacher-a-location@test.com")
    await create_test_user(user_id="teacher-b-id", role="teacher", email="teacher-b-location@test.com")

    teacher_a_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-a-id', 'role': 'teacher'})}"
    }
    teacher_b_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-b-id', 'role': 'teacher'})}"
    }

    create_resp = await client.post(
        "/api/v1/locations",
        json={
            "name": "Teacher B Studio",
            "type": "teacherStudio",
            "address": "서울시 강남구",
            "is_default": True,
        },
        headers=teacher_b_headers,
    )
    assert create_resp.status_code == 201
    location_id = create_resp.json()["id"]

    cross_list = await client.get(
        "/api/v1/locations?owner_id=teacher-b-id",
        headers=teacher_a_headers,
    )
    assert cross_list.status_code == 403

    cross_get = await client.get(
        f"/api/v1/locations/{location_id}",
        headers=teacher_a_headers,
    )
    assert cross_get.status_code == 403

    cross_update = await client.put(
        f"/api/v1/locations/{location_id}",
        json={"name": "Hijacked Studio"},
        headers=teacher_a_headers,
    )
    assert cross_update.status_code == 403

    cross_default = await client.patch(
        f"/api/v1/locations/{location_id}/default",
        headers=teacher_a_headers,
    )
    assert cross_default.status_code == 403

    cross_deactivate = await client.patch(
        f"/api/v1/locations/{location_id}/deactivate",
        headers=teacher_a_headers,
    )
    assert cross_deactivate.status_code == 403

    cross_reactivate = await client.patch(
        f"/api/v1/locations/{location_id}/reactivate",
        headers=teacher_a_headers,
    )
    assert cross_reactivate.status_code == 403

    owner_get = await client.get(
        f"/api/v1/locations/{location_id}",
        headers=teacher_b_headers,
    )
    assert owner_get.status_code == 200
    assert owner_get.json()["name"] == "Teacher B Studio"
    assert owner_get.json()["is_active"] is True


# ---------------------------------------------------------------------------
# Schedule exception contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_schedule_exception_rich_format(client, auth_headers, create_test_user):
    """Frontend sends rich format (start_date, end_date, start_time, end_time)."""
    await create_test_user()
    resp = await client.post(
        "/api/v1/schedule/exceptions",
        json={
            "type": "vacation",
            "start_date": "2026-04-01",
            "end_date": "2026-04-05",
            "start_time": "09:00",
            "end_time": "18:00",
            "reason": "봄방학",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["type"] == "vacation"
    assert data["start_date"] == "2026-04-01"
    assert data["end_date"] == "2026-04-05"


@pytest.mark.asyncio
async def test_contract_schedule_availability_delete(
    client, auth_headers, create_test_user
):
    """Frontend teacher availability repository calls DELETE /schedule/availability."""
    await create_test_user(user_id="test-user-id", role="teacher")

    set_resp = await client.put(
        "/api/v1/schedule/availability",
        json={
            "weekly_schedules": [
                {
                    "day_of_week": 0,
                    "start_time": "15:00",
                    "end_time": "18:00",
                    "is_active": True,
                }
            ]
        },
        headers=auth_headers,
    )
    assert set_resp.status_code == 200
    assert set_resp.json()["weekly_schedules"]

    delete_resp = await client.delete(
        "/api/v1/schedule/availability",
        headers=auth_headers,
    )
    assert delete_resp.status_code == 204

    get_resp = await client.get("/api/v1/schedule/availability", headers=auth_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["availabilities"] == []
    assert get_resp.json()["weekly_schedules"] == []


@pytest.mark.asyncio
async def test_contract_schedule_slots_without_date_returns_frontend_time_slot_list(
    client, auth_headers, student_auth_headers, create_test_user
):
    """RemoteBookingRepository.getTeacherAvailability expects a top-level list."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-slots-list@test.com",
    )

    set_resp = await client.put(
        "/api/v1/schedule/availability",
        json={
            "weekly_schedules": [
                {
                    "day_of_week": 0,
                    "start_time": "15:00",
                    "end_time": "18:00",
                    "is_active": True,
                }
            ]
        },
        headers=auth_headers,
    )
    assert set_resp.status_code == 200

    response = await client.get(
        "/api/v1/schedule/slots?teacher_id=test-user-id",
        headers=student_auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data == [
        {
            "id": "0-15:00-18:00",
            "day_of_week": 1,
            "start_time": "15:00",
            "end_time": "18:00",
            "is_active": True,
        }
    ]


@pytest.mark.asyncio
async def test_contract_schedule_slots_date_range_returns_dates_and_full_slots(
    client, auth_headers, student_auth_headers, create_test_user
):
    """Frontend range repositories expect dates plus AvailabilitySlot-shaped slots."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-slots-range@test.com",
    )

    set_resp = await client.put(
        "/api/v1/schedule/availability",
        json={
            "weekly_schedules": [
                {
                    "day_of_week": 0,
                    "start_time": "15:00",
                    "end_time": "17:00",
                    "is_active": True,
                }
            ]
        },
        headers=auth_headers,
    )
    assert set_resp.status_code == 200

    response = await client.get(
        "/api/v1/schedule/slots",
        params={
            "teacher_id": "test-user-id",
            "date_from": "2026-05-04",
            "date_to": "2026-05-10",
        },
        headers=student_auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["dates"] == ["2026-05-04"]
    assert data["slots"][0] == {
        "id": "test-user-id-2026-05-04-15:00",
        "teacher_id": "test-user-id",
        "date": "2026-05-04",
        "start_time": "15:00",
        "end_time": "16:00",
        "duration_minutes": 60,
        "status": "available",
        "booked_by_student_id": None,
        "booked_by_student_name": None,
        "lesson_id": None,
        "is_recommended": False,
    }


@pytest.mark.asyncio
async def test_contract_group_bookings_frontend_shapes_and_body_actions(
    client, auth_headers, create_test_user
):
    """RemoteGroupClassBookingRepository expects paginated /groups/bookings and body actions."""
    await create_test_user(user_id="test-user-id", role="teacher")

    schedule_resp = await client.post(
        "/api/v1/groups/schedules",
        json={
            "group_class_id": "group-001",
            "start_time": "2026-05-04T15:00:00",
            "end_time": "2026-05-04T16:00:00",
            "max_capacity": 1,
            "waitlist_capacity": 2,
        },
        headers=auth_headers,
    )
    assert schedule_resp.status_code == 201
    schedule_id = schedule_resp.json()["id"]

    confirmed_resp = await client.post(
        "/api/v1/groups/bookings",
        json={"schedule_id": schedule_id, "student_id": "student-confirmed"},
        headers=auth_headers,
    )
    assert confirmed_resp.status_code == 201
    waitlist_resp = await client.post(
        "/api/v1/groups/bookings",
        json={"schedule_id": schedule_id, "student_id": "student-waitlist"},
        headers=auth_headers,
    )
    assert waitlist_resp.status_code == 201
    assert waitlist_resp.json()["status"] == "waitlist"

    list_resp = await client.get(
        "/api/v1/groups/bookings",
        params={"schedule_id": schedule_id, "active": "true"},
        headers=auth_headers,
    )
    assert list_resp.status_code == 200
    list_data = list_resp.json()
    assert list_data["total"] == 1
    assert list_data["items"][0]["student_id"] == "student-confirmed"

    auto_cancel_resp = await client.post(
        "/api/v1/groups/bookings/auto-cancel-waitlist",
        json={"schedule_id": schedule_id},
        headers=auth_headers,
    )
    assert auto_cancel_resp.status_code == 200
    assert auto_cancel_resp.json()[0]["status"] == "cancelled"

    replacement_resp = await client.post(
        "/api/v1/groups/bookings",
        json={"schedule_id": schedule_id, "student_id": "student-waitlist-2"},
        headers=auth_headers,
    )
    assert replacement_resp.status_code == 201
    assert replacement_resp.json()["status"] == "waitlist"

    promote_resp = await client.post(
        "/api/v1/groups/bookings/promote",
        json={"schedule_id": schedule_id},
        headers=auth_headers,
    )
    assert promote_resp.status_code == 200
    assert promote_resp.json()["student_id"] == "student-waitlist-2"

    batch_resp = await client.post(
        "/api/v1/groups/bookings/batch-attendance",
        json={"attendance": [{"booking_id": confirmed_resp.json()["id"], "attended": True}]},
        headers=auth_headers,
    )
    assert batch_resp.status_code == 200
    assert batch_resp.json()[0]["status"] == "attended"


# ---------------------------------------------------------------------------
# Lesson request contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_booking_update_and_delete(
    client, auth_headers, create_test_user
):
    """Frontend booking repository calls PUT/DELETE /bookings/{id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/bookings",
        json={
            "teacher_id": "test-user-id",
            "student_id": "student-001",
            "lesson_type": "regular",
            "scheduled_date": "2026-05-10",
            "scheduled_time": "14:00",
            "duration": 60,
            "instrument": "piano",
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    booking_id = create_resp.json()["id"]

    update_resp = await client.put(
        f"/api/v1/bookings/{booking_id}",
        json={
            "scheduled_date": "2026-05-11",
            "scheduled_time": "15:00",
            "duration": 45,
            "instrument": "violin",
            "notes": "변경",
        },
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    updated = update_resp.json()
    assert updated["scheduled_date"] == "2026-05-11"
    assert updated["scheduled_time"] == "15:00"
    assert updated["duration"] == 45
    assert updated["instrument"] == "violin"

    delete_resp = await client.delete(
        f"/api/v1/bookings/{booking_id}",
        headers=auth_headers,
    )
    assert delete_resp.status_code == 204

    get_resp = await client.get(
        f"/api/v1/bookings/{booking_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 404


@pytest.mark.asyncio
async def test_contract_booking_create_preserves_frontend_student_and_date_aliases(
    client, auth_headers, create_test_user
):
    """RemoteBookingRepository sends student_id and regular lesson date aliases."""
    await create_test_user(user_id="test-user-id", role="teacher")

    regular_resp = await client.post(
        "/api/v1/bookings",
        json={
            "teacher_id": "test-user-id",
            "lesson_type": "regular",
            "student_id": "student-regular-001",
            "student_name": "Regular Student",
            "preferred_start_date": "2026-05-20T00:00:00.000",
            "message": "regular request",
            "fee": 200000,
        },
        headers=auth_headers,
    )
    assert regular_resp.status_code == 201
    regular = regular_resp.json()
    assert regular["student_id"] == "student-regular-001"
    assert regular["scheduled_date"] == "2026-05-20"
    assert regular["scheduled_time"] == "00:00"
    assert regular["lesson_date"] == "2026-05-20"
    assert regular["start_time"] == "00:00"
    assert regular["end_time"] == "01:00"
    assert regular["duration_minutes"] == 60

    registration_resp = await client.post(
        "/api/v1/bookings",
        json={
            "teacher_id": "test-user-id",
            "lesson_type": "regular",
            "student_id": "student-registration-001",
            "student_name": "Registration Student",
            "start_date": "2026-05-21T00:00:00.000",
            "schedule_type": "weekly",
            "lessons_per_week": 1,
            "fee": 200000,
        },
        headers=auth_headers,
    )
    assert registration_resp.status_code == 201
    registration = registration_resp.json()
    assert registration["student_id"] == "student-registration-001"
    assert registration["scheduled_date"] == "2026-05-21"
    assert registration["scheduled_time"] == "00:00"


@pytest.mark.asyncio
async def test_contract_lesson_delete(client, auth_headers, create_test_user):
    """Frontend lesson repository calls DELETE /lessons/{id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lessons",
        json={
            "student_id": "student-001",
            "instrument": "piano",
            "date": "2026-05-12",
            "start_time": "14:00",
            "duration": 60,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    lesson_id = create_resp.json()["id"]

    delete_resp = await client.delete(
        f"/api/v1/lessons/{lesson_id}",
        headers=auth_headers,
    )
    assert delete_resp.status_code == 204

    get_resp = await client.get(f"/api/v1/lessons/{lesson_id}", headers=auth_headers)
    assert get_resp.status_code == 404


@pytest.mark.asyncio
async def test_contract_lesson_class_reorder_route_not_captured_as_detail_update(
    client, auth_headers, create_test_user
):
    """Frontend calls PUT /lessons-classes/reorder, which must beat /{class_id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lessons-classes",
        json={"name": "Group A", "type": "academy"},
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    class_id = create_resp.json()["id"]

    reorder_resp = await client.put(
        "/api/v1/lessons-classes/reorder",
        json={"ordered_ids": [class_id]},
        headers=auth_headers,
    )
    assert reorder_resp.status_code == 200
    assert reorder_resp.json()["message"] == "Reorder successful"


@pytest.mark.asyncio
async def test_contract_practice_log_get_by_id(client, auth_headers, create_test_user):
    """Frontend practice repository calls GET /practice-logs/{id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/practice-logs/?student_id=student-001",
        json={
            "date": "2026-05-12",
            "total_minutes": 30,
            "tasks": [{"id": "task-1", "title": "scale", "is_completed": False}],
            "notes": "연습",
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    log_id = create_resp.json()["id"]

    get_resp = await client.get(
        f"/api/v1/practice-logs/{log_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == log_id
    assert get_resp.json()["total_minutes"] == 30


@pytest.mark.asyncio
async def test_contract_practice_log_list_frontend_shape_and_filters(
    client, auth_headers, create_test_user
):
    """Frontend practice repository expects /practice-logs to return {items: [...]}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    for payload in [
        {"date": "2026-05-01", "total_minutes": 20},
        {"date": "2026-05-15", "total_minutes": 30},
        {"date": "2026-04-30", "total_minutes": 40},
    ]:
        create_resp = await client.post(
            "/api/v1/practice-logs/?student_id=student-001",
            json=payload,
            headers=auth_headers,
        )
        assert create_resp.status_code == 201

    all_resp = await client.get(
        "/api/v1/practice-logs?student_id=student-001",
        headers=auth_headers,
    )
    assert all_resp.status_code == 200
    all_data = all_resp.json()
    assert "items" in all_data
    assert all_data["total"] == 3

    date_resp = await client.get(
        "/api/v1/practice-logs?student_id=student-001&date=2026-05-01",
        headers=auth_headers,
    )
    assert date_resp.status_code == 200
    assert [item["date"] for item in date_resp.json()["items"]] == ["2026-05-01"]

    month_resp = await client.get(
        "/api/v1/practice-logs?student_id=student-001&year=2026&month=5",
        headers=auth_headers,
    )
    assert month_resp.status_code == 200
    assert [item["date"] for item in month_resp.json()["items"]] == [
        "2026-05-01",
        "2026-05-15",
    ]


@pytest.mark.asyncio
async def test_contract_practice_log_frontend_create_and_weekly_defaults(
    client, auth_headers, create_test_user
):
    """RemotePracticeRepository posts student_id in body and omits week_start."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/practice-logs",
        json={
            "student_id": "student-001",
            "date": "2026-05-04",
            "total_minutes": 25,
            "tasks": [],
            "notes": "frontend body student",
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    assert create_resp.json()["student_id"] == "student-001"

    weekly_resp = await client.get(
        "/api/v1/practice-logs/weekly?student_id=student-001",
        headers=auth_headers,
    )
    assert weekly_resp.status_code == 200
    data = weekly_resp.json()
    assert isinstance(data, list)
    assert len(data) == 7
    assert all(isinstance(day, bool) for day in data)


@pytest.mark.asyncio
async def test_contract_practice_streak_update_and_record(
    client, auth_headers, create_test_user
):
    """Frontend practice repository calls PUT /practice/streak and POST /practice/streak/record."""
    await create_test_user(user_id="test-user-id", role="teacher")

    update_resp = await client.put(
        "/api/v1/practice/streak?student_id=student-001",
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["student_id"] == "student-001"
    assert update_resp.json()["current_streak"] == 0

    record_resp = await client.post(
        "/api/v1/practice/streak/record?student_id=student-001",
        headers=auth_headers,
    )
    assert record_resp.status_code == 200
    data = record_resp.json()
    assert data["student_id"] == "student-001"
    assert data["current_streak"] == 1
    assert data["longest_streak"] == 1
    assert data["last_practice_date"] is not None


@pytest.mark.asyncio
async def test_contract_teaching_resource_get_by_id(
    client, auth_headers, create_test_user
):
    """Frontend teaching resource repository calls GET /settings/teaching-resources/{id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/settings/teaching-resources",
        json={
            "type": "youtube",
            "title": "Etude reference",
            "youtube_video_id": "abc123",
            "tags": ["etude", "piano"],
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    resource_id = create_resp.json()["id"]

    get_resp = await client.get(
        f"/api/v1/settings/teaching-resources/{resource_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    data = get_resp.json()
    assert data["id"] == resource_id
    assert data["teacher_id"] == "test-user-id"
    assert data["title"] == "Etude reference"
    assert data["tags"] == ["etude", "piano"]


@pytest.mark.asyncio
async def test_contract_lesson_request_crud(client, auth_headers, student_auth_headers, create_test_user):
    """Frontend calls /schedule/lesson-requests for full CRUD."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id", role="student",
        name="Student", email="student@test.com",
    )

    # Create (as student)
    create_resp = await client.post(
        "/api/v1/schedule/lesson-requests",
        json={
            "teacher_id": "test-user-id",
            "message": "다시 레슨 받고 싶습니다",
            "preferred_timing": "nextWeek",
        },
        headers=student_auth_headers,
    )
    assert create_resp.status_code == 201
    request_id = create_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/schedule/lesson-requests/{request_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200

    # List
    list_resp = await client.get(
        "/api/v1/schedule/lesson-requests?teacher_id=test-user-id",
        headers=auth_headers,
    )
    assert list_resp.status_code == 200

    # Update status (legacy frontend still sends approved; backend canonicalizes to spec status)
    status_resp = await client.patch(
        f"/api/v1/schedule/lesson-requests/{request_id}/status",
        json={"status": "approved"},
        headers=auth_headers,
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "timeConfirmed"
    assert status_resp.json()["events"][-1]["event_type"] == "approve"


# ---------------------------------------------------------------------------
# Relationship contracts
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_contract_lesson_policy_frontend_repository(
    client, auth_headers, create_test_user
):
    """Frontend calls /lesson-policies/* with LessonPolicy JSON field names."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "test-user-id-prof",
            "min_cancel_hours": 6,
            "max_changes_per_month": 3,
            "allow_same_day_cancel": False,
            "late_cancel_deadline": "20:00",
            "deduct_lesson_on_no_show": True,
            "grace_period_minutes": 10,
            "allow_carryover": True,
            "max_carryover_lessons": 2,
            "carryover_period_months": 1,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    created = create_resp.json()
    assert created["teacher_id"] == "test-user-id-prof"
    assert created["min_cancel_hours"] == 6
    assert created["max_changes_per_month"] == 3
    assert created["late_cancel_deadline"] == "20:00"

    teacher_resp = await client.get(
        "/api/v1/lesson-policies/teacher/test-user-id-prof",
        headers=auth_headers,
    )
    assert teacher_resp.status_code == 200
    assert teacher_resp.json()["id"] == created["id"]

    effective_resp = await client.get(
        "/api/v1/lesson-policies/effective?teacher_id=test-user-id-prof",
        headers=auth_headers,
    )
    assert effective_resp.status_code == 200
    assert effective_resp.json()["min_cancel_hours"] == 6

    update_resp = await client.put(
        f"/api/v1/lesson-policies/{created['id']}",
        json={"max_changes_per_month": 4},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["max_changes_per_month"] == 4

    delete_resp = await client.delete(
        f"/api/v1/lesson-policies/{created['id']}",
        headers=auth_headers,
    )
    assert delete_resp.status_code == 204


@pytest.mark.asyncio
async def test_contract_lesson_policy_class_policy_overrides_teacher_default(
    client, auth_headers, create_test_user, db_session
):
    """Class-scoped policy should be persisted and preferred by effective lookup."""
    from app.models.lesson import LessonClass

    await create_test_user(user_id="test-user-id", role="teacher")
    lesson_class = LessonClass(
        id="policy-class-001",
        teacher_id="test-user-id-prof",
        name="Strict Academy Class",
        type="private",
    )
    db_session.add(lesson_class)
    await db_session.flush()

    default_resp = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "test-user-id-prof",
            "min_cancel_hours": 4,
            "max_changes_per_month": 2,
            "allow_same_day_cancel": False,
            "late_cancel_deadline": "20:00",
            "deduct_lesson_on_no_show": True,
            "grace_period_minutes": 15,
            "allow_carryover": True,
            "max_carryover_lessons": 1,
            "carryover_period_months": 1,
        },
        headers=auth_headers,
    )
    assert default_resp.status_code == 201

    class_resp = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "test-user-id-prof",
            "lesson_class_id": "policy-class-001",
            "min_cancel_hours": 24,
            "max_changes_per_month": 1,
            "allow_same_day_cancel": False,
            "late_cancel_deadline": "18:00",
            "deduct_lesson_on_no_show": True,
            "grace_period_minutes": 10,
            "allow_carryover": False,
            "max_carryover_lessons": 0,
            "carryover_period_months": 0,
        },
        headers=auth_headers,
    )
    assert class_resp.status_code == 201
    class_policy = class_resp.json()
    assert class_policy["lesson_class_id"] == "policy-class-001"
    assert class_policy["min_cancel_hours"] == 24
    assert class_policy["max_changes_per_month"] == 1
    assert class_policy["allow_carryover"] is False
    assert class_policy["grace_period_minutes"] == 10

    class_lookup = await client.get(
        "/api/v1/lesson-policies/class/policy-class-001",
        headers=auth_headers,
    )
    assert class_lookup.status_code == 200
    assert class_lookup.json()["id"] == class_policy["id"]

    effective_class = await client.get(
        "/api/v1/lesson-policies/effective?teacher_id=test-user-id-prof&lesson_class_id=policy-class-001",
        headers=auth_headers,
    )
    assert effective_class.status_code == 200
    assert effective_class.json()["id"] == class_policy["id"]
    assert effective_class.json()["min_cancel_hours"] == 24

    effective_default = await client.get(
        "/api/v1/lesson-policies/effective?teacher_id=test-user-id-prof&lesson_class_id=unknown-class",
        headers=auth_headers,
    )
    assert effective_default.status_code == 200
    assert effective_default.json()["id"] == default_resp.json()["id"]


@pytest.mark.asyncio
async def test_lesson_policy_class_policy_requires_owned_class(
    client, create_test_user, db_session
):
    """Teachers cannot create class policies for another teacher's class."""
    from app.models.lesson import LessonClass

    await create_test_user(user_id="teacher-a-id", role="teacher", email="teacher-a-class-policy@test.com")
    await create_test_user(user_id="teacher-b-id", role="teacher", email="teacher-b-class-policy@test.com")
    db_session.add(
        LessonClass(
            id="teacher-b-class",
            teacher_id="teacher-b-id-prof",
            name="Other Teacher Class",
            type="private",
        )
    )
    await db_session.flush()

    teacher_a_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-a-id', 'role': 'teacher'})}"
    }
    response = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "teacher-a-id-prof",
            "lesson_class_id": "teacher-b-class",
            "min_cancel_hours": 24,
        },
        headers=teacher_a_headers,
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_lesson_policy_mutations_are_scoped_to_owning_teacher(
    client, create_test_user
):
    """Teachers cannot create, update, or delete another teacher's policy."""
    await create_test_user(user_id="teacher-a-id", role="teacher", email="teacher-a-policy@test.com")
    await create_test_user(user_id="teacher-b-id", role="teacher", email="teacher-b-policy@test.com")

    teacher_a_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-a-id', 'role': 'teacher'})}"
    }
    teacher_b_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'teacher-b-id', 'role': 'teacher'})}"
    }

    cross_create = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "teacher-b-id-prof",
            "min_cancel_hours": 6,
        },
        headers=teacher_a_headers,
    )
    assert cross_create.status_code == 403

    own_create = await client.post(
        "/api/v1/lesson-policies",
        json={
            "teacher_id": "teacher-b-id-prof",
            "min_cancel_hours": 6,
        },
        headers=teacher_b_headers,
    )
    assert own_create.status_code == 201
    policy_id = own_create.json()["id"]

    cross_update = await client.put(
        f"/api/v1/lesson-policies/{policy_id}",
        json={"max_changes_per_month": 5},
        headers=teacher_a_headers,
    )
    assert cross_update.status_code == 403

    cross_delete = await client.delete(
        f"/api/v1/lesson-policies/{policy_id}",
        headers=teacher_a_headers,
    )
    assert cross_delete.status_code == 403

    still_exists = await client.get(
        "/api/v1/lesson-policies/teacher/teacher-b-id-prof",
        headers=teacher_b_headers,
    )
    assert still_exists.status_code == 200


@pytest.mark.asyncio
async def test_contract_follow_list_and_notification_update(
    client, auth_headers, create_test_user
):
    """Frontend follow repository calls GET /follows and PATCH /follows/{id}."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/follows",
        json={"following_id": "teacher-002", "target_type": "teacher"},
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    follow_id = create_resp.json()["id"]

    list_resp = await client.get("/api/v1/follows", headers=auth_headers)
    assert list_resp.status_code == 200
    data = list_resp.json()
    assert "items" in data
    assert data["items"][0]["id"] == follow_id
    assert data["items"][0]["notification_enabled"] is True

    update_resp = await client.patch(
        f"/api/v1/follows/{follow_id}",
        json={"notification_enabled": False},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["notification_enabled"] is False


@pytest.mark.asyncio
async def test_contract_gamification_badge_award(
    client, auth_headers, create_test_user
):
    """Frontend gamification repository calls POST /gamification/{student_id}/badges."""
    await create_test_user(user_id="test-user-id", role="teacher")

    award_resp = await client.post(
        "/api/v1/gamification/student-001/badges",
        json={
            "badges": [
                {
                    "id": "practice-3-days",
                    "name": "3 day streak",
                    "description": "Practiced for three days",
                    "icon": "fire",
                    "rarity": "rare",
                    "is_earned": True,
                }
            ]
        },
        headers=auth_headers,
    )
    assert award_resp.status_code == 201
    assert award_resp.json()["message"] == "Badges awarded"

    get_resp = await client.get(
        "/api/v1/gamification/student-001",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    badges = get_resp.json()["earned_badges"]
    assert badges[0]["badge_name"] == "3 day streak"
    assert badges[0]["rarity"] == "rare"


@pytest.mark.asyncio
async def test_contract_subscription_settings_flat_crud(
    client, auth_headers, create_test_user
):
    """Frontend calls flat /subscription-settings routes."""
    await create_test_user(user_id="test-user-id", role="teacher")

    create_resp = await client.post(
        "/api/v1/subscription-settings",
        json={
            "teacher_id": "teacher-001",
            "renewal_alert_threshold": 2,
            "renewal_alert_days": 5,
            "discount_policies": [
                {
                    "min_lessons": 10,
                    "type": "bonusLessons",
                    "value": 1,
                    "description": "bonus",
                }
            ],
            "enable_push_notification": True,
            "enable_badge": True,
            "notify_parent": False,
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201
    created = create_resp.json()
    assert created["teacher_id"] == "teacher-001"
    assert created["organization_id"] is None

    teacher_resp = await client.get(
        "/api/v1/subscription-settings/teacher/teacher-001",
        headers=auth_headers,
    )
    assert teacher_resp.status_code == 200
    assert teacher_resp.json()["id"] == created["id"]

    update_resp = await client.put(
        f"/api/v1/subscription-settings/{created['id']}",
        json={"renewal_alert_days": 9, "notify_parent": True},
        headers=auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["renewal_alert_days"] == 9
    assert update_resp.json()["notify_parent"] is True

    org_create_resp = await client.post(
        "/api/v1/subscription-settings",
        json={
            "organization_id": "org-001",
            "renewal_alert_threshold": 1,
            "renewal_alert_days": 7,
            "discount_policies": [],
            "enable_push_notification": True,
            "enable_badge": True,
            "notify_parent": False,
        },
        headers=auth_headers,
    )
    assert org_create_resp.status_code == 201

    org_resp = await client.get(
        "/api/v1/subscription-settings/organization/org-001",
        headers=auth_headers,
    )
    assert org_resp.status_code == 200
    assert org_resp.json()["organization_id"] == "org-001"


@pytest.mark.asyncio
async def test_contract_manual_teacher_crud(
    client, student_auth_headers, create_test_user
):
    """Frontend student home repository calls /manual-teachers CRUD."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        email="student-manual-teacher@test.com",
    )

    create_resp = await client.post(
        "/api/v1/manual-teachers",
        json={
            "id": "manual-001",
            "name": "Offline Teacher",
            "instrument": "piano",
            "phone": "010-1111-2222",
            "notes": "outside app",
            "created_at": "2026-05-01T00:00:00",
            "profile_color_value": 123,
        },
        headers=student_auth_headers,
    )
    assert create_resp.status_code == 201
    assert create_resp.json()["id"] == "manual-001"

    list_resp = await client.get("/api/v1/manual-teachers", headers=student_auth_headers)
    assert list_resp.status_code == 200
    assert list_resp.json()["items"][0]["name"] == "Offline Teacher"

    detail_resp = await client.get(
        "/api/v1/manual-teachers/manual-001",
        headers=student_auth_headers,
    )
    assert detail_resp.status_code == 200
    assert detail_resp.json()["instrument"] == "piano"

    update_resp = await client.put(
        "/api/v1/manual-teachers/manual-001",
        json={"name": "Updated Teacher", "instrument": "violin"},
        headers=student_auth_headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["name"] == "Updated Teacher"
    assert update_resp.json()["instrument"] == "violin"

    delete_resp = await client.delete(
        "/api/v1/manual-teachers/manual-001",
        headers=student_auth_headers,
    )
    assert delete_resp.status_code == 204

    missing_resp = await client.get(
        "/api/v1/manual-teachers/manual-001",
        headers=student_auth_headers,
    )
    assert missing_resp.status_code == 404


@pytest.mark.asyncio
async def test_contract_posts_and_monthly_analytics(
    client, auth_headers, create_test_user
):
    """Frontend feed and analytics repositories call /posts and /analytics/monthly-stats."""
    await create_test_user(user_id="test-user-id", role="teacher")

    posts_resp = await client.get(
        "/api/v1/posts?author_id=teacher-001",
        headers=auth_headers,
    )
    assert posts_resp.status_code == 200
    assert posts_resp.json()["items"] == []

    analytics_resp = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )
    assert analytics_resp.status_code == 200
    data = analytics_resp.json()
    assert data["month"].startswith("2026-05")
    assert data["total_lessons"] == 0
    assert data["lesson_trend"] == [
        {"month": "2025-12-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-01-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-02-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-03-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-04-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-05-01T00:00:00", "lesson_count": 0, "revenue": 0},
    ]
    assert data["practice_ranking"] == []


@pytest.mark.asyncio
async def test_contract_posts_are_persisted_and_filtered(
    client, auth_headers, create_test_user
):
    """Posts should be persisted so follow feed can load teacher/academy announcements."""
    await create_test_user(user_id="test-user-id", role="teacher")

    created = []
    for payload in [
        {
            "author_id": "test-user-id-prof",
            "author_name": "Teacher One",
            "post_type": "notice",
            "title": "Old notice",
            "content": "older",
        },
        {
            "author_id": "test-user-id-prof",
            "author_name": "Teacher One",
            "post_type": "performance",
            "title": "New performance",
            "content": "newer",
        },
        {
            "author_id": "test-user-id",
            "author_name": "Teacher User",
            "post_type": "event",
            "title": "Teacher user event",
            "content": "event",
        },
    ]:
        resp = await client.post("/api/v1/posts", json=payload, headers=auth_headers)
        assert resp.status_code == 201
        created.append(resp.json())

    by_author = await client.get(
        "/api/v1/posts?author_id=test-user-id-prof",
        headers=auth_headers,
    )
    assert by_author.status_code == 200
    items = by_author.json()["items"]
    assert [item["author_id"] for item in items] == ["test-user-id-prof", "test-user-id-prof"]
    assert items[0]["title"] == "New performance"
    assert items[1]["title"] == "Old notice"

    by_authors = await client.get(
        "/api/v1/posts?author_ids=test-user-id-prof,test-user-id",
        headers=auth_headers,
    )
    assert by_authors.status_code == 200
    assert by_authors.json()["total"] == 3
    assert {item["id"] for item in by_authors.json()["items"]} == {
        item["id"] for item in created
    }


@pytest.mark.asyncio
async def test_contract_post_create_rejects_unowned_author(
    client, auth_headers, create_test_user
):
    """Teachers must not create feed posts for an unrelated author_id."""
    await create_test_user(user_id="test-user-id", role="teacher")

    resp = await client.post(
        "/api/v1/posts",
        json={
            "author_id": "other-teacher-prof",
            "author_name": "Other Teacher",
            "post_type": "notice",
            "title": "Invalid",
            "content": "not mine",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_contract_monthly_analytics_aggregates_lessons_and_students(
    client, auth_headers, create_test_user
):
    """Monthly analytics should aggregate teacher lessons and active students."""
    await create_test_user(user_id="test-user-id", role="teacher")

    for payload in [
        {
            "student_id": "student-001",
            "instrument": "piano",
            "date": "2026-05-03",
            "duration": 60,
        },
        {
            "student_id": "student-002",
            "instrument": "violin",
            "date": "2026-05-04",
            "duration": 45,
        },
        {
            "student_id": "student-003",
            "instrument": "cello",
            "date": "2026-05-05",
            "duration": 30,
        },
        {
            "student_id": "student-004",
            "instrument": "piano",
            "date": "2026-04-30",
            "duration": 60,
        },
    ]:
        create_resp = await client.post(
            "/api/v1/lessons",
            json=payload,
            headers=auth_headers,
        )
        assert create_resp.status_code == 201
        lesson_id = create_resp.json()["id"]
        if payload["date"] == "2026-05-03":
            status_payload = {"status": "completed"}
        elif payload["date"] == "2026-05-04":
            status_payload = {"status": "cancelledByStudentLate"}
        elif payload["date"] == "2026-05-05":
            status_payload = {"status": "noShow"}
        else:
            continue
        status_resp = await client.patch(
            f"/api/v1/lessons/{lesson_id}/status",
            json=status_payload,
            headers=auth_headers,
        )
        assert status_resp.status_code == 200

    student_resp = await client.post(
        "/api/v1/students",
        json={"name": "Active Student", "instrument": "piano"},
        headers=auth_headers,
    )
    assert student_resp.status_code == 201

    analytics_resp = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )
    assert analytics_resp.status_code == 200
    data = analytics_resp.json()
    assert data["total_lessons"] == 3
    assert data["completed_lessons"] == 1
    assert data["cancelled_lessons"] == 1
    assert data["no_show_lessons"] == 1
    assert data["attendance_rate"] == pytest.approx(1 / 3)
    assert data["total_students"] == 1
    assert data["lesson_trend"] == [
        {"month": "2025-12-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-01-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-02-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-03-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-04-01T00:00:00", "lesson_count": 1, "revenue": 0},
        {"month": "2026-05-01T00:00:00", "lesson_count": 3, "revenue": 0}
    ]


@pytest.mark.asyncio
async def test_contract_monthly_analytics_aggregates_confirmed_subscription_revenue(
    client, auth_headers, create_test_user, db_session
):
    """Monthly revenue should sum confirmed subscriptions for the current teacher's students."""
    from app.models.student import Student
    from app.models.subscription import Subscription

    await create_test_user(user_id="test-user-id", role="teacher")

    student = Student(
        id="student-revenue-001",
        teacher_id="test-user-id-prof",
        name="Revenue Student",
        instrument="piano",
    )
    other_teacher_student = Student(
        id="student-other-teacher",
        teacher_id="other-teacher-prof",
        name="Other Student",
        instrument="violin",
    )
    db_session.add_all([student, other_teacher_student])
    await db_session.flush()

    db_session.add_all(
        [
            Subscription(
                student_id=student.id,
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=120000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 5, 10, tzinfo=UTC),
            ),
            Subscription(
                student_id=student.id,
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=90000,
                payment_confirmed=False,
                payment_confirmed_at=datetime(2026, 5, 11, tzinfo=UTC),
            ),
            Subscription(
                student_id=student.id,
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=70000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 4, 30, tzinfo=UTC),
            ),
            Subscription(
                student_id=other_teacher_student.id,
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=500000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 5, 12, tzinfo=UTC),
            ),
        ]
    )
    await db_session.flush()

    analytics_resp = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )
    assert analytics_resp.status_code == 200
    data = analytics_resp.json()
    assert data["total_revenue"] == 120000
    assert data["revenue_change_percent"] == pytest.approx(50000 / 70000)
    assert data["lesson_trend"] == [
        {"month": "2025-12-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-01-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-02-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-03-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-04-01T00:00:00", "lesson_count": 0, "revenue": 70000},
        {"month": "2026-05-01T00:00:00", "lesson_count": 0, "revenue": 120000}
    ]


@pytest.mark.asyncio
async def test_contract_monthly_analytics_aggregates_new_and_churned_students(
    client, auth_headers, create_test_user, db_session
):
    """Monthly analytics should count new and inactive students for the teacher."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")

    db_session.add_all(
        [
            Student(
                id="new-student-001",
                teacher_id="test-user-id-prof",
                name="New Student",
                instrument="piano",
                created_at=datetime(2026, 5, 2, tzinfo=UTC),
                updated_at=datetime(2026, 5, 2, tzinfo=UTC),
            ),
            Student(
                id="inactive-student-001",
                teacher_id="test-user-id-prof",
                name="Inactive Student",
                instrument="violin",
                status="inactive",
                created_at=datetime(2026, 4, 2, tzinfo=UTC),
                updated_at=datetime(2026, 5, 3, tzinfo=UTC),
            ),
            Student(
                id="other-teacher-new-student",
                teacher_id="other-teacher-prof",
                name="Other New Student",
                instrument="cello",
                created_at=datetime(2026, 5, 2, tzinfo=UTC),
                updated_at=datetime(2026, 5, 2, tzinfo=UTC),
            ),
        ]
    )
    await db_session.flush()

    analytics_resp = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )
    assert analytics_resp.status_code == 200
    data = analytics_resp.json()
    assert data["new_students"] == 1
    assert data["churned_students"] == 1


@pytest.mark.asyncio
async def test_contract_monthly_analytics_aggregates_practice_ranking(
    client, auth_headers, create_test_user, db_session
):
    """Monthly analytics should rank current teacher's students by practice minutes."""
    from app.models.practice_log import PracticeLog
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")

    db_session.add_all(
        [
            Student(
                id="practice-student-001",
                teacher_id="test-user-id-prof",
                name="High Practice",
                instrument="piano",
            ),
            Student(
                id="practice-student-002",
                teacher_id="test-user-id-prof",
                name="Low Practice",
                instrument="violin",
            ),
            Student(
                id="practice-student-other",
                teacher_id="other-teacher-prof",
                name="Other Teacher Student",
                instrument="cello",
            ),
        ]
    )
    await db_session.flush()

    db_session.add_all(
        [
            PracticeLog(
                student_id="practice-student-001",
                date=date(2026, 5, 1),
                total_minutes=60,
            ),
            PracticeLog(
                student_id="practice-student-001",
                date=date(2026, 5, 2),
                total_minutes=40,
            ),
            PracticeLog(
                student_id="practice-student-002",
                date=date(2026, 5, 1),
                total_minutes=30,
            ),
            PracticeLog(
                student_id="practice-student-001",
                date=date(2026, 4, 30),
                total_minutes=500,
            ),
            PracticeLog(
                student_id="practice-student-other",
                date=date(2026, 5, 1),
                total_minutes=1000,
            ),
        ]
    )
    await db_session.flush()

    analytics_resp = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )
    assert analytics_resp.status_code == 200
    ranking = analytics_resp.json()["practice_ranking"]
    assert ranking == [
        {
            "student_id": "practice-student-001",
            "student_name": "High Practice",
            "instrument": "piano",
            "practice_rate": pytest.approx(2 / 31),
            "practice_minutes": 100,
        },
        {
            "student_id": "practice-student-002",
            "student_name": "Low Practice",
            "instrument": "violin",
            "practice_rate": pytest.approx(1 / 31),
            "practice_minutes": 30,
        },
    ]


@pytest.mark.asyncio
async def test_contract_relationship_get_by_id(client, auth_headers, create_test_user):
    """Frontend calls GET /relationships/{id}."""
    await create_test_user()
    # Create a relationship via invite
    invite_resp = await client.post(
        "/api/v1/relationships/invite",
        json={"student_id": "some-student", "method": "sms"},
        headers=auth_headers,
    )
    assert invite_resp.status_code == 201
    rel_id = invite_resp.json()["id"]

    # Get by ID
    get_resp = await client.get(
        f"/api/v1/relationships/{rel_id}",
        headers=auth_headers,
    )
    assert get_resp.status_code == 200
    data = get_resp.json()
    # Should include extended fields
    assert data["status"] in {"trialBooked", "active", "expired", "past"}
    assert data["updated_at"] is not None
    assert "total_lesson_count" in data
    assert "is_manually_registered" in data
    assert "last_lesson_day" in data
    assert "last_schedule_recorded_at" in data


@pytest.mark.asyncio
async def test_contract_relationship_status_with_metadata(client, auth_headers, create_test_user):
    """Frontend sends extra metadata with status update."""
    await create_test_user()
    invite_resp = await client.post(
        "/api/v1/relationships/invite",
        json={"student_id": "some-student"},
        headers=auth_headers,
    )
    rel_id = invite_resp.json()["id"]

    resp = await client.patch(
        f"/api/v1/relationships/{rel_id}/status",
        json={
            "status": "active",
            "subscription_id": "sub-123",
            "last_lesson_day": 2,
            "last_lesson_time": "14:00",
            "last_lesson_duration": 45,
        },
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["active_subscription_id"] == "sub-123"
    assert data["last_lesson_day"] == 2
    assert data["updated_at"] is not None


@pytest.mark.asyncio
async def test_contract_relationship_schedule_metadata_without_status(
    client, auth_headers, create_test_user
):
    """Frontend recordSchedule patches schedule fields without a status value."""
    await create_test_user()
    invite_resp = await client.post(
        "/api/v1/relationships/invite",
        json={"student_id": "some-student"},
        headers=auth_headers,
    )
    rel_id = invite_resp.json()["id"]

    resp = await client.patch(
        f"/api/v1/relationships/{rel_id}/status",
        json={
            "last_lesson_day": "2",
            "last_lesson_time": "15:00",
            "last_lesson_duration": 60,
        },
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "trialBooked"
    assert data["last_lesson_day"] == 2
    assert data["last_lesson_time"] == "15:00"
    assert data["last_schedule_recorded_at"] is not None
