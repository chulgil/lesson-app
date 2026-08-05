"""Idempotency middleware — end-to-end POST dedupe over ASGI (#1117).

Uses a self-contained FastAPI app with a side-effecting POST endpoint (a counter
standing in for "create a resource"), so we can assert the handler runs exactly
once per logical mutation regardless of how many times the client replays.
"""

from __future__ import annotations

from collections.abc import AsyncGenerator

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.idempotency import IdempotencyMiddleware
from app.core.security import create_access_token

pytestmark = pytest.mark.asyncio


def _build_app(db_session: AsyncSession) -> tuple[FastAPI, dict[str, int]]:
    app = FastAPI()
    app.add_middleware(IdempotencyMiddleware)

    state = {"calls": 0}

    @app.post("/echo")
    async def echo() -> dict[str, int]:
        state["calls"] += 1
        return {"call": state["calls"]}

    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    return app, state


def _auth(user_id: str = "user-1") -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token({'sub': user_id})}"}


async def _client(app: FastAPI) -> AsyncClient:
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_same_key_replays_and_runs_handler_once(db_session: AsyncSession) -> None:
    app, state = _build_app(db_session)
    headers = {**_auth(), "Idempotency-Key": "k1"}

    async with await _client(app) as ac:
        first = await ac.post("/echo", headers=headers)
        second = await ac.post("/echo", headers=headers)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json() == second.json() == {"call": 1}
    assert state["calls"] == 1


async def test_different_keys_run_handler_twice(db_session: AsyncSession) -> None:
    app, state = _build_app(db_session)

    async with await _client(app) as ac:
        first = await ac.post("/echo", headers={**_auth(), "Idempotency-Key": "k1"})
        second = await ac.post("/echo", headers={**_auth(), "Idempotency-Key": "k2"})

    assert first.json() == {"call": 1}
    assert second.json() == {"call": 2}
    assert state["calls"] == 2


async def test_no_header_passes_through(db_session: AsyncSession) -> None:
    app, state = _build_app(db_session)

    async with await _client(app) as ac:
        first = await ac.post("/echo", headers=_auth())
        second = await ac.post("/echo", headers=_auth())

    assert first.json() == {"call": 1}
    assert second.json() == {"call": 2}
    assert state["calls"] == 2


async def test_unauthenticated_with_header_passes_through(db_session: AsyncSession) -> None:
    app, state = _build_app(db_session)
    headers = {"Idempotency-Key": "k1"}  # no Authorization → no user scope

    async with await _client(app) as ac:
        first = await ac.post("/echo", headers=headers)
        second = await ac.post("/echo", headers=headers)

    assert first.json() == {"call": 1}
    assert second.json() == {"call": 2}
    assert state["calls"] == 2


async def test_same_key_different_users_not_deduped(db_session: AsyncSession) -> None:
    app, state = _build_app(db_session)

    async with await _client(app) as ac:
        first = await ac.post("/echo", headers={**_auth("user-1"), "Idempotency-Key": "shared"})
        second = await ac.post("/echo", headers={**_auth("user-2"), "Idempotency-Key": "shared"})

    assert first.json() == {"call": 1}
    assert second.json() == {"call": 2}
    assert state["calls"] == 2
