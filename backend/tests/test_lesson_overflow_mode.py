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


async def _grant_credit(
    client: AsyncClient, auth_headers: dict, sid: str, *, source_subscription_id: str | None = None
) -> str:
    r = await client.post(
        "/api/v1/teachers/me/makeup-credits",
        headers=auth_headers,
        json={"student_id": sid, "source_subscription_id": source_subscription_id},
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _list_credits(client: AsyncClient, auth_headers: dict, sid: str) -> list[dict]:
    r = await client.get(
        "/api/v1/teachers/me/makeup-credits",
        headers=auth_headers,
        params={"student_id": sid},
    )
    assert r.status_code == 200, r.text
    return r.json()["credits"]


@pytest.mark.asyncio
async def test_makeup_credit_mode_consumes_credit_any_remaining(teacher, client: AsyncClient, auth_headers: dict):
    """S4 — 잔여 무관 크레딧 소비: 정규 카운터 불변 + 회차 미부여 + 크레딧 used 연결 (§5.4)."""
    sid = await teacher.create_student("보강소비학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    credit_id = await _grant_credit(client, auth_headers, sid)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-16",
        start_time="10:00",
        subscription_id=sub_id,
        overflow_mode="makeup_credit",
    )
    assert r.status_code == 201, r.text
    lesson = r.json()
    assert lesson["subscription_id"] == sub_id
    assert lesson["session_number"] is None
    assert lesson["is_preview"] is False

    sub = await _get_subscription(client, auth_headers, sub_id)
    assert sub["total_lessons"] == 10
    assert sub["used_lessons"] == 0
    assert sub["bonus_count"] == 0

    credits = await _list_credits(client, auth_headers, sid)
    used = [c for c in credits if c["id"] == credit_id][0]
    assert used["used_lesson_id"] == lesson["id"]


@pytest.mark.asyncio
async def test_makeup_credit_completion_skips_regular_deduction(teacher, client: AsyncClient, auth_headers: dict):
    """§5.3 — 크레딧 레슨 완료는 정규 used_lessons 를 차감하지 않는다."""
    sid = await teacher.create_student("보강완료학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    await _grant_credit(client, auth_headers, sid)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-16",
        start_time="12:00",
        subscription_id=sub_id,
        overflow_mode="makeup_credit",
    )
    assert r.status_code == 201, r.text
    await teacher.complete_lesson(r.json()["id"])

    sub = await _get_subscription(client, auth_headers, sub_id)
    assert sub["used_lessons"] == 0, "credit-funded lesson must not deduct the regular counter"


@pytest.mark.asyncio
async def test_makeup_credit_mode_without_credit_rejected(teacher, client: AsyncClient, auth_headers: dict):
    sid = await teacher.create_student("크레딧없음학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-16",
        start_time="14:00",
        subscription_id=sub_id,
        overflow_mode="makeup_credit",
    )
    assert r.status_code == 422, r.text


@pytest.mark.asyncio
async def test_makeup_credit_attaches_to_source_subscription(teacher, client: AsyncClient, auth_headers: dict):
    """§5.4 — subscription_id 미지정 시 크레딧의 source 수강권에 우선 귀속."""
    sid = await teacher.create_student("보강귀속학생")
    old_sub = await teacher.create_subscription(sid, total_lessons=1, amount=100000)
    await _exhaust_single_lesson_subscription(teacher, client, auth_headers, sid, old_sub)
    new_sub = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    await _grant_credit(client, auth_headers, sid, source_subscription_id=old_sub)

    r = await _create_lesson(
        client,
        auth_headers,
        sid,
        date="2026-08-16",
        start_time="16:00",
        overflow_mode="makeup_credit",
    )
    assert r.status_code == 201, r.text
    assert r.json()["subscription_id"] == old_sub, (
        f"expected credit source {old_sub}, got {r.json()['subscription_id']} (latest active={new_sub})"
    )


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
async def test_preview_lesson_skips_student_notification(
    teacher, client: AsyncClient, auth_headers: dict, create_test_user, db_session
):
    """미리보기 레슨은 '새 레슨 등록' 알림을 보내지 않는다 — 갱신 제안 알림이 별도 채널.

    user 연결 학생(알림 수신 가능 상태)으로 만들어 놓고, 일반 레슨은 알림이
    발생하고 preview 레슨은 발생하지 않음을 카운트로 고정한다.
    """
    from sqlalchemy import func, select

    from app.models.notification import Notification
    from app.models.student import Student

    sid = await teacher.create_student("알림검증학생")
    student_user = await create_test_user(
        user_id="notif-target-user", role="student", name="알림검증학생", email="notif-target@test.com"
    )
    row = await db_session.get(Student, sid)
    row.user_id = student_user.id
    await db_session.flush()

    sub_id = await teacher.create_subscription(sid, total_lessons=2, amount=100000)

    # 일반 레슨 → lessonBooked 알림 1건 (알림 경로 자체가 살아있음을 고정)
    r = await _create_lesson(
        client, auth_headers, sid,
        date="2026-08-17", start_time="10:00", subscription_id=sub_id,
    )
    assert r.status_code == 201, r.text
    baseline = await db_session.scalar(select(func.count(Notification.id)))
    assert baseline and baseline >= 1

    # 잔여 소진 후 preview 레슨 → 알림 카운트 불변
    await teacher.complete_lesson(r.json()["id"])
    r2 = await _create_lesson(
        client, auth_headers, sid,
        date="2026-08-18", start_time="14:00", subscription_id=sub_id,
    )
    assert r2.status_code == 201, r2.text
    await teacher.complete_lesson(r2.json()["id"])
    before_preview = await db_session.scalar(select(func.count(Notification.id)))

    r3 = await _create_lesson(
        client, auth_headers, sid,
        date="2026-08-19", start_time="14:00",
        subscription_id=sub_id, overflow_mode="renewal_pending",
    )
    assert r3.status_code == 201, r3.text
    assert r3.json()["is_preview"] is True

    after_preview = await db_session.scalar(select(func.count(Notification.id)))
    assert after_preview == before_preview, "preview 레슨은 lessonBooked 알림을 보내지 않는다"
