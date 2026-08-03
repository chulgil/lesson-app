"""Tests for auto subscription creation when creating lessons without subscription_id."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_lesson_without_subscription_creates_trial(teacher, client: AsyncClient, auth_headers: dict):
    """Creating a lesson without subscription_id should auto-create a trial subscription."""
    sid = await teacher.create_student("김테스트")

    # Create lesson with no subscription_id
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-06-01", "start_time": "14:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()

    # Lesson must be linked to a subscription
    assert lesson["subscription_id"] is not None, "Expected auto-created subscription_id"
    assert lesson["session_number"] is not None, "Expected session_number from auto subscription"


@pytest.mark.asyncio
async def test_create_lesson_reuses_active_subscription(teacher, client: AsyncClient, auth_headers: dict):
    """Creating a lesson without subscription_id should reuse existing active subscription."""
    sid = await teacher.create_student("박재사용")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)

    # Create lesson with no subscription_id
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-06-01", "start_time": "10:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()

    # Should reuse the existing active subscription
    assert lesson["subscription_id"] == sub_id, (
        f"Expected existing subscription {sub_id}, got {lesson['subscription_id']}"
    )


@pytest.mark.asyncio
async def test_trial_subscription_has_correct_defaults(teacher, client: AsyncClient, auth_headers: dict):
    """Auto-created trial subscription should have correct field values."""
    sid = await teacher.create_student("이기본값")

    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": "2026-07-15", "start_time": "11:00", "duration": 60},
    )
    assert r.status_code == 201, f"create_lesson failed: {r.status_code} {r.text}"
    lesson = r.json()
    sub_id = lesson["subscription_id"]
    assert sub_id is not None

    # Fetch the subscription and verify defaults
    r = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert r.status_code == 200, f"get_subscription failed: {r.status_code} {r.text}"
    sub = r.json()

    assert sub["type"] == "trial"
    assert sub["amount"] == 0
    assert sub["total_lessons"] == 1
    assert sub["payment_confirmed"] is True
    assert sub["total_reschedule_allowance"] == 0
    assert sub["status"] == "active"


async def _make_lesson(client: AsyncClient, auth_headers: dict, sid: str, date: str) -> "object":
    return await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={"student_id": sid, "date": date, "start_time": "10:00", "duration": 60},
    )


@pytest.mark.asyncio
async def test_connected_student_cannot_regenerate_auto_trial(
    teacher, client: AsyncClient, auth_headers: dict, db_session
):
    """§2.6.5 (D2) — 앱 연결 학생의 자동 체험권은 1회만. 재생성 시 trial_already_used."""
    import datetime as _dt

    from app.models.student import Student
    from app.models.subscription import Subscription, SubscriptionStatus

    sid = await teacher.create_student("가드연결학생")
    student = await db_session.get(Student, sid)
    student.connected_at = _dt.datetime.now(_dt.UTC)
    await db_session.flush()

    # 첫 자동 체험권은 가드 대상이 아니다.
    r1 = await _make_lesson(client, auth_headers, sid, "2026-08-20")
    assert r1.status_code == 201, r1.text
    trial_id = r1.json()["subscription_id"]

    # 30일 만료를 시뮬레이트 — 자동 경로가 새 체험권을 만들려는 상태.
    sub = await db_session.get(Subscription, trial_id)
    sub.status = SubscriptionStatus.expired
    await db_session.flush()

    r2 = await _make_lesson(client, auth_headers, sid, "2026-08-21")
    assert r2.status_code == 422, r2.text
    assert r2.json()["detail"] == "trial_already_used"


@pytest.mark.asyncio
async def test_unconnected_student_can_regenerate_auto_trial(
    teacher, client: AsyncClient, auth_headers: dict, db_session
):
    """§2.7 (D4) — 미가입(수기) 학생은 체험권 재생성 무제한 (스케줄 관리 경량 사용 보호)."""
    from app.models.subscription import Subscription, SubscriptionStatus

    sid = await teacher.create_student("가드미가입학생")

    r1 = await _make_lesson(client, auth_headers, sid, "2026-08-22")
    assert r1.status_code == 201, r1.text
    first_trial = r1.json()["subscription_id"]

    sub = await db_session.get(Subscription, first_trial)
    sub.status = SubscriptionStatus.expired
    await db_session.flush()

    r2 = await _make_lesson(client, auth_headers, sid, "2026-08-23")
    assert r2.status_code == 201, r2.text
    assert r2.json()["subscription_id"] != first_trial
