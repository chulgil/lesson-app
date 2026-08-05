"""Lesson write-path contract (#1236 / #1237 / #1238).

The FE historically PUT the whole Lesson entity, so unsupported fields
(status / feedback / key_points / practice_tips) were silently dropped with a
200 OK. These tests pin the dedicated endpoints as the only write paths and
keep the whitelist honest.
"""

import pytest
from httpx import AsyncClient


async def _create_lesson(client: AsyncClient, auth_headers: dict, sid: str, **extra) -> dict:
    payload = {
        "student_id": sid,
        "date": extra.pop("date", "2026-08-10"),
        "start_time": extra.pop("start_time", "10:00"),
        "duration": 60,
        **extra,
    }
    r = await client.post("/api/v1/lessons", headers=auth_headers, json=payload)
    assert r.status_code == 201, r.text
    return r.json()


async def _get_lesson(client: AsyncClient, auth_headers: dict, lesson_id: str) -> dict:
    r = await client.get(f"/api/v1/lessons/{lesson_id}", headers=auth_headers)
    assert r.status_code == 200, r.text
    return r.json()


@pytest.mark.asyncio
async def test_feedback_endpoint_persists_key_points(teacher, client: AsyncClient, auth_headers: dict):
    """key_points 는 LessonFeedbackUpdate 에 있으나 저장되지 않았다 (#1236)."""
    sid = await teacher.create_student("피드백저장학생")
    lesson = await _create_lesson(client, auth_headers, sid)

    r = await client.put(
        f"/api/v1/lessons/{lesson['id']}/feedback",
        headers=auth_headers,
        json={
            "feedback": "활 사용이 좋아졌어요",
            "key_points": ["보잉", "음정"],
            "practice_tips": "매일 10분 스케일",
        },
    )
    assert r.status_code == 200, r.text

    saved = await _get_lesson(client, auth_headers, lesson["id"])
    assert saved["feedback"] == "활 사용이 좋아졌어요"
    assert saved["practice_tips"] == "매일 10분 스케일"
    assert saved["key_points"] == ["보잉", "음정"], "key_points must persist via the feedback endpoint"


@pytest.mark.asyncio
async def test_feedback_endpoint_clears_key_points_with_empty_list(teacher, client: AsyncClient, auth_headers: dict):
    """빈 배열은 '전체 삭제' 의도 — 이전 값이 남으면 지울 방법이 없다."""
    sid = await teacher.create_student("키포인트삭제학생")
    lesson = await _create_lesson(client, auth_headers, sid, start_time="11:00")

    await client.put(
        f"/api/v1/lessons/{lesson['id']}/feedback",
        headers=auth_headers,
        json={"key_points": ["보잉"]},
    )
    r = await client.put(
        f"/api/v1/lessons/{lesson['id']}/feedback",
        headers=auth_headers,
        json={"key_points": []},
    )
    assert r.status_code == 200, r.text

    saved = await _get_lesson(client, auth_headers, lesson["id"])
    assert saved["key_points"] == []


@pytest.mark.asyncio
async def test_put_lesson_rejects_unsupported_fields(teacher, client: AsyncClient, auth_headers: dict):
    """#1238 — 미지원 필드는 무언 폐기 대신 422 로 거절한다 (전용 엔드포인트 강제)."""
    sid = await teacher.create_student("화이트리스트학생")
    lesson = await _create_lesson(client, auth_headers, sid, start_time="12:00")

    body = dict(lesson)  # entity-wide PUT — the legacy FE pattern
    body["status"] = "completed"
    r = await client.put(f"/api/v1/lessons/{lesson['id']}", headers=auth_headers, json=body)
    assert r.status_code == 422, "entity-wide PUT must fail loudly, not silently drop fields"

    still = await _get_lesson(client, auth_headers, lesson["id"])
    assert still["status"] == "scheduled"


@pytest.mark.asyncio
async def test_put_lesson_accepts_supported_fields(teacher, client: AsyncClient, auth_headers: dict):
    """화이트리스트 안의 필드만 담은 정상 편집은 계속 통과한다 (회귀 가드)."""
    sid = await teacher.create_student("정상편집학생")
    lesson = await _create_lesson(client, auth_headers, sid, start_time="13:00")

    r = await client.put(
        f"/api/v1/lessons/{lesson['id']}",
        headers=auth_headers,
        json={"date": "2026-08-11", "start_time": "15:30", "duration": 90},
    )
    assert r.status_code == 200, r.text

    saved = await _get_lesson(client, auth_headers, lesson["id"])
    assert saved["date"] == "2026-08-11"
    assert saved["start_time"] == "15:30"
    assert saved["duration"] == 90


@pytest.mark.asyncio
async def test_status_endpoint_is_the_only_transition_path(teacher, client: AsyncClient, auth_headers: dict):
    """#1237 — 상태 전이는 PATCH /status 로만. 완료 시 수강권 차감까지 수행."""
    sid = await teacher.create_student("상태전이학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lesson = await _create_lesson(client, auth_headers, sid, start_time="14:00", subscription_id=sub_id)

    r = await client.patch(
        f"/api/v1/lessons/{lesson['id']}/status",
        headers=auth_headers,
        json={"status": "completed"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "completed"

    sub = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub.json()["used_lessons"] == 1, "completion via the status endpoint deducts one session"


@pytest.mark.asyncio
async def test_completion_plus_manual_usage_double_deducts(teacher, client: AsyncClient, auth_headers: dict):
    """왜 FE 가 완료 후 usage 를 또 기록하면 안 되는지 고정 (#1237).

    BE 완료 차감은 lesson_id 기준 멱등이지만, ``POST /subscriptions/{id}/usages``
    는 멱등 가드가 없어 같은 레슨에 두 번째 차감이 쌓인다 — 완료 차감의 SSOT 는
    상태 전이 엔드포인트 하나뿐이다.
    """
    sid = await teacher.create_student("이중차감학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lesson = await _create_lesson(client, auth_headers, sid, start_time="16:00", subscription_id=sub_id)

    await client.patch(
        f"/api/v1/lessons/{lesson['id']}/status",
        headers=auth_headers,
        json={"status": "completed"},
    )
    after_completion = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert after_completion.json()["used_lessons"] == 1

    r = await client.post(
        f"/api/v1/subscriptions/{sub_id}/usage",
        headers=auth_headers,
        json={"lesson_id": lesson["id"], "type": "lesson", "deducted": True},
    )
    assert r.status_code in (200, 201), r.text

    after_manual = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert after_manual.json()["used_lessons"] == 2, (
        "manual usage after completion double-deducts — the client must not do both"
    )
