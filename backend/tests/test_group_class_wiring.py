"""P1-0 배선 정합 — ``GroupClassSchedule.group_class_id`` 는 ``GroupClass`` 를 참조한다.

배경: 그룹 스케줄/예약 서비스는 ``group_class_id`` 를 ``LessonClass``(학원 조직단위,
별개 개념) 로 해석해 왔다. 그 결과 정원·노쇼정책을 보유한 ``GroupClass`` 는 어떤
코드도 읽지 않는 죽은 모델이었다. 이 모듈은 다음을 고정한다.

1. 모델/DB 레벨 FK 가 ``group_classes.id`` 를 가리킨다.
2. 소유권 검증이 ``GroupClass.teacher_id`` 로 해석된다 (LessonClass 는 권한을 주지 않는다).
3. 스케줄 생성 시 정원이 ``GroupClass`` 에서 상속된다 (정원 SSOT).
4. 스케줄 → ``GroupClass`` 로 노쇼정책이 조회 가능하다 (J5b 4분기 집행의 진입점).

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P1-0.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory
from httpx import AsyncClient
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.base import Base

_MIGRATION_REVISION = "group_class_schedule_fk"


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    return ScriptDirectory.from_config(Config(str(backend_root / "alembic.ini")))


async def _make_group_class(
    db_session: AsyncSession,
    *,
    class_id: str = "gc-wiring",
    teacher_user_id: str = "test-user-id",
    max_capacity: int = 4,
    waitlist_capacity: int | None = 2,
    no_show_policy: str = "halfCredit",
) -> str:
    """실제 ``GroupClass`` row 를 만들고 id 반환 (teacher profile 에 소속)."""
    from sqlalchemy import select

    from app.models.schedule import GroupClass, GroupClassType, NoShowPolicy
    from app.models.teacher import Teacher

    teacher_profile_id = await db_session.scalar(select(Teacher.id).where(Teacher.user_id == teacher_user_id))
    if teacher_profile_id is None:
        teacher_profile_id = teacher_user_id
    db_session.add(
        GroupClass(
            id=class_id,
            teacher_id=teacher_profile_id,
            name="앙상블반",
            type=GroupClassType.regular,
            max_capacity=max_capacity,
            waitlist_capacity=waitlist_capacity,
            no_show_policy=NoShowPolicy(no_show_policy),
            duration_minutes=60,
            booking_deadline_minutes=60,
            cancel_deadline_minutes=1440,
            is_active=True,
        )
    )
    await db_session.flush()
    return class_id


# ---------------------------------------------------------------------------
# 1. 모델 / 마이그레이션 FK
# ---------------------------------------------------------------------------


def test_schedule_declares_fk_to_group_classes() -> None:
    """metadata 상 ``group_class_id`` 의 FK 타겟이 ``group_classes.id`` 여야 한다."""
    column = Base.metadata.tables["group_class_schedules"].c["group_class_id"]
    targets = {fk.target_fullname for fk in column.foreign_keys}
    assert "group_classes.id" in targets, f"FK 타겟 불일치: {targets}"
    assert "lesson_classes.id" not in targets, "LessonClass 오참조가 남아 있다"


def test_fk_migration_is_chained_and_documents_backfill() -> None:
    """마이그레이션이 단일 체인에 붙고, 기존 데이터 이관 전략을 명시해야 한다."""
    script = _script()
    rev = script.get_revision(_MIGRATION_REVISION)
    assert rev is not None
    assert rev.down_revision == "add_practice_journal"

    source = Path(rev.module.__file__).read_text()
    assert "fk_group_class_schedules_group_class_id_group_classes" in source
    # 기존 스케줄의 group_class_id 는 lesson_classes 를 가리킨다 — 백필 전략 명시 필수.
    assert "lesson_classes" in source, "기존 데이터 이관 전략(백필)이 마이그레이션에 없다"


@pytest.mark.sqlite_fk_on
async def test_orphan_schedule_is_rejected_by_db(db_session: AsyncSession) -> None:
    """존재하지 않는 group_class_id 로 스케줄을 넣으면 DB 가 거부해야 한다."""
    from datetime import UTC, datetime

    from app.models.schedule_ext import GroupClassSchedule

    db_session.add(
        GroupClassSchedule(
            id="sched-orphan",
            group_class_id="does-not-exist",
            start_time=datetime(2026, 8, 1, 10, tzinfo=UTC),
            end_time=datetime(2026, 8, 1, 11, tzinfo=UTC),
            max_capacity=5,
        )
    )
    with pytest.raises(IntegrityError):
        await db_session.flush()
    await db_session.rollback()


# ---------------------------------------------------------------------------
# 2. 소유권이 GroupClass 로 해석된다
# ---------------------------------------------------------------------------


async def test_group_class_owner_can_create_schedule(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher")
    await _make_group_class(db_session)

    response = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-wiring",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["group_class_id"] == "gc-wiring"


async def test_lesson_class_no_longer_grants_group_access(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """LessonClass row 만 있고 GroupClass 가 없으면 404 — 오참조 회귀 방지."""
    from sqlalchemy import select

    from app.models.lesson import LessonClass, LessonClassType
    from app.models.teacher import Teacher

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher_profile_id = await db_session.scalar(select(Teacher.id).where(Teacher.user_id == "test-user-id"))
    db_session.add(
        LessonClass(
            id="lc-only",
            teacher_id=teacher_profile_id,
            name="학원 조직단위",
            type=LessonClassType.private,
        )
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "lc-only",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
        },
    )
    assert response.status_code == 404, response.text


async def test_other_teacher_cannot_create_schedule(
    client: AsyncClient, create_test_user, db_session: AsyncSession
) -> None:
    """다른 강사의 GroupClass 에는 403."""
    from app.core.security import create_access_token

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher", role="teacher", email="other@test.com")
    await _make_group_class(db_session, class_id="gc-owned", teacher_user_id="test-user-id")

    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher', 'role': 'teacher'})}"}
    response = await client.post(
        "/api/v1/groups/schedules",
        headers=other_headers,
        json={
            "group_class_id": "gc-owned",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
        },
    )
    assert response.status_code == 403, response.text


# ---------------------------------------------------------------------------
# 3. 정원 SSOT — 서비스가 GroupClass 정원을 실제로 읽는다
# ---------------------------------------------------------------------------


async def test_schedule_inherits_capacity_from_group_class(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """max_capacity 미지정 시 GroupClass 의 정원·대기열 정원을 상속한다."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _make_group_class(db_session, max_capacity=4, waitlist_capacity=2)

    response = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-wiring",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["max_capacity"] == 4
    assert data["waitlist_capacity"] == 2


async def test_explicit_capacity_overrides_group_class_default(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """회차별 예외 정원은 명시값이 우선 (기존 호출자 호환)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _make_group_class(db_session, max_capacity=4)

    response = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-wiring",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
            "max_capacity": 9,
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["max_capacity"] == 9


# ---------------------------------------------------------------------------
# 4. 노쇼정책 조회 경로 (J5b 4분기 집행의 진입점)
# ---------------------------------------------------------------------------


async def test_no_show_policy_resolves_from_schedule(db_session: AsyncSession) -> None:
    """스케줄 → GroupClass 로 노쇼정책이 조회된다."""
    from datetime import UTC, datetime

    from app.models.schedule import NoShowPolicy
    from app.models.schedule_ext import GroupClassSchedule
    from app.services.schedule_ext_service import ScheduleExtService

    await _make_group_class(db_session, class_id="gc-policy", no_show_policy="halfCredit")
    db_session.add(
        GroupClassSchedule(
            id="sched-policy",
            group_class_id="gc-policy",
            start_time=datetime(2026, 8, 1, 10, tzinfo=UTC),
            end_time=datetime(2026, 8, 1, 11, tzinfo=UTC),
            max_capacity=4,
        )
    )
    await db_session.flush()

    service = ScheduleExtService(db_session)
    group_class = await service.get_group_class_for_schedule("sched-policy")
    assert group_class is not None
    assert group_class.id == "gc-policy"
    assert group_class.no_show_policy == NoShowPolicy.halfCredit
    assert group_class.max_capacity == 4


# ---------------------------------------------------------------------------
# 5. 기존 예약 흐름 회귀 — 정원 초과 → 대기열 → 자동승격
# ---------------------------------------------------------------------------


async def test_booking_capacity_and_waitlist_still_work(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
) -> None:
    """GroupClass 배선 이후에도 정원 마감·대기열 적재가 동작해야 한다."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    await _make_group_class(db_session, max_capacity=1, waitlist_capacity=1)
    for sid in ("stu-a", "stu-b"):
        db_session.add(Student(id=sid, teacher_id="test-user-id-prof", name=sid, instrument="piano"))
    await db_session.flush()

    created = await client.post(
        "/api/v1/groups/schedules",
        headers=auth_headers,
        json={
            "group_class_id": "gc-wiring",
            "start_time": "2026-08-01T10:00:00",
            "end_time": "2026-08-01T11:00:00",
        },
    )
    schedule_id = created.json()["id"]

    first = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "stu-a"},
    )
    assert first.status_code == 201, first.text
    assert first.json()["status"] == "confirmed"

    second = await client.post(
        "/api/v1/groups/bookings",
        headers=auth_headers,
        json={"schedule_id": schedule_id, "student_id": "stu-b"},
    )
    assert second.status_code == 201, second.text
    assert second.json()["status"] == "waitlist"
