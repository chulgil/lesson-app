"""Server-side idempotency key store for POST dedupe (#1117).

A slow-network POST can reach the server and commit while the client's response
times out. The client then replays the queued mutation. Without a dedupe key the
server treats the replay as a new request and creates a duplicate resource.

This table stores the client-generated ``Idempotency-Key`` per user together with
the original response, so a replay with the same key returns the stored response
instead of re-executing the handler. Scoped by ``user_id`` — keys never collide
across accounts.
"""

from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class IdempotencyKey(UUIDMixin, Base):
    """One row per (user, idempotency key). Reserved before the handler runs,
    then updated with the handler's response for replay."""

    __tablename__ = "idempotency_keys"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    idem_key: Mapped[str] = mapped_column(String(255), nullable=False)
    method: Mapped[str] = mapped_column(String(10), nullable=False)
    path: Mapped[str] = mapped_column(String(500), nullable=False)
    # NULL while the original request is still in flight (reserved but not yet
    # completed). Set once the handler responds → future replays return it.
    status_code: Mapped[int | None] = mapped_column(Integer, nullable=True)
    response_body: Mapped[Any | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (UniqueConstraint("user_id", "idem_key", name="uq_idempotency_keys_user_id_idem_key"),)
