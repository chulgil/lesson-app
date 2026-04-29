"""Tests for RequestEvent model — Plan A Phase 1.

Validates that 27 RequestEventType values + 2 ScheduleChangeType values
are persisted correctly in the request_events table.
"""

from datetime import UTC, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_request_event_persists_27_event_types(db_session: AsyncSession) -> None:
    """RequestEvent model must persist all 27 event types (P0-2).

    Mirrors frontend SSOT in
    `frontend/lib/features/schedule/domain/entities/request_event.dart`
    (RequestEventType, Hive typeId 130, 27 values).
    """
    from app.models.request_event import (
        RequestEvent,
        RequestEventType,
        ScheduleChangeType,
    )

    # Plan A Phase 1 의 RED test 는 lesson_request 의존 없이 단독 실행
    # (FK 없음 — request_id 는 String UUID 로 외부 lesson_request.id 참조)
    request_id = "test-request-uuid-0000-0000-0000-000000000001"
    actor_id = "teacher-uuid-0000-0000-0000-000000000001"

    for et in RequestEventType:
        evt = RequestEvent(
            request_id=request_id,
            actor_type="teacher",
            actor_id=actor_id,
            event_type=et,
            schedule_change_type=(ScheduleChangeType.singleLesson if et.name.startswith("scheduleChange") else None),
            created_at=datetime.now(UTC),
        )
        db_session.add(evt)
    await db_session.flush()

    rows = (await db_session.scalars(select(RequestEvent).where(RequestEvent.request_id == request_id))).all()
    assert len(rows) == 27, f"기대 27 event, 실제 {len(rows)}"
    assert {r.event_type for r in rows} == set(RequestEventType)


@pytest.mark.asyncio
async def test_request_event_schedule_change_fields_optional(
    db_session: AsyncSession,
) -> None:
    """schedule_change_type / proposed_day_of_week / proposed_time 는 모두 nullable."""
    from app.models.request_event import RequestEvent, RequestEventType

    evt = RequestEvent(
        request_id="r-001",
        actor_type="student",
        actor_id="s-001",
        event_type=RequestEventType.initialRequest,
        created_at=datetime.now(UTC),
    )
    db_session.add(evt)
    await db_session.flush()

    fetched = await db_session.scalar(select(RequestEvent).where(RequestEvent.id == evt.id))
    assert fetched is not None
    assert fetched.schedule_change_type is None
    assert fetched.proposed_day_of_week is None
    assert fetched.proposed_time is None
    assert fetched.suggested_slots in (None, [], {}, [{}])  # JSON 직렬화 빈값 허용


@pytest.mark.asyncio
async def test_request_event_schedule_change_type_2_values(
    db_session: AsyncSession,
) -> None:
    """ScheduleChangeType 은 singleLesson / bulkChange 2값 (typeId 132)."""
    from app.models.request_event import (
        RequestEvent,
        RequestEventType,
        ScheduleChangeType,
    )

    types = list(ScheduleChangeType)
    assert {t.value for t in types} == {"singleLesson", "bulkChange"}, (
        f"ScheduleChangeType 값 불일치: {[t.value for t in types]}"
    )

    for sct in types:
        evt = RequestEvent(
            request_id="r-sct",
            actor_type="teacher",
            actor_id="t-sct",
            event_type=RequestEventType.scheduleChangeProposed,
            schedule_change_type=sct,
            proposed_day_of_week=2,
            proposed_time="14:30",
            created_at=datetime.now(UTC),
        )
        db_session.add(evt)
    await db_session.flush()

    rows = (await db_session.scalars(select(RequestEvent).where(RequestEvent.request_id == "r-sct"))).all()
    assert len(rows) == 2
    assert {r.schedule_change_type for r in rows} == set(ScheduleChangeType)


@pytest.mark.asyncio
async def test_request_event_15_columns_layout(db_session: AsyncSession) -> None:
    """RequestEvent 는 frontend Hive RequestEvent (14 fields) + DB id 1 = 15 컬럼."""
    from app.models.request_event import RequestEvent

    columns = {c.name for c in RequestEvent.__table__.columns}
    expected = {
        "id",
        "request_id",
        "actor_type",
        "actor_id",
        "event_type",
        "suggested_slots",
        "selected_slot_index",
        "message",
        "schedule_change_type",
        "proposed_day_of_week",
        "proposed_time",
        "subscription_id",
        "session_number",
        "created_at",
        "updated_at",  # TimestampMixin (백엔드 표준)
    }
    assert columns == expected, f"컬럼 불일치: 기대 {expected}, 실제 {columns}"
