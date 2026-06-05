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
from collections.abc import Awaitable, Callable
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


# #423 — push fallback dispatcher signature. Called once per failed send when a
# caller provides `fallback_user_id`. Returns nothing; failures inside the
# fallback path are logged and swallowed (a failed fallback must not recurse).
FallbackDispatcher = Callable[[str, str, dict[str, str]], Awaitable[None]]


class _DefaultPushFallback:
    """Real-world fallback: FCM push via NotificationService.

    Kept out of `build_alimtalk_service` import path until call-time so the
    service module stays lightweight for unit tests that pass their own
    fallback callable.
    """

    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def __call__(
        self,
        user_id: str,
        template_id: str,
        variables: dict[str, str],
    ) -> None:
        # Local import — NotificationService pulls FCM which is heavy.
        from app.services.notification_service import NotificationService

        notif_type = _ALIMTALK_TO_NOTIFICATION_TYPE.get(template_id, "paymentReminder")
        title, body = _fallback_message(template_id, variables)
        try:
            notif_service = NotificationService(self._db)
            await notif_service.create_and_send(
                user_id=user_id,
                notification_type=notif_type,
                title=title,
                body=body,
                data={
                    "alimtalk_template": template_id,
                    "alimtalk_fallback": True,
                },
            )
        except Exception:  # noqa: BLE001 — fallback must not propagate
            logger.exception("alimtalk push fallback failed template=%s user=%s", template_id, user_id)


# Map alimtalk template → in-app notification type. Used by the default fallback
# dispatcher to pick the correct notification channel for the student/parent.
_ALIMTALK_TO_NOTIFICATION_TYPE: dict[str, str] = {
    AlimTalkTemplate.invoice.value: "paymentRequested",
    AlimTalkTemplate.reminder_d1.value: "paymentReminder",
    AlimTalkTemplate.reminder_d3.value: "paymentReminder",
    AlimTalkTemplate.reminder_d7.value: "paymentReminder",
    AlimTalkTemplate.payment_confirm.value: "paymentConfirmed",
}


def _fallback_message(template_id: str, variables: dict[str, str]) -> tuple[str, str]:
    """Build a short fallback push title/body when alimtalk could not be delivered."""
    student = variables.get("student_name", "")
    if template_id == AlimTalkTemplate.invoice.value:
        return (
            "수강료 안내",
            f"{student} 학생 수강권 제안을 확인해 주세요." if student else "수강권 제안을 확인해 주세요.",
        )
    if template_id == AlimTalkTemplate.payment_confirm.value:
        return ("입금 확인 완료", f"{student} 학생 수강권이 발급되었습니다." if student else "수강권이 발급되었습니다.")
    if template_id.startswith("LNZ_PAYMENT_REMINDER_D"):
        d_day = variables.get("d_day", "")
        suffix = f" (D+{d_day})" if d_day else ""
        return ("입금 확인 대기" + suffix, "수강료 입금이 아직 확인되지 않았습니다.")
    return ("알림", "새로운 알림이 있습니다.")


def build_alimtalk_service(db: AsyncSession) -> AlimTalkService:
    """Convenience factory used by triggers in other services + cron jobs.

    Wires the default push fallback dispatcher so that real failures route to
    FCM. Tests construct AlimTalkService directly and may pass their own
    `fallback_dispatcher` (or none) to keep assertions narrow.
    """
    return AlimTalkService(
        get_alimtalk_client(),
        db,
        fallback_dispatcher=_DefaultPushFallback(db),
    )


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

    def __init__(
        self,
        client: AlimTalkClient,
        db: AsyncSession,
        *,
        fallback_dispatcher: FallbackDispatcher | None = None,
    ) -> None:
        self.client = client
        self.db = db
        # #423 — invoked once per failed send when the caller supplies a
        # `fallback_user_id`. `None` means "audit-only" (caller doesn't want
        # the in-app push). Existing unit tests rely on this default.
        self._fallback_dispatcher = fallback_dispatcher

    # ------------------------------------------------------------------ public API

    async def send_invoice(
        self,
        *,
        proposal_id: str,
        recipient_phone: str,
        variables: dict[str, str],
        fallback_user_id: str | None = None,
    ) -> AlimTalkLog | None:
        return await self._send_with_log(
            template_id=AlimTalkTemplate.invoice.value,
            proposal_id=proposal_id,
            subscription_id=None,
            recipient_phone=recipient_phone,
            variables=variables,
            fallback_user_id=fallback_user_id,
        )

    async def send_payment_reminder(
        self,
        *,
        proposal_id: str,
        d_day: int,
        recipient_phone: str,
        variables: dict[str, str],
        fallback_user_id: str | None = None,
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
            fallback_user_id=fallback_user_id,
        )

    async def send_payment_confirm(
        self,
        *,
        subscription_id: str,
        recipient_phone: str,
        variables: dict[str, str],
        proposal_id: str | None = None,
        fallback_user_id: str | None = None,
    ) -> AlimTalkLog | None:
        return await self._send_with_log(
            template_id=AlimTalkTemplate.payment_confirm.value,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            recipient_phone=recipient_phone,
            variables=variables,
            fallback_user_id=fallback_user_id,
        )

    async def send_teacher_vacation(
        self,
        *,
        vacation_period_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        """LNZ_TEACHER_VACATION fan-out — one row per (vacation, phone).

        Idempotency key is (vacation_period_id, recipient_phone, template_id):
        the same vacation may impact several students and each phone gets a
        single send. Caller (vacation service) drives one call per impacted
        student.
        """
        return await self._send_with_log(
            template_id=AlimTalkTemplate.teacher_vacation.value,
            proposal_id=None,
            subscription_id=None,
            vacation_period_id=vacation_period_id,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    async def send_teacher_vacation_cancelled(
        self,
        *,
        vacation_period_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        """LNZ_TEACHER_VACATION_CANCELLED — Recovery fan-out (spec §7.3).

        Mirrors `send_teacher_vacation` (same key shape) so the announce/cancel
        pair stays balanced per (vacation_period_id, recipient_phone). One
        cancellation row per impacted student/phone.
        """
        return await self._send_with_log(
            template_id=AlimTalkTemplate.teacher_vacation_cancelled.value,
            proposal_id=None,
            subscription_id=None,
            vacation_period_id=vacation_period_id,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    async def send_teacher_vacation_returned(
        self,
        *,
        vacation_period_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> AlimTalkLog | None:
        """LNZ_TEACHER_VACATION_RETURNED — daily cron announce (spec §6.3).

        Sent the morning after a vacation's end_date for every student/phone
        that originally received the LNZ_TEACHER_VACATION notice. Idempotency
        key is identical (vacation_period_id, recipient_phone, template_id) —
        cron retries on a future day are safe.
        """
        return await self._send_with_log(
            template_id=AlimTalkTemplate.teacher_vacation_returned.value,
            proposal_id=None,
            subscription_id=None,
            vacation_period_id=vacation_period_id,
            recipient_phone=recipient_phone,
            variables=variables,
        )

    async def send_academy_announcement(
        self,
        *,
        kakao_template_id: str,
        recipient_phone: str,
        variables: dict[str, str],
    ) -> bool:
        """AC-M3 §4 — 학원 공지를 카톡 알림톡 1건 발송.

        AlimTalkLog 행은 생성하지 않는다 (recipient.kakao_delivered 가 SOR).
        idempotency / fallback / send window 검사도 호출자(announcement
        send 흐름)가 채임 — 이 메서드는 단발 "보냈는지" 응답만 한다.

        Returns: 발송 성공 여부 (success bool).
        """
        if not recipient_phone:
            return False
        result = await self._safe_send(kakao_template_id, recipient_phone, variables)
        return bool(result.success)

    # ------------------------------------------------------------------ internals

    async def _send_with_log(
        self,
        *,
        template_id: str,
        proposal_id: str | None,
        subscription_id: str | None,
        recipient_phone: str,
        variables: dict[str, str],
        vacation_period_id: str | None = None,
        fallback_user_id: str | None = None,
    ) -> AlimTalkLog | None:
        if not recipient_phone:
            logger.info("alimtalk skipped: recipient phone empty template=%s", template_id)
            return None

        existing = await self._find_existing(
            template_id,
            proposal_id,
            subscription_id,
            vacation_period_id,
            recipient_phone,
        )
        if existing and existing.success:
            return existing

        if not _in_send_window(template_id):
            return await self._record_deferred(
                template_id=template_id,
                proposal_id=proposal_id,
                subscription_id=subscription_id,
                vacation_period_id=vacation_period_id,
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
            await self._maybe_dispatch_fallback(
                result=result,
                template_id=template_id,
                variables=variables,
                fallback_user_id=fallback_user_id,
            )
            return existing

        log = AlimTalkLog(
            template_id=template_id,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            vacation_period_id=vacation_period_id,
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
        await self._maybe_dispatch_fallback(
            result=result,
            template_id=template_id,
            variables=variables,
            fallback_user_id=fallback_user_id,
        )
        return log

    async def _maybe_dispatch_fallback(
        self,
        *,
        result: AlimTalkResult,
        template_id: str,
        variables: dict[str, str],
        fallback_user_id: str | None,
    ) -> None:
        """Dispatch FCM push fallback exactly once when alimtalk failed.

        Spec: alimtalk_templates.md §5 — failed sends route to in-app push
        (and SMS for CRITICAL). This method fires the FCM half; SMS is out of
        scope for #423 because no SMS infrastructure exists yet.

        Guarded by:
          * carrier success → no fallback (delivery already worked)
          * `fallback_user_id is None` → caller is audit-only
          * `self._fallback_dispatcher is None` → service wasn't wired (unit tests)
        Failure inside the dispatcher itself is swallowed by the dispatcher to
        prevent recursion (alimtalk fail → push fail → alimtalk retry...).
        """
        if result.success:
            return
        if fallback_user_id is None or self._fallback_dispatcher is None:
            return
        try:
            await self._fallback_dispatcher(fallback_user_id, template_id, variables)
        except Exception:  # noqa: BLE001 — defensive; dispatcher already swallows
            logger.exception(
                "alimtalk fallback dispatch raised template=%s user=%s",
                template_id,
                fallback_user_id,
            )

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
        vacation_period_id: str | None = None,
        recipient_phone: str | None = None,
    ) -> AlimTalkLog | None:
        # Need at least one identity key (proposal / subscription / vacation).
        if proposal_id is None and subscription_id is None and vacation_period_id is None:
            return None
        stmt = select(AlimTalkLog).where(AlimTalkLog.template_id == template_id)
        if proposal_id is not None:
            stmt = stmt.where(AlimTalkLog.proposal_id == proposal_id)
        if subscription_id is not None:
            stmt = stmt.where(AlimTalkLog.subscription_id == subscription_id)
        if vacation_period_id is not None:
            stmt = stmt.where(AlimTalkLog.vacation_period_id == vacation_period_id)
            # Vacation fans out per student — phone is part of the key so two
            # students never collide on the same vacation row.
            if recipient_phone is not None:
                stmt = stmt.where(AlimTalkLog.recipient_phone == recipient_phone)
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
        vacation_period_id: str | None = None,
    ) -> AlimTalkLog:
        log = AlimTalkLog(
            template_id=template_id,
            proposal_id=proposal_id,
            subscription_id=subscription_id,
            vacation_period_id=vacation_period_id,
            recipient_phone=recipient_phone,
            variables=variables,
            success=False,
            error="deferred: outside 08:00-20:00 KST send window",
            retry_count=0,
        )
        self.db.add(log)
        await self.db.flush()
        return log
