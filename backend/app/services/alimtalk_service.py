"""Alimtalk sending service — #423.

Coordinates the 5 alimtalk templates:
  * `LNZ_INVOICE`              — sent right after a teacher creates a proposal
  * `LNZ_PAYMENT_REMINDER_D1`  — D+1 cron
  * `LNZ_PAYMENT_REMINDER_D3`  — D+3 cron
  * `LNZ_PAYMENT_REMINDER_D7`  — D+7 cron (final notice)
  * `LNZ_PAYMENT_CONFIRM`      — sent right after a teacher confirms payment

Invariants enforced here (not on the carrier):

  * **Idempotency** — at most one row per `(proposal_id|subscription_id, template_id)`.
  * **Send window** — 08:00-20:00 KST. Outside window, the call is recorded as
    deferred (failure with a marker error) so the retry cron picks it up the
    next morning. `LNZ_PAYMENT_REMINDER_D7` bypasses this because it is the
    last-chance notice on expiry day.
  * **Failure fallback** — failed sends record the fallback channel ("push" /
    "sms") so the audit log shows where the message actually went.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.alimtalk_client import (
    AlimTalkClient,
    AlimTalkResult,
    KakaoAlimTalkClient,
    MockAlimTalkClient,
)
from app.core.config import settings
from app.models.alimtalk_log import AlimTalkLog, AlimTalkTemplate

logger = logging.getLogger(__name__)


# Process-level mock singleton so tests + dev can inspect every send across calls.
_shared_mock_client: MockAlimTalkClient | None = None


def get_alimtalk_client() -> AlimTalkClient:
    """Return the active alimtalk carrier client (mock vs real, controlled by env)."""
    global _shared_mock_client
    if settings.ALIMTALK_USE_MOCK:
        if _shared_mock_client is None:
            _shared_mock_client = MockAlimTalkClient()
        return _shared_mock_client
    return KakaoAlimTalkClient(
        api_base_url=settings.ALIMTALK_API_BASE_URL,
        api_key=settings.ALIMTALK_API_KEY,
        sender_profile=settings.ALIMTALK_SENDER_PROFILE,
    )


def build_alimtalk_service(db: AsyncSession) -> AlimTalkService:
    """Convenience factory used by triggers in other services + cron jobs."""
    return AlimTalkService(get_alimtalk_client(), db)


KST = timezone(timedelta(hours=9))
SEND_WINDOW_START_HOUR = 8
SEND_WINDOW_END_HOUR = 20
# Templates that may send outside the normal window (e.g. final-notice cron at 09:00
# but conceptually allowed at any time because expiry is at midnight).
_WINDOW_BYPASS_TEMPLATES: frozenset[str] = frozenset({AlimTalkTemplate.reminder_d7.value})


def _now_kst() -> datetime:
    return datetime.now(KST)


def _in_send_window(template_id: str, now: datetime | None = None) -> bool:
    if template_id in _WINDOW_BYPASS_TEMPLATES:
        return True
    current = (now or _now_kst()).astimezone(KST)
    return SEND_WINDOW_START_HOUR <= current.hour < SEND_WINDOW_END_HOUR


class AlimTalkService:
    """Coordinates the 5 templates + idempotency + send window + fallback log."""

    def __init__(self, client: AlimTalkClient, db: AsyncSession) -> None:
        self.client = client
        self.db = db

    # ------------------------------------------------------------------ public API

    async def send_invoice(
        self,
        *,
        proposal_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        return await self._send_with_log(
            template_id=AlimTalkTemplate.invoice.value,
            proposal_id=proposal_id,
            subscription_id=None,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    async def send_payment_reminder(
        self,
        *,
        proposal_id: str,
        d_day: int,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        template_map = {
            1: AlimTalkTemplate.reminder_d1,
            3: AlimTalkTemplate.reminder_d3,
            7: AlimTalkTemplate.reminder_d7,
        }
        template = template_map.get(d_day)
        if template is None:
            raise ValueError(f"unsupported reminder d_day={d_day}")
        return await self._send_with_log(
            template_id=template.value,
            proposal_id=proposal_id,
            subscription_id=None,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    async def send_payment_confirm(
        self,
        *,
        subscription_id: str,
        recipient_phone: str,
        variables: dict[str, str],
        proposal_id: str | None = None,
    ) -> AlimTalkLog | None:
        return await self._send_with_log(
            template_id=AlimTalkTemplate.payment_confirm.value,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    # ------------------------------------------------------------------ internals

    async def _send_with_log(
        self,
        *,
        template_id: str,
        proposal_id: str | None,
        subscription_id: str | None,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        if not recipient_phone:
            logger.info("alimtalk skipped: recipient phone empty template=%s", template_id)
            return None

        existing = await self._find_existing(template_id, proposal_id, subscription_id)
        if existing and existing.success:
            return existing

        if not _in_send_window(template_id):
            return await self._record_deferred(
                template_id=template_id,
                proposal_id=proposal_id,
                subscription_id=subscription_id,
                recipient_phone=recipient_phone,
                variables=variables,
            )

        result = await self._safe_send(template_id, recipient_phone, variables)

        if existing is not None:
            # Reuse the row — bump retry_count if we previously failed.
            existing.recipient_phone = recipient_phone
            existing.variables = variables
            existing.sent_at = datetime.now(UTC)
            existing.success = result.success
            existing.message_id = result.message_id
            existing.error = result.error
            existing.retry_count = (existing.retry_count or 0) + 1
            if not result.success:
                existing.fallback_channel = "push"
            await self.db.flush()
            return existing

        log = AlimTalkLog(
            template_id=template_id,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            recipient_phone=recipient_phone,
            variables=variables,
            success=result.success,
            message_id=result.message_id,
            error=result.error,
            retry_count=0,
            fallback_channel=None if result.success else "push",
        )
        self.db.add(log)
        await self.db.flush()
        return log

    async def _safe_send(
        self,
        template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkResult:
        try:
            return await self.client.send(
                template_id=template_id,
                recipient_phone=recipient_phone,
                variables=variables,
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("alimtalk send raised template=%s", template_id)
            return AlimTalkResult(success=False, error=str(exc))

    async def _find_existing(
        self,
        template_id: str,
        proposal_id: str | None,
        subscription_id: str | None,
    ) -> AlimTalkLog | None:
        if proposal_id is None and subscription_id is None:
            return None
        stmt = select(AlimTalkLog).where(AlimTalkLog.template_id == template_id)
        if proposal_id is not None:
            stmt = stmt.where(AlimTalkLog.proposal_id == proposal_id)
        if subscription_id is not None:
            stmt = stmt.where(AlimTalkLog.subscription_id == subscription_id)
        result = await self.db.scalars(stmt)
        return result.first()

    async def _record_deferred(
        self,
        *,
        template_id: str,
        proposal_id: str | None,
        subscription_id: str | None,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog:
        log = AlimTalkLog(
            template_id=template_id,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            recipient_phone=recipient_phone,
            variables=variables,
            success=False,
            error="deferred: outside 08:00-20:00 KST send window",
            retry_count=0,
        )
        self.db.add(log)
        await self.db.flush()
        return log
