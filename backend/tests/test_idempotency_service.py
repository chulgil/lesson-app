"""Idempotency service — reserve / replay / release + concurrent-race safety (#1117)."""

from __future__ import annotations

import asyncio

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.idempotency_key import IdempotencyKey
from app.services.idempotency_service import (
    IN_FLIGHT,
    REPLAY,
    RESERVED,
    IdempotencyService,
)

pytestmark = pytest.mark.asyncio


def _make_session_factory(db_engine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=db_engine, class_=AsyncSession, expire_on_commit=False)


async def test_first_reserve_returns_reserved(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)

    outcome = await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")

    assert outcome.kind == RESERVED


async def test_second_reserve_while_in_flight_returns_in_flight(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)
    await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")

    # No store yet → the original is still processing.
    outcome = await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")

    assert outcome.kind == IN_FLIGHT


async def test_reserve_after_store_replays_stored_response(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)
    await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")
    await service.store_response(user_id="user-1", idem_key="k1", status_code=201, response_body={"id": "lesson-1"})

    outcome = await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")

    assert outcome.kind == REPLAY
    assert outcome.status_code == 201
    assert outcome.response_body == {"id": "lesson-1"}


async def test_different_keys_both_reserve(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)

    first = await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")
    second = await service.reserve_or_replay(user_id="user-1", idem_key="k2", method="POST", path="/lessons")

    assert first.kind == RESERVED
    assert second.kind == RESERVED


async def test_same_key_different_user_both_reserve(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)

    first = await service.reserve_or_replay(user_id="user-1", idem_key="shared", method="POST", path="/lessons")
    second = await service.reserve_or_replay(user_id="user-2", idem_key="shared", method="POST", path="/lessons")

    assert first.kind == RESERVED
    assert second.kind == RESERVED


async def test_release_allows_fresh_reserve(db_session: AsyncSession) -> None:
    service = IdempotencyService(db_session)
    await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")

    await service.release(user_id="user-1", idem_key="k1")

    outcome = await service.reserve_or_replay(user_id="user-1", idem_key="k1", method="POST", path="/lessons")
    assert outcome.kind == RESERVED


async def test_concurrent_same_key_reserves_exactly_once(db_engine) -> None:
    """Two tasks reserving the same key concurrently → exactly one row, one winner."""
    factory = _make_session_factory(db_engine)

    async def attempt() -> str:
        async with factory() as session:
            service = IdempotencyService(session)
            outcome = await service.reserve_or_replay(user_id="user-1", idem_key="race", method="POST", path="/lessons")
            return outcome.kind

    results = await asyncio.gather(attempt(), attempt())

    assert results.count(RESERVED) == 1, f"expected exactly one winner, got {results}"

    async with factory() as session:
        count = await session.scalar(
            select(func.count())
            .select_from(IdempotencyKey)
            .where(IdempotencyKey.user_id == "user-1", IdempotencyKey.idem_key == "race")
        )
    assert count == 1
