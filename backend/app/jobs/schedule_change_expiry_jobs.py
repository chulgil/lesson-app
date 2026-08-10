"""Schedule-change expiry hourly cron jobs — #692.

규칙 (subscription_schedule_change_spec.md §8.1):
- 72h 무응답 → scheduleChangeExpired 이벤트 + 양측 Default 복귀 + 변경권 복원
- 24h 무응답 → scheduleChangeReminder 이벤트 + 응답자에게 push 1회 (중복 방지)
- 60h 경과  → 요청자에게 만료 임박 push 1회 (중복 방지)

판정 기준: 마지막 scheduleChangeProposed / scheduleChangeCountered 이벤트 시각.
응답(Accepted/Rejected) 수신 시 타이머 리셋 — 그 사이 이벤트가 없을 때만 경과 시간 측정.

중복 방지: scheduleChangeReminder / scheduleChangeExpired 이벤트를 DB 기록으로 차단.
  - REMINDER_SENT: request_id + session_number 로 scheduleChangeReminder 이벤트 존재 여부 확인
  - EXPIRY_SENT:   request_id + session_number 로 scheduleChangeExpired  이벤트 존재 여부 확인
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.scheduler import (  # noqa: F401  release 는 finally 블록에서 사용
    advisory_lock_key,
    release_advisory_lock,
    try_advisory_lock,
)
from app.models.request_event import RequestEvent, RequestEventType

logger = logging.getLogger(__name__)

JOB_ID_EXPIRY = "schedule_change_expiry_hourly"

# 72시간 = 만료 기준
_EXPIRY_HOURS = 72
# 24시간 = 응답자 리마인드
_REMINDER_HOURS = 24
# 60시간 = 요청자 임박 알림
_APPROACHING_HOURS = 60

# 시스템 actor (배치 생성 이벤트용)
_SYSTEM_ACTOR_ID = "system"
_SYSTEM_ACTOR_TYPE = "system"

# 유효한 "타이머 리셋" 이벤트 (응답 수신 = 타이머 초기화)
_TIMER_RESET_TYPES = {
    RequestEventType.scheduleChangeAccepted,
    RequestEventType.scheduleChangeRejected,
    RequestEventType.scheduleChangeExpired,
}

# 협상 시작/중간 이벤트 (이 이벤트의 시각이 만료 기산점)
_PENDING_SOURCE_TYPES = {
    RequestEventType.scheduleChangeProposed,
    RequestEventType.scheduleChangeCountered,
}


async def _get_pending_threads(session: AsyncSession) -> list[dict[str, Any]]:
    """응답 대기 중인 (sub_id, request_id, session_number, latest_event) 목록 반환.

    전략:
    1. 모든 스케줄 변경 관련 이벤트를 (request_id, session_number) 스레드별로 그룹화.
    2. 각 스레드에서 가장 최근 이벤트가 Proposed/Countered 이면 '대기 중' 으로 판정.
    3. 이미 Expired/Accepted/Rejected 이벤트가 있는 스레드는 제외.
    """
    all_types = list(_PENDING_SOURCE_TYPES | _TIMER_RESET_TYPES)
    result = await session.scalars(
        select(RequestEvent)
        .where(RequestEvent.event_type.in_(all_types))
        .order_by(RequestEvent.request_id, RequestEvent.session_number, RequestEvent.created_at)
    )
    events = list(result.all())

    # 스레드별 최신 이벤트 추적
    threads: dict[tuple[str, str | None], RequestEvent] = {}
    for event in events:
        key = (event.request_id, str(event.session_number))
        threads[key] = event  # 같은 key 는 마지막(시간순)이 남음

    # 대기 중인 스레드만
    pending = []
    for latest in threads.values():
        if latest.event_type in _PENDING_SOURCE_TYPES:
            pending.append(
                {
                    "latest_event": latest,
                    "request_id": latest.request_id,
                    "session_number": latest.session_number,
                    "subscription_id": latest.subscription_id,
                    "proposed_at": latest.created_at,
                    # 응답자 = 제안자의 반대편
                    "proposer_actor_type": latest.actor_type,
                    "proposer_actor_id": latest.actor_id,
                }
            )
    return pending


async def _has_event(
    session: AsyncSession,
    *,
    request_id: str,
    session_number: int | None,
    event_type: RequestEventType,
) -> bool:
    """특정 (request_id, session_number) 스레드에 해당 event_type 이 이미 존재하는지 확인."""
    filters = [
        RequestEvent.request_id == request_id,
        RequestEvent.event_type == event_type,
    ]
    if session_number is not None:
        filters.append(RequestEvent.session_number == session_number)
    existing = await session.scalar(select(RequestEvent).where(and_(*filters)).limit(1))
    return existing is not None


async def _restore_reschedule_credit(
    session: AsyncSession,
    *,
    subscription_id: str | None,
    latest_event: RequestEvent,
) -> bool:
    """만료 시 요청 이벤트에서 차감된 변경권 복원.

    reschedule_credit_spec.md §4 규칙:
    - scheduleChangeProposed 이벤트의 change_credit_used == 1 이면 복원.
    - used_reschedule_count -= 1 (floor 0).
    """
    if subscription_id is None:
        return False
    if (latest_event.change_credit_used or 0) != 1:
        return False

    from sqlalchemy import select as sa_select

    from app.models.subscription import Subscription

    sub = await session.scalar(sa_select(Subscription).where(Subscription.id == subscription_id).with_for_update())
    if sub is None:
        return False

    if (sub.used_reschedule_count or 0) > 0:
        sub.used_reschedule_count = sub.used_reschedule_count - 1
        logger.info(
            "schedule_change_expiry: restored credit sub=%s remaining=%d",
            subscription_id,
            sub.used_reschedule_count,
        )
        return True
    return False


async def _send_push(
    session: AsyncSession,
    *,
    user_id: str,
    title: str,
    body: str,
    notification_type: str,
    data: dict[str, Any],
) -> None:
    """Best-effort push — 실패해도 job 전체를 중단하지 않는다."""
    try:
        from app.services.notification_service import NotificationService

        notif_service = NotificationService(session)
        await notif_service.create_and_send(
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            data=data,
        )
    except Exception:  # noqa: BLE001
        logger.exception(
            "schedule_change_expiry: push failed type=%s user=%s",
            notification_type,
            user_id,
        )


async def _has_approaching_notification(
    session: AsyncSession,
    *,
    user_id: str,
    request_id: str,
) -> bool:
    """True if the 60h approaching push was already sent for this request.

    The Notification row that ``_send_push`` persists is the dedupe marker —
    matched in Python because JSON containment operators differ between the
    PG production and SQLite test dialects.
    """
    from app.models.notification import Notification

    result = await session.scalars(
        select(Notification.data).where(
            Notification.user_id == user_id,
            Notification.type == "scheduleChangeApproaching",
        )
    )
    return any((row or {}).get("requestId") == request_id for row in result.all())


async def _find_opponent_user_id(
    session: AsyncSession,
    *,
    request_id: str,
    proposer_actor_type: str,
) -> str | None:
    """협상 스레드의 응답자 user_id 조회.

    레슨 요청(LessonRequest) 에서 teacher_id / student_id 를 읽는다.
    """
    try:
        from app.models.lesson_request import LessonRequest

        req = await session.get(LessonRequest, request_id)
        if req is None:
            return None
        # proposer 가 teacher 면 opponent = student, 그 반대도 동일
        if proposer_actor_type == "teacher":
            return getattr(req, "student_id", None)
        return getattr(req, "teacher_id", None)
    except Exception:  # noqa: BLE001
        logger.warning("schedule_change_expiry: could not resolve opponent user_id request=%s", request_id)
        return None


async def _find_proposer_user_id(
    session: AsyncSession,
    *,
    request_id: str,
    proposer_actor_type: str,
) -> str | None:
    """협상 스레드의 제안자 user_id 조회."""
    try:
        from app.models.lesson_request import LessonRequest

        req = await session.get(LessonRequest, request_id)
        if req is None:
            return None
        if proposer_actor_type == "teacher":
            return getattr(req, "teacher_id", None)
        return getattr(req, "student_id", None)
    except Exception:  # noqa: BLE001
        logger.warning("schedule_change_expiry: could not resolve proposer user_id request=%s", request_id)
        return None


async def _run_schedule_change_expiry(
    *,
    session: AsyncSession | None = None,
) -> dict[str, Any]:
    """공통 runner. 테스트에서는 session 주입, 프로덕션에서는 새 세션 오픈."""

    async def _do(s: AsyncSession) -> dict[str, Any]:
        now = datetime.now(UTC)
        expiry_cutoff = now - timedelta(hours=_EXPIRY_HOURS)
        reminder_cutoff = now - timedelta(hours=_REMINDER_HOURS)
        approaching_cutoff = now - timedelta(hours=_APPROACHING_HOURS)

        threads = await _get_pending_threads(s)

        expired_count = 0
        reminder_count = 0
        approaching_count = 0

        for thread in threads:
            latest_event: RequestEvent = thread["latest_event"]
            request_id: str = thread["request_id"]
            session_number: int | None = thread["session_number"]
            subscription_id: str | None = thread["subscription_id"]
            proposed_at: datetime = thread["proposed_at"]
            proposer_actor_type: str = thread["proposer_actor_type"]
            proposer_actor_id: str = thread["proposer_actor_id"]

            # UTC 변환 보장
            if proposed_at.tzinfo is None:
                proposed_at = proposed_at.replace(tzinfo=UTC)

            # ── 72h 만료 처리 ────────────────────────────────────────────────
            if proposed_at <= expiry_cutoff:
                already_expired = await _has_event(
                    s,
                    request_id=request_id,
                    session_number=session_number,
                    event_type=RequestEventType.scheduleChangeExpired,
                )
                if not already_expired:
                    # 변경권 복원 (마감 후 제안이었으면 change_credit_used=1)
                    await _restore_reschedule_credit(
                        s,
                        subscription_id=subscription_id,
                        latest_event=latest_event,
                    )

                    # scheduleChangeExpired 이벤트 기록
                    expired_event = RequestEvent(
                        request_id=request_id,
                        actor_type=_SYSTEM_ACTOR_TYPE,
                        actor_id=_SYSTEM_ACTOR_ID,
                        event_type=RequestEventType.scheduleChangeExpired,
                        subscription_id=subscription_id,
                        session_number=session_number,
                        message="72h 무응답으로 자동 만료되었습니다",
                    )
                    s.add(expired_event)
                    await s.flush()
                    expired_count += 1

                    # 양측 push
                    opponent_user_id = await _find_opponent_user_id(
                        s,
                        request_id=request_id,
                        proposer_actor_type=proposer_actor_type,
                    )
                    proposer_user_id = await _find_proposer_user_id(
                        s,
                        request_id=request_id,
                        proposer_actor_type=proposer_actor_type,
                    )
                    push_data = {
                        "requestId": request_id,
                        "subscriptionId": subscription_id or "",
                        "sessionNumber": str(session_number or ""),
                        "category": "schedule",
                    }
                    for uid in filter(None, [opponent_user_id, proposer_user_id]):
                        await _send_push(
                            s,
                            user_id=uid,
                            title="일정 변경 요청 만료",
                            body="응답 없이 일정 변경 요청이 만료되었습니다",
                            notification_type="scheduleChangeExpired",
                            data=push_data,
                        )
                continue  # 만료됐으면 리마인드/임박 skip

            # ── 60h 임박 알림 (요청자) ────────────────────────────────────────
            if proposed_at <= approaching_cutoff:
                # Dedupe on the previously-sent Notification row (this push's
                # own marker). It used to key on the scheduleChangeReminder
                # RequestEvent, which the 24h reminder always writes 36h
                # earlier — so the approaching push could never fire. A new
                # RequestEventType marker is not an option: deployed FE builds
                # crash on unknown RequestEventType values ($enumDecode),
                # while the FE notification-type parser falls back safely.
                proposer_user_id = await _find_proposer_user_id(
                    s,
                    request_id=request_id,
                    proposer_actor_type=proposer_actor_type,
                )
                already_approaching = proposer_user_id is None or await _has_approaching_notification(
                    s,
                    user_id=proposer_user_id,
                    request_id=request_id,
                )
                if not already_approaching:
                    if proposer_user_id:
                        await _send_push(
                            s,
                            user_id=proposer_user_id,
                            title="일정 변경 요청 만료 임박",
                            body="12시간 후 일정 변경 요청이 자동 만료됩니다",
                            notification_type="scheduleChangeApproaching",
                            data={
                                "requestId": request_id,
                                "subscriptionId": subscription_id or "",
                                "sessionNumber": str(session_number or ""),
                                "category": "schedule",
                            },
                        )
                    approaching_count += 1

            # ── 24h 응답자 리마인드 ───────────────────────────────────────────
            if proposed_at <= reminder_cutoff:
                already_reminded = await _has_event(
                    s,
                    request_id=request_id,
                    session_number=session_number,
                    event_type=RequestEventType.scheduleChangeReminder,
                )
                if not already_reminded:
                    reminder_event = RequestEvent(
                        request_id=request_id,
                        actor_type=_SYSTEM_ACTOR_TYPE,
                        actor_id=_SYSTEM_ACTOR_ID,
                        event_type=RequestEventType.scheduleChangeReminder,
                        subscription_id=subscription_id,
                        session_number=session_number,
                        message="24h 무응답 리마인드",
                    )
                    s.add(reminder_event)
                    await s.flush()

                    opponent_user_id = await _find_opponent_user_id(
                        s,
                        request_id=request_id,
                        proposer_actor_type=proposer_actor_type,
                    )
                    if opponent_user_id:
                        await _send_push(
                            s,
                            user_id=opponent_user_id,
                            title="일정 변경 응답 대기 중",
                            body="일정 변경 요청에 응답이 필요합니다",
                            notification_type="scheduleChangeReminder",
                            data={
                                "requestId": request_id,
                                "subscriptionId": subscription_id or "",
                                "sessionNumber": str(session_number or ""),
                                "category": "schedule",
                            },
                        )
                    reminder_count += 1

        await s.commit()
        return {
            "job_id": JOB_ID_EXPIRY,
            "expired": expired_count,
            "reminded": reminder_count,
            "approaching": approaching_count,
            "checked": len(threads),
        }

    if session is not None:
        return await _do(session)

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(JOB_ID_EXPIRY)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", JOB_ID_EXPIRY)
            return {
                "job_id": JOB_ID_EXPIRY,
                "expired": 0,
                "reminded": 0,
                "approaching": 0,
                "checked": 0,
                "lock_acquired": False,
            }
        try:
            out = await _do(new_session)
        finally:
            await release_advisory_lock(new_session, key=lock_key)
        out["lock_acquired"] = True
        return out


async def run_schedule_change_expiry_job(session: AsyncSession | None = None) -> dict[str, Any]:
    """Hourly runner — 72h 만료 + 24h 리마인드 + 60h 임박 알림."""
    return await _run_schedule_change_expiry(session=session)
