"""Idempotency reservation + replay for POST dedupe (#1117, SN-4/INV-2).

Reserve-first pattern to stay race-safe (this repo had a real duplicate-write
race before): INSERT the key row *before* the handler runs. Two concurrent
requests carrying the same ``Idempotency-Key`` cannot both reserve — the unique
constraint on ``(user_id, idem_key)`` lets exactly one win. The loser reads the
existing row: if the winner already stored a response it is replayed, otherwise
the original is still in flight and the loser gets ``in_flight`` (→ 409).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.idempotency_key import IdempotencyKey

# Reservation outcomes. Plain strings (not a DB enum) — internal control flow.
RESERVED = "reserved"
REPLAY = "replay"
IN_FLIGHT = "in_flight"


@dataclass
class IdempotencyOutcome:
    """Result of :meth:`IdempotencyService.reserve_or_replay`."""

    kind: str
    status_code: int | None = None
    response_body: Any | None = None


class IdempotencyService:
    """Reserve/store/release operations over one :class:`AsyncSession`.

    Each method commits on its own so a reservation is durable *before* the
    handler runs (race safety). In production the middleware gives this its own
    session, separate from the handler's request session.
    """

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def reserve_or_replay(
        self,
        *,
        user_id: str,
        idem_key: str,
        method: str,
        path: str,
    ) -> IdempotencyOutcome:
        """Reserve the key or, if it already exists, replay / report in-flight."""
        row = IdempotencyKey(
            user_id=user_id,
            idem_key=idem_key,
            method=method,
            path=path,
            status_code=None,
            response_body=None,
        )
        self._session.add(row)
        try:
            await self._session.commit()
            return IdempotencyOutcome(RESERVED)
        except IntegrityError:
            await self._session.rollback()

        existing = await self._get(user_id=user_id, idem_key=idem_key)
        if existing is None:
            # Extremely rare: the row vanished between the conflict and the read
            # (e.g. a concurrent release). Treat as still in-flight — the client
            # retries, not duplicates.
            return IdempotencyOutcome(IN_FLIGHT)
        if existing.status_code is not None:
            return IdempotencyOutcome(
                REPLAY,
                status_code=existing.status_code,
                response_body=existing.response_body,
            )
        return IdempotencyOutcome(IN_FLIGHT)

    async def store_response(
        self,
        *,
        user_id: str,
        idem_key: str,
        status_code: int,
        response_body: Any | None,
    ) -> None:
        """Persist the handler's response so future replays return it."""
        row = await self._get(user_id=user_id, idem_key=idem_key)
        if row is None:
            return
        row.status_code = status_code
        row.response_body = response_body
        await self._session.commit()

    async def release(self, *, user_id: str, idem_key: str) -> None:
        """Drop the reservation so a transient failure can be retried cleanly."""
        row = await self._get(user_id=user_id, idem_key=idem_key)
        if row is None:
            return
        await self._session.delete(row)
        await self._session.commit()

    async def _get(self, *, user_id: str, idem_key: str) -> IdempotencyKey | None:
        return await self._session.scalar(
            select(IdempotencyKey).where(
                IdempotencyKey.user_id == user_id,
                IdempotencyKey.idem_key == idem_key,
            )
        )
