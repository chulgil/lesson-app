"""AlimTalkService unit tests — #423."""

from __future__ import annotations

import pytest
from freezegun import freeze_time
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.alimtalk_client import MockAlimTalkClient
from app.models.alimtalk_log import AlimTalkLog, AlimTalkTemplate
from app.services.alimtalk_service import AlimTalkService

VARIABLES = {
    "student_name": "김민준",
    "teacher_name": "이선생",
    "amount": "150,000",
    "bank_account": "1234-5678",
}


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")  # UTC 03:00 = KST 12:00 → in send window
async def test_send_invoice_success(db_session: AsyncSession):
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    log = await service.send_invoice(
        proposal_id="proposal-1",
        recipient_phone="010-1111-2222",
        variables=VARIABLES,
    )

    assert log is not None
    assert log.success is True
    assert log.template_id == AlimTalkTemplate.invoice.value
    assert client.sent == [(AlimTalkTemplate.invoice.value, "010-1111-2222", VARIABLES)]


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_invoice_idempotency_only_sends_once(db_session: AsyncSession):
    """Calling send_invoice twice for the same proposal results in exactly one carrier send."""
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    first = await service.send_invoice(
        proposal_id="proposal-X",
        recipient_phone="010-1111-3333",
        variables=VARIABLES,
    )
    second = await service.send_invoice(
        proposal_id="proposal-X",
        recipient_phone="010-1111-3333",
        variables=VARIABLES,
    )

    assert first is not None and second is not None
    assert len(client.sent) == 1, f"client.sent must hold one send, got {client.sent}"

    rows = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.proposal_id == "proposal-X"))).all()
    assert len(rows) == 1


@pytest.mark.asyncio
@freeze_time("2026-06-01 13:00:00")  # UTC 13:00 = KST 22:00 → outside window
async def test_send_window_blocks_at_night(db_session: AsyncSession):
    """Outside 08:00-20:00 KST, the send is deferred (logged as failure with marker)."""
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    log = await service.send_invoice(
        proposal_id="night-proposal",
        recipient_phone="010-9999-1111",
        variables=VARIABLES,
    )

    assert log is not None
    assert log.success is False
    assert "send window" in (log.error or "").lower() or "deferred" in (log.error or "").lower()
    assert client.sent == []  # carrier was not called


@pytest.mark.asyncio
@freeze_time("2026-06-01 13:00:00")  # 22:00 KST
async def test_d7_bypasses_send_window(db_session: AsyncSession):
    """LNZ_PAYMENT_REMINDER_D7 may send at night (final notice on expiry day)."""
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    log = await service.send_payment_reminder(
        proposal_id="expiring-proposal",
        d_day=7,
        recipient_phone="010-7777-8888",
        variables=VARIABLES,
    )

    assert log is not None
    assert log.success is True
    assert log.template_id == AlimTalkTemplate.reminder_d7.value
    assert len(client.sent) == 1


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_failure_records_fallback_channel(db_session: AsyncSession):
    """When the carrier returns failure, AlimTalkLog records fallback_channel='push'."""
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    service = AlimTalkService(client, db_session)

    log = await service.send_invoice(
        proposal_id="fail-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
    )

    assert log is not None
    assert log.success is False
    assert log.error == "carrier 503"
    assert log.fallback_channel == "push"


@pytest.mark.asyncio
async def test_unsupported_d_day_raises(db_session: AsyncSession):
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    with pytest.raises(ValueError, match="d_day"):
        await service.send_payment_reminder(
            proposal_id="p",
            d_day=2,
            recipient_phone="010-1111-2222",
            variables=VARIABLES,
        )


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_empty_phone_is_noop(db_session: AsyncSession):
    """Recipient with no phone is silently skipped — no carrier call, no log row."""
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    log = await service.send_invoice(
        proposal_id="no-phone-proposal",
        recipient_phone="",
        variables=VARIABLES,
    )

    assert log is None
    assert client.sent == []
    rows = (await db_session.scalars(select(AlimTalkLog))).all()
    assert rows == []


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_payment_confirm_idempotent_by_subscription_id(db_session: AsyncSession):
    """Idempotency is keyed by subscription_id for LNZ_PAYMENT_CONFIRM."""
    client = MockAlimTalkClient()
    service = AlimTalkService(client, db_session)

    await service.send_payment_confirm(
        subscription_id="sub-A",
        recipient_phone="010-4444-5555",
        variables=VARIABLES,
    )
    await service.send_payment_confirm(
        subscription_id="sub-A",
        recipient_phone="010-4444-5555",
        variables=VARIABLES,
    )

    assert len(client.sent) == 1
    rows = (await db_session.scalars(select(AlimTalkLog).where(AlimTalkLog.subscription_id == "sub-A"))).all()
    assert len(rows) == 1


# ---------------------------------------------------------------- fallback dispatcher


class _SpyFallback:
    """Test double for the push fallback dispatcher.

    Captures each (user_id, template_id, variables) tuple so tests can assert
    the fallback is fired exactly once per alimtalk failure.
    """

    def __init__(self, raise_exc: Exception | None = None) -> None:
        self.calls: list[tuple[str, str, dict[str, str]]] = []
        self.raise_exc = raise_exc

    async def __call__(self, user_id: str, template_id: str, variables: dict[str, str]) -> None:
        self.calls.append((user_id, template_id, dict(variables)))
        if self.raise_exc is not None:
            raise self.raise_exc


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_dispatched_on_failure(db_session: AsyncSession):
    """When alimtalk fails and `fallback_user_id` is given, FCM push fallback fires once."""
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    fallback = _SpyFallback()
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    log = await service.send_invoice(
        proposal_id="fallback-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
        fallback_user_id="user-123",
    )

    assert log is not None
    assert log.success is False
    assert log.fallback_channel == "push"
    assert len(fallback.calls) == 1
    user_id, template_id, vars_passed = fallback.calls[0]
    assert user_id == "user-123"
    assert template_id == AlimTalkTemplate.invoice.value
    assert vars_passed == VARIABLES


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_not_dispatched_on_success(db_session: AsyncSession):
    """Successful alimtalk → fallback dispatcher must NOT fire (no duplicate push)."""
    client = MockAlimTalkClient()
    fallback = _SpyFallback()
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    await service.send_invoice(
        proposal_id="success-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
        fallback_user_id="user-123",
    )

    assert fallback.calls == []


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_skipped_when_user_id_missing(db_session: AsyncSession):
    """No `fallback_user_id` → audit-only; fallback dispatcher is not invoked."""
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    fallback = _SpyFallback()
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    log = await service.send_invoice(
        proposal_id="audit-only-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
        # fallback_user_id omitted on purpose
    )

    assert log is not None
    assert log.success is False
    assert log.fallback_channel == "push"  # audit trail still records intent
    assert fallback.calls == []  # but no FCM push fired


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_exception_does_not_propagate(db_session: AsyncSession):
    """Failure inside the fallback dispatcher must not break the alimtalk caller."""
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    fallback = _SpyFallback(raise_exc=RuntimeError("fcm down"))
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    # Must complete without raising — alimtalk audit still works even if push fails.
    log = await service.send_invoice(
        proposal_id="fallback-explodes-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
        fallback_user_id="user-123",
    )

    assert log is not None
    assert log.success is False
    assert len(fallback.calls) == 1  # we still attempted the fallback


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_fires_for_payment_reminder(db_session: AsyncSession):
    """D+N reminder failure also routes to the FCM push fallback."""
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    fallback = _SpyFallback()
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    await service.send_payment_reminder(
        proposal_id="reminder-proposal",
        d_day=3,
        recipient_phone="010-4444-5555",
        variables=VARIABLES,
        fallback_user_id="user-456",
    )

    assert len(fallback.calls) == 1
    user_id, template_id, _ = fallback.calls[0]
    assert user_id == "user-456"
    assert template_id == AlimTalkTemplate.reminder_d3.value


@pytest.mark.asyncio
@freeze_time("2026-06-01 13:00:00")  # 22:00 KST — deferred window
async def test_fallback_not_dispatched_on_deferred(db_session: AsyncSession):
    """Deferred send (outside window) → no carrier call, no fallback dispatch."""
    client = MockAlimTalkClient()
    fallback = _SpyFallback()
    service = AlimTalkService(client, db_session, fallback_dispatcher=fallback)

    log = await service.send_invoice(
        proposal_id="deferred-proposal",
        recipient_phone="010-9999-1111",
        variables=VARIABLES,
        fallback_user_id="user-789",
    )

    assert log is not None
    assert log.success is False
    assert "send window" in (log.error or "")
    assert fallback.calls == []  # deferred is not a real failure


@pytest.mark.asyncio
@freeze_time("2026-06-01 03:00:00")
async def test_fallback_default_none_preserves_legacy_behavior(db_session: AsyncSession):
    """Constructing AlimTalkService without `fallback_dispatcher` keeps the audit-only behavior.

    Important for existing unit tests + ops scripts that drive the service
    directly without FCM wiring.
    """
    client = MockAlimTalkClient(next_failure=True, next_error="carrier 503")
    service = AlimTalkService(client, db_session)  # no dispatcher

    log = await service.send_invoice(
        proposal_id="legacy-proposal",
        recipient_phone="010-2222-3333",
        variables=VARIABLES,
        fallback_user_id="user-123",  # ignored because dispatcher is None
    )

    assert log is not None
    assert log.success is False
    assert log.fallback_channel == "push"
