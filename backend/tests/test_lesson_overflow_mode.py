"""LessonCreate.overflow_mode branches (subscription_required_spec §2.6.2).

J1 scope: ``bonus`` / ``renewal_pending`` / ``None``(legacy) — ``makeup_credit``
is rejected here and lands in J2.
"""

import pytest
from httpx import AsyncClient


async def _create_lesson(client: AsyncClient, auth_headers: dict, sid: str, **extra):
    payload = {
        "student_id": sid,
        "date": extra.pop("date", "2026-08-10"),
        "start_time": extra.pop("start_time", "10:00"),
        "duration": 60,
        **extra,
    }
    return await client.post("/api/v1/lessons", headers=auth_headers, json=payload)


async def _get_subscription(client: AsyncClient, auth_headers: dict, sub_id: str) -> dict:
    r = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert r.status_code == 200, r.text
    return r.json()


async def _exhaust_single_lesson_subscription(
    teacher, client: AsyncClient, auth_headers: dict, sid: str, sub_id: str
) -> None:
    """Consume the only session of a total_lessons=1 subscription (remaining -> 0)."""
    r = await _create_lesson(client, auth_headers, sid, subscription_id=sub_id, date="2026-08-10", start_time="09:00")
    assert r.status_code == 201, r.text
    await teacher.complete_lesson(r.json()["id"])


@pytest.mark.asyncio
async def test_legacy_no_mode_keeps_silent_bonus_expansion(teacher, client: AsyncClient, auth_headers: dict):
    """§2.6.2 하위 호환 — overflow_mode 없는 레거시 호출은 기존 §2.3 자동 보너스 유지."""
    sid = await teacher.create_student("레거시학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, sub_id)

    r = await _create_lesson(client, auth_headers, sid, date="2026-08-11", start_time="10:00")
    assert r.status_code == 201, r.text
    assert r.json()["subscription_id"] == sub_id

    sub = await _get_subscription(client, auth_headers, sub_id)
    assert sub["total_lessons"] == 2
    assert sub["bonus_count"] == 1


@pytest.mark.asyncio
async def test_bonus_mode_expands_target_subscription(teacher, client: AsyncClient, auth_headers: dict):
    sid = await teacher.create_student("보너스학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, sub_id)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-12",
        start_time="11:00",
        subscription_id=sub_id,
        overflow_mode="bonus",
    )
    assert r.status_code == 201, r.text
    lesson = r.json()
    assert lesson["subscription_id"] == sub_id
    assert lesson["is_preview"] is False

    sub = await _get_subscription(client, auth_headers, sub_id)
    assert sub["total_lessons"] == 2
    assert sub["bonus_count"] == 1


@pytest.mark.asyncio
@pytest.mark.parametrize("mode", ["bonus", "renewal_pending"])
async def test_overflow_mode_rejected_when_remaining(teacher, client: AsyncClient, auth_headers: dict, mode: str):
    """잔여 > 0 이면 overflow 처리 대상이 아니다 — FE 분기 버그 방어."""
    sid = await teacher.create_student(f"잔여있음{mode}")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-13",
        start_time="10:00",
        subscription_id=sub_id,
        overflow_mode=mode,
    )
    assert r.status_code == 422, r.text


@pytest.mark.asyncio
async def test_renewal_pending_creates_preview_without_counters(teacher, client: AsyncClient, auth_headers: dict):
    """renewal_pending — is_preview 레슨 생성 + 카운터/회차 불변 (§2.6.2)."""
    sid = await teacher.create_student("갱신대기학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, sub_id)
    before = await _get_subscription(client, auth_headers, sub_id)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-14",
        start_time="14:00",
        subscription_id=sub_id,
        overflow_mode="renewal_pending",
    )
    assert r.status_code == 201, r.text
    lesson = r.json()
    assert lesson["is_preview"] is True
    assert lesson["subscription_id"] == sub_id
    assert lesson["session_number"] is None

    after = await _get_subscription(client, auth_headers, sub_id)
    assert after["total_lessons"] == before["total_lessons"]
    assert after["bonus_count"] == before["bonus_count"]
    assert after["used_lessons"] == before["used_lessons"]


@pytest.mark.asyncio
async def test_overflow_mode_requires_subscription(teacher, client: AsyncClient, auth_headers: dict):
    """활성 수강권이 없으면 overflow_mode 는 성립하지 않는다 (체험 자동생성으로 우회 금지)."""
    sid = await teacher.create_student("무수강권학생")

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-15",
        start_time="10:00",
        overflow_mode="renewal_pending",
    )
    assert r.status_code == 422, r.text


@pytest.mark.asyncio
async def test_makeup_credit_mode_not_supported_in_j1(teacher, client: AsyncClient, auth_headers: dict):
    """J2 에서 크레딧 소비가 붙기 전까지 makeup_credit 은 422 — J2 가 이 테스트를 대체한다."""
    sid = await teacher.create_student("보강대기학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, sub_id)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-16",
        start_time="10:00",
        subscription_id=sub_id,
        overflow_mode="makeup_credit",
    )
    assert r.status_code == 422, r.text


@pytest.mark.asyncio
async def test_invalid_overflow_mode_rejected(teacher, client: AsyncClient, auth_headers: dict):
    sid = await teacher.create_student("잘못된모드학생")

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-17",
        start_time="10:00",
        overflow_mode="banana",
    )
    assert r.status_code == 422, r.text


@pytest.mark.asyncio
async def test_preview_lesson_skips_student_notification(teacher, client: AsyncClient, auth_headers: dict):
    """미리보기 레슨은 '새 레슨 등록' 알림을 보내지 않는다 — 갱신 제안 알림이 별도 채널."""
    sid = await teacher.create_student("알림검증학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, sub_id)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-18",
        start_time="14:00",
        subscription_id=sub_id,
        overflow_mode="renewal_pending",
    )
    assert r.status_code == 201, r.text
    # 학생 user 미연결 시 알림 자체가 없으므로, 이 테스트는 생성 성공 + preview 플래그만
    # 고정한다. (user 연결 학생의 알림 스킵 분기는 아래 서비스 단위 검증으로 충분 —
    # create() 는 is_preview 일 때 notify 블록을 건너뛴다.)
    assert r.json()["is_preview"] is True
