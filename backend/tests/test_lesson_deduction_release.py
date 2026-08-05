"""완료 되돌림 시 수강권 차감 해제 (#1240).

차감은 증가만 있고 반전이 없어, 오탭으로 완료 처리한 레슨을 되돌려도 학생의
회차가 영구히 소모됐다. 차감 상태 -> 비차감 상태 전이는 그 레슨이 만든
usage 를 해제해야 한다.
"""

import pytest
from httpx import AsyncClient


async def _lesson(client: AsyncClient, auth_headers: dict, sid: str, sub_id: str, **extra) -> str:
    payload = {
        "student_id": sid,
        "date": extra.pop("date", "2026-08-10"),
        "start_time": extra.pop("start_time", "10:00"),
        "duration": 60,
        "subscription_id": sub_id,
        **extra,
    }
    r = await client.post("/api/v1/lessons", headers=auth_headers, json=payload)
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _used(client: AsyncClient, auth_headers: dict, sub_id: str) -> int:
    r = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert r.status_code == 200, r.text
    return r.json()["used_lessons"]


async def _set_status(client: AsyncClient, auth_headers: dict, lesson_id: str, status: str):
    r = await client.patch(
        f"/api/v1/lessons/{lesson_id}/status",
        headers=auth_headers,
        json={"status": status},
    )
    assert r.status_code == 200, r.text
    return r.json()


@pytest.mark.asyncio
async def test_reverting_completed_releases_the_deduction(teacher, client: AsyncClient, auth_headers: dict):
    sid = await teacher.create_student("되돌림학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lid = await _lesson(client, auth_headers, sid, sub_id)

    await _set_status(client, auth_headers, lid, "completed")
    assert await _used(client, auth_headers, sub_id) == 1

    await _set_status(client, auth_headers, lid, "scheduled")
    assert await _used(client, auth_headers, sub_id) == 0, "오탭 복구는 회차를 되돌려줘야 한다"


@pytest.mark.asyncio
async def test_release_then_recomplete_deducts_once(teacher, client: AsyncClient, auth_headers: dict):
    """해제 후 다시 완료하면 정확히 1회 — 해제가 멱등 가드를 망가뜨리지 않는다."""
    sid = await teacher.create_student("재완료학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lid = await _lesson(client, auth_headers, sid, sub_id, start_time="11:00")

    await _set_status(client, auth_headers, lid, "completed")
    await _set_status(client, auth_headers, lid, "scheduled")
    await _set_status(client, auth_headers, lid, "completed")

    assert await _used(client, auth_headers, sub_id) == 1


@pytest.mark.asyncio
async def test_teacher_cancel_after_completion_releases(teacher, client: AsyncClient, auth_headers: dict):
    """휴강(cancelledByTeacher)은 차감 없는 상태 — 완료에서 넘어오면 해제된다."""
    sid = await teacher.create_student("휴강전환학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lid = await _lesson(client, auth_headers, sid, sub_id, start_time="12:00")

    await _set_status(client, auth_headers, lid, "completed")
    await _set_status(client, auth_headers, lid, "cancelledByTeacher")

    assert await _used(client, auth_headers, sub_id) == 0


@pytest.mark.asyncio
async def test_release_never_goes_below_zero(teacher, client: AsyncClient, auth_headers: dict):
    """차감된 적 없는 레슨을 되돌려도 카운터가 음수로 내려가지 않는다."""
    sid = await teacher.create_student("음수방지학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    lid = await _lesson(client, auth_headers, sid, sub_id, start_time="13:00")

    await _set_status(client, auth_headers, lid, "cancelledByTeacher")
    await _set_status(client, auth_headers, lid, "scheduled")

    assert await _used(client, auth_headers, sub_id) == 0


@pytest.mark.asyncio
async def test_release_does_not_touch_other_lessons_usage(teacher, client: AsyncClient, auth_headers: dict):
    """해제는 해당 레슨의 usage 만 건드린다 — 형제 레슨 차감은 보존."""
    sid = await teacher.create_student("형제보존학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    keep = await _lesson(client, auth_headers, sid, sub_id, start_time="14:00")
    revert = await _lesson(client, auth_headers, sid, sub_id, start_time="15:00")

    await _set_status(client, auth_headers, keep, "completed")
    await _set_status(client, auth_headers, revert, "completed")
    assert await _used(client, auth_headers, sub_id) == 2

    await _set_status(client, auth_headers, revert, "scheduled")
    assert await _used(client, auth_headers, sub_id) == 1, "형제 레슨의 차감은 유지돼야 한다"
