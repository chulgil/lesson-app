"""취소 마감시간 서버 판정 (#1241).

`LessonPolicy.cancellation_deadline_hours` 는 저장만 되고 어떤 경로에서도
집행되지 않았다 — 지각 취소 여부는 선생님이 다이얼로그에서 고르는 값이라
설정이 아무 효과가 없었다. 타이밍 판정의 최종 권위는 서버이며, 클라이언트는
같은 값을 힌트로 미리 보여준다.
"""

from datetime import date, datetime, timedelta, timezone

import pytest
from app.services.cancellation_policy import resolve_cancel_timing
from httpx import AsyncClient

KST = timezone(timedelta(hours=9))


def _kst(y: int, m: int, d: int, hh: int, mm: int = 0) -> datetime:
    return datetime(y, m, d, hh, mm, tzinfo=KST)


class TestResolveCancelTiming:
    """순수 판정 함수 — 경계값을 여기서 고정한다."""

    def test_well_before_deadline_is_advance(self):
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=24,
                at=_kst(2026, 8, 8, 9),
            )
            is False
        )

    def test_after_deadline_is_late(self):
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=24,
                at=_kst(2026, 8, 10, 9),
            )
            is True
        )

    def test_exactly_at_deadline_is_not_late(self):
        """마감 '시각까지' 는 세이프 — 경계는 사용자에게 유리하게."""
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=24,
                at=_kst(2026, 8, 9, 14),
            )
            is False
        )

    def test_one_minute_past_deadline_is_late(self):
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=24,
                at=_kst(2026, 8, 9, 14, 1),
            )
            is True
        )

    def test_zero_deadline_means_only_after_start_is_late(self):
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=0,
                at=_kst(2026, 8, 10, 13, 59),
            )
            is False
        )
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="14:00",
                deadline_hours=0,
                at=_kst(2026, 8, 10, 14, 1),
            )
            is True
        )

    def test_unparseable_start_time_is_not_late(self):
        """판정 불가 시 페널티 없음 — 애매하면 학생에게 유리하게."""
        assert (
            resolve_cancel_timing(
                lesson_date=date(2026, 8, 10),
                start_time="bogus",
                deadline_hours=24,
                at=_kst(2026, 8, 10, 9),
            )
            is False
        )


async def _create_lesson(client: AsyncClient, auth_headers: dict, sid: str, sub_id: str, when: date, hhmm: str) -> str:
    r = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": sid,
            "date": when.isoformat(),
            "start_time": hhmm,
            "duration": 60,
            "subscription_id": sub_id,
        },
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _set_policy(client: AsyncClient, auth_headers: dict, **fields):
    """교사 기본 정책 생성 — late_cancel_deducts_lesson 은 모델 기본값 True."""
    r = await client.post("/api/v1/lesson-policies", headers=auth_headers, json=fields)
    assert r.status_code in (200, 201), r.text
    return r.json()


@pytest.mark.asyncio
async def test_server_upgrades_advance_cancel_past_deadline(teacher, client: AsyncClient, auth_headers: dict):
    """클라이언트가 사전 취소라고 주장해도 마감을 넘겼으면 서버가 지각으로 확정."""
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("마감초과학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    today = datetime.now(KST).date()
    lid = await _create_lesson(client, auth_headers, sid, sub_id, today, "23:59")

    r = await client.patch(
        f"/api/v1/lessons/{lid}/status",
        headers=auth_headers,
        json={"status": "cancelledByStudentAdvance"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "cancelledByStudentLate", "마감 초과 취소는 서버가 지각으로 확정한다"

    sub = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub.json()["used_lessons"] == 1, "지각 확정이면 정책 차감까지 이어져야 한다"


@pytest.mark.asyncio
async def test_server_downgrades_late_cancel_before_deadline(teacher, client: AsyncClient, auth_headers: dict):
    """마감 전 취소를 지각으로 보내도 서버가 사전 취소로 정정 — 차감 없음."""
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("마감이전학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    far = datetime.now(KST).date() + timedelta(days=10)
    lid = await _create_lesson(client, auth_headers, sid, sub_id, far, "10:00")

    r = await client.patch(
        f"/api/v1/lessons/{lid}/status",
        headers=auth_headers,
        json={"status": "cancelledByStudentLate"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "cancelledByStudentAdvance"

    sub = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub.json()["used_lessons"] == 0


@pytest.mark.asyncio
async def test_non_timing_statuses_are_untouched(teacher, client: AsyncClient, auth_headers: dict):
    """노쇼·선생님 취소는 '누가/무엇' 판단이라 서버가 타이밍으로 바꾸지 않는다."""
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("무관상태학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    far = datetime.now(KST).date() + timedelta(days=10)

    for hour, status_value in enumerate(("noShow", "cancelledByTeacher", "cancelledMutual"), start=9):
        lid = await _create_lesson(client, auth_headers, sid, sub_id, far, f"{hour:02d}:00")
        r = await client.patch(
            f"/api/v1/lessons/{lid}/status",
            headers=auth_headers,
            json={"status": status_value},
        )
        assert r.status_code == 200, r.text
        assert r.json()["status"] == status_value


@pytest.mark.asyncio
async def test_no_policy_keeps_client_choice(teacher, client: AsyncClient, auth_headers: dict):
    """정책 미설정 교사는 기존 동작 유지 — 서버가 임의로 페널티를 만들지 않는다."""
    sid = await teacher.create_student("정책없음학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    today = datetime.now(KST).date()
    lid = await _create_lesson(client, auth_headers, sid, sub_id, today, "23:59")

    r = await client.patch(
        f"/api/v1/lessons/{lid}/status",
        headers=auth_headers,
        json={"status": "cancelledByStudentAdvance"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "cancelledByStudentAdvance"


@pytest.mark.asyncio
async def test_subscription_override_wins_over_policy(teacher, client: AsyncClient, auth_headers: dict):
    """수강권 개별 override 가 교사 기본 정책보다 우선한다."""
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("오버라이드학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    r = await client.patch(
        f"/api/v1/subscriptions/{sub_id}/cancel-deadline",
        headers=auth_headers,
        json={"override_cancel_deadline_hours": 0},
    )
    assert r.status_code == 200, r.text

    # 마감 0시간 = 레슨 시작 전까지 사전 취소 → 오늘 늦은 레슨도 승격되지 않는다.
    today = datetime.now(KST).date()
    lid = await _create_lesson(client, auth_headers, sid, sub_id, today, "23:59")
    rr = await client.patch(
        f"/api/v1/lessons/{lid}/status",
        headers=auth_headers,
        json={"status": "cancelledByStudentAdvance"},
    )
    assert rr.status_code == 200, rr.text
    assert rr.json()["status"] == "cancelledByStudentAdvance"


@pytest.mark.asyncio
async def test_cancellation_policy_endpoint_feeds_the_client_hint(teacher, client: AsyncClient, auth_headers: dict):
    """FE 힌트용 — 서버와 같은 값을 미리 보여줄 수 있어야 한다."""
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("힌트학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    today = datetime.now(KST).date()
    lid = await _create_lesson(client, auth_headers, sid, sub_id, today, "23:59")

    r = await client.get(f"/api/v1/lessons/{lid}/cancellation-policy", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["deadline_hours"] == 24
    assert body["is_late_now"] is True
    assert body["deadline_at"] is not None
    assert body["source"] == "policy"


@pytest.mark.asyncio
async def test_past_lesson_keeps_teacher_record(teacher, client: AsyncClient, auth_headers: dict):
    """소급 기록은 서버가 판정하지 않는다 — 취소 시점을 알 수 없기 때문.

    이미 지난 레슨을 나중에 정리할 때 "지금" 은 학생이 통보한 시각이 아니다.
    증거가 없으면 선생님의 기록이 최종 — 없는 페널티를 만드는 쪽이 더 나쁘다.
    (마감 우회 차단은 레슨 시작 전 실시간 판정으로 이미 성립한다.)
    """
    await _set_policy(client, auth_headers, min_cancel_hours=24)
    sid = await teacher.create_student("소급기록학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=10, amount=500000)
    past = datetime.now(KST).date() - timedelta(days=7)
    lid = await _create_lesson(client, auth_headers, sid, sub_id, past, "10:00")

    r = await client.patch(
        f"/api/v1/lessons/{lid}/status",
        headers=auth_headers,
        json={"status": "cancelledByStudentAdvance"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "cancelledByStudentAdvance"

    sub = await client.get(f"/api/v1/subscriptions/{sub_id}", headers=auth_headers)
    assert sub.json()["used_lessons"] == 0
