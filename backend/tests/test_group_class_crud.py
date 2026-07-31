"""P1-1 클래스 정의 CRUD + 반(regular) 반복 스케줄 자동 생성.

교사가 그룹 클래스를 만들고 고치고 내리는 경로를 고정한다.

1. CRUD 4종 (생성·목록·상세·수정) 이 FE ``GroupClass`` 엔티티의 wire key 로 응답한다.
2. 반(regular) 생성 시 요일·시간 기반 반복 ``GroupClassSchedule`` 이 자동 생성된다.
   정원은 명시하지 않는다 — ``GroupClass`` 상속 (정원 SSOT, P1-0).
3. 반복 설정 수정 시 **미래 빈 회차만** 재생성한다 (과거·예약 있는 회차 보존).
4. 드롭인(dropIn) 은 자동 생성하지 않는다 (교사가 회차를 직접 오픈).
5. 소유 교사가 아니면 쓰기 403, 비활성화한 클래스는 기본 목록에서 빠진다.

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P1-1.
"""

from __future__ import annotations

import datetime as dt
from zoneinfo import ZoneInfo

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

_KST = ZoneInfo("Asia/Seoul")
_CLASSES = "/api/v1/groups/classes"

# FE `frontend/lib/features/schedule/domain/entities/group_class.dart` 의 wire key.
# 소비자 계약이므로 BE 컬럼명(repeat_days/repeat_time) 이 아니라 이 이름이 기준이다.
_FE_KEYS = {
    "id",
    "teacher_id",
    "organization_id",
    "name",
    "description",
    "type",
    "max_capacity",
    "waitlist_capacity",
    "duration_minutes",
    "booking_deadline_minutes",
    "cancel_deadline_minutes",
    "no_show_policy",
    "max_no_show_count",
    "repeat_days_of_week",
    "repeat_time_of_day",
    "instrument",
    "price_per_session",
    "is_active",
    "created_at",
    "updated_at",
}


def _regular_payload(**overrides) -> dict:
    """월·수 18:00 앙상블반 기본 payload."""
    payload = {
        "name": "앙상블반",
        "type": "regular",
        "max_capacity": 6,
        "waitlist_capacity": 2,
        "duration_minutes": 60,
        "no_show_policy": "halfCredit",
        "repeat_days_of_week": [1, 3],  # 1=월 … 7=일 (FE 계약)
        "repeat_time_of_day": "18:00",
        "instrument": "violin",
    }
    payload.update(overrides)
    return payload


def _other_teacher_headers(user_id: str = "other-teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _schedules_of(db_session: AsyncSession, class_id: str) -> list:
    from app.models.schedule_ext import GroupClassSchedule

    rows = await db_session.scalars(
        select(GroupClassSchedule)
        .where(GroupClassSchedule.group_class_id == class_id)
        .order_by(GroupClassSchedule.start_time)
    )
    return list(rows.all())


def _as_kst(value: dt.datetime) -> dt.datetime:
    """저장된 start_time 을 KST 벽시계로 환산 (naive 는 KST 로 간주)."""
    if value.tzinfo is None:
        return value.replace(tzinfo=_KST)
    return value.astimezone(_KST)


# ---------------------------------------------------------------------------
# 1. CRUD 4종
# ---------------------------------------------------------------------------


async def test_create_group_class_returns_fe_contract_keys(client: AsyncClient, auth_headers, create_test_user) -> None:
    """생성 응답은 FE GroupClass 엔티티가 파싱할 수 있는 key 집합이어야 한다."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())

    assert response.status_code == 201, response.text
    body = response.json()
    assert _FE_KEYS <= set(body), f"FE 계약 key 누락: {sorted(_FE_KEYS - set(body))}"
    assert body["name"] == "앙상블반"
    assert body["type"] == "regular"
    assert body["max_capacity"] == 6
    assert body["no_show_policy"] == "halfCredit"
    assert body["repeat_days_of_week"] == [1, 3]
    assert body["repeat_time_of_day"] == "18:00"
    assert body["is_active"] is True
    # teacher_id 는 호출자 user_id 가 아니라 강사 프로필 id 로 저장된다.
    assert body["teacher_id"] == "test-user-id-prof"


async def test_list_group_classes_returns_own_classes(client: AsyncClient, auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await client.post(_CLASSES, headers=auth_headers, json=_regular_payload(name="앙상블반"))
    await client.post(
        _CLASSES,
        headers=auth_headers,
        json=_regular_payload(name="원데이 특강", type="dropIn", repeat_days_of_week=None, repeat_time_of_day=None),
    )

    response = await client.get(_CLASSES, headers=auth_headers)

    assert response.status_code == 200, response.text
    names = {item["name"] for item in response.json()["items"]}
    assert names == {"앙상블반", "원데이 특강"}


async def test_list_group_classes_by_teacher_id_is_readable_by_student(
    client: AsyncClient, auth_headers, student_auth_headers, create_test_user
) -> None:
    """교사 상세의 '개설 클래스' 섹션(P1-2) 을 위해 학생도 teacher_id 필터로 읽는다."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")
    await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())

    response = await client.get(_CLASSES, headers=student_auth_headers, params={"teacher_id": "test-user-id-prof"})

    assert response.status_code == 200, response.text
    assert [item["name"] for item in response.json()["items"]] == ["앙상블반"]


async def test_get_group_class_detail(client: AsyncClient, auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]

    response = await client.get(f"{_CLASSES}/{class_id}", headers=auth_headers)

    assert response.status_code == 200, response.text
    assert response.json()["id"] == class_id
    assert _FE_KEYS <= set(response.json())


async def test_get_unknown_group_class_returns_404(client: AsyncClient, auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get(f"{_CLASSES}/does-not-exist", headers=auth_headers)

    assert response.status_code == 404, response.text


async def test_update_group_class_patches_only_supplied_fields(
    client: AsyncClient, auth_headers, create_test_user
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]

    response = await client.patch(
        f"{_CLASSES}/{class_id}",
        headers=auth_headers,
        json={"name": "앙상블 A반", "max_capacity": 8},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["name"] == "앙상블 A반"
    assert body["max_capacity"] == 8
    # 건드리지 않은 필드는 보존.
    assert body["no_show_policy"] == "halfCredit"
    assert body["repeat_time_of_day"] == "18:00"


# ---------------------------------------------------------------------------
# 2. 반(regular) 반복 스케줄 자동 생성
# ---------------------------------------------------------------------------


async def test_regular_creates_recurring_schedules(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """반 생성 시 요일·시간 기반으로 N주치 회차가 자동 생성되고 정원을 상속한다."""
    await create_test_user(user_id="test-user-id", role="teacher")

    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    assert created.status_code == 201, created.text
    class_id = created.json()["id"]

    schedules = await _schedules_of(db_session, class_id)
    # 주 2회(월·수) × 4주 rolling window.
    assert len(schedules) == 8, f"생성된 회차 수: {len(schedules)}"

    for schedule in schedules:
        start_kst = _as_kst(schedule.start_time)
        # 1=월 … 7=일 (FE 계약) → python weekday 0=월.
        assert start_kst.weekday() + 1 in (1, 3), f"요일 불일치: {start_kst}"
        assert (start_kst.hour, start_kst.minute) == (18, 0), f"시각 불일치: {start_kst}"
        assert (_as_kst(schedule.end_time) - start_kst) == dt.timedelta(minutes=60)
        # 정원 SSOT = GroupClass — 회차에 정원을 따로 박지 않고 상속한다.
        assert schedule.max_capacity == 6
        assert schedule.waitlist_capacity == 2

    # 회차는 미래에만 생성된다.
    now_kst = dt.datetime.now(_KST)
    assert all(_as_kst(schedule.start_time) > now_kst for schedule in schedules)
    # 같은 시각 중복 없음.
    assert len({schedule.start_time for schedule in schedules}) == 8


async def test_drop_in_class_does_not_create_schedules(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """드롭인은 교사가 회차를 직접 오픈한다 — 자동 생성 금지."""
    await create_test_user(user_id="test-user-id", role="teacher")

    created = await client.post(
        _CLASSES,
        headers=auth_headers,
        json=_regular_payload(type="dropIn", name="원데이 특강"),
    )
    assert created.status_code == 201, created.text

    assert await _schedules_of(db_session, created.json()["id"]) == []


async def test_regular_without_repeat_config_creates_no_schedules(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """요일·시간이 없으면 생성할 반복 정보가 없다 — 조용히 0건."""
    await create_test_user(user_id="test-user-id", role="teacher")

    created = await client.post(
        _CLASSES,
        headers=auth_headers,
        json=_regular_payload(repeat_days_of_week=None, repeat_time_of_day=None),
    )
    assert created.status_code == 201, created.text

    assert await _schedules_of(db_session, created.json()["id"]) == []


async def test_update_recurrence_regenerates_future_only(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """반복 시간 변경 → 미래 빈 회차만 갱신. 과거·예약 있는 회차는 보존."""
    from app.models.schedule_ext import GroupClassSchedule

    await create_test_user(user_id="test-user-id", role="teacher")
    created = await client.post(
        _CLASSES,
        headers=auth_headers,
        json=_regular_payload(repeat_days_of_week=[1], repeat_time_of_day="18:00"),
    )
    class_id = created.json()["id"]

    generated = await _schedules_of(db_session, class_id)
    assert len(generated) == 4

    # 과거 회차 1건 (자동 생성 대상 밖 — 이미 지나간 수업).
    past_start = dt.datetime.now(_KST) - dt.timedelta(days=7)
    db_session.add(
        GroupClassSchedule(
            id="gcs-past",
            group_class_id=class_id,
            start_time=past_start,
            end_time=past_start + dt.timedelta(minutes=60),
            max_capacity=6,
        )
    )
    # 미래 회차 중 1건은 이미 예약이 있다 → 보존되어야 한다.
    booked = generated[0]
    booked.current_bookings = 1
    booked_start = booked.start_time
    await db_session.flush()

    response = await client.patch(
        f"{_CLASSES}/{class_id}",
        headers=auth_headers,
        json={"repeat_time_of_day": "20:00"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["repeat_time_of_day"] == "20:00"

    after = await _schedules_of(db_session, class_id)
    # SQLite 는 offset 을 돌려주지 않는다 — 벽시계 기준으로 비교한다.
    starts = {_as_kst(schedule.start_time) for schedule in after}
    assert _as_kst(past_start) in starts, "과거 회차가 삭제되었다"
    assert _as_kst(booked_start) in starts, "예약 있는 미래 회차가 삭제되었다"

    regenerated = [s for s in after if _as_kst(s.start_time).hour == 20]
    assert len(regenerated) == 4, f"20:00 회차 수: {len(regenerated)}"
    # 예약 없던 18:00 미래 회차는 사라졌다 (예약 있는 1건만 남음).
    now_kst = dt.datetime.now(_KST)
    leftover_18 = [s for s in after if _as_kst(s.start_time).hour == 18 and _as_kst(s.start_time) > now_kst]
    assert len(leftover_18) == 1


async def test_update_without_recurrence_change_keeps_schedules(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """이름만 바꿀 때 회차를 다시 만들지 않는다 (불필요한 파괴 금지)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]
    before = {schedule.id for schedule in await _schedules_of(db_session, class_id)}

    response = await client.patch(f"{_CLASSES}/{class_id}", headers=auth_headers, json={"name": "앙상블 B반"})

    assert response.status_code == 200, response.text
    after = {schedule.id for schedule in await _schedules_of(db_session, class_id)}
    assert after == before


# ---------------------------------------------------------------------------
# 3. 소유권 · 비활성화
# ---------------------------------------------------------------------------


async def test_other_teacher_cannot_update_group_class(client: AsyncClient, auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher", role="teacher", email="other@test.com")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]

    response = await client.patch(
        f"{_CLASSES}/{class_id}",
        headers=_other_teacher_headers(),
        json={"name": "탈취"},
    )

    assert response.status_code == 403, response.text


async def test_other_teacher_cannot_deactivate_group_class(client: AsyncClient, auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher", role="teacher", email="other@test.com")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]

    response = await client.delete(f"{_CLASSES}/{class_id}", headers=_other_teacher_headers())

    assert response.status_code == 403, response.text


async def test_deactivated_class_is_excluded_from_list(client: AsyncClient, auth_headers, create_test_user) -> None:
    """비활성화는 soft delete — 기본 목록에서 빠지고 include_inactive 로만 보인다."""
    await create_test_user(user_id="test-user-id", role="teacher")
    created = await client.post(_CLASSES, headers=auth_headers, json=_regular_payload())
    class_id = created.json()["id"]

    deleted = await client.delete(f"{_CLASSES}/{class_id}", headers=auth_headers)
    assert deleted.status_code == 200, deleted.text
    assert deleted.json()["is_active"] is False

    listed = await client.get(_CLASSES, headers=auth_headers)
    assert [item["id"] for item in listed.json()["items"]] == []

    with_inactive = await client.get(_CLASSES, headers=auth_headers, params={"include_inactive": "true"})
    assert [item["id"] for item in with_inactive.json()["items"]] == [class_id]


async def test_student_cannot_create_group_class(client: AsyncClient, student_auth_headers, create_test_user) -> None:
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com")

    response = await client.post(_CLASSES, headers=student_auth_headers, json=_regular_payload())

    assert response.status_code == 403, response.text
