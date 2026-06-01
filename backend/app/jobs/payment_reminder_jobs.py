"""Payment reminder cron jobs — #424.

Three daily KST 09:00 jobs that walk `SubscriptionProposal` rows in
`pending` / `paymentNotified` status and ping the teacher (and, once #423
ships, the student via 알림톡) for D+1, D+3, D+7-final reminders.

Idempotency: each proposal carries `reminder_d{1,3,7}_sent_at` — a job only
sends when the relevant field is still NULL, so re-running the job is safe.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.scheduler import advisory_lock_key, try_advisory_lock
from app.models.subscription import ProposalStatus, SubscriptionProposal

logger = logging.getLogger(__name__)


JOB_ID_D1 = "payment_reminder_d1"
JOB_ID_D3 = "payment_reminder_d3"
JOB_ID_D7 = "payment_reminder_d7_final"


_ACTIVE = (ProposalStatus.pending, ProposalStatus.paymentNotified)


async def _send_student_alimtalk(session: AsyncSession, proposal: SubscriptionProposal, d_day: int) -> None:
    """#423 — D+1/D+3/D+7 학생/학부모 측 알림톡 발송 (멱등성은 service 안에서)."""
    from app.models.student import Student
    from app.services.alimtalk_service import build_alimtalk_service

    student = await session.get(Student, proposal.student_id)
    if student is None:
        return
    phone = student.parent_phone or student.phone or ""
    if not phone:
        return
    service = build_alimtalk_service(session)
    await service.send_payment_reminder(
        proposal_id=proposal.id,
        d_day=d_day,
        recipient_phone=phone,
        variables={
            "student_name": student.name or "",
            "proposal_id": proposal.id,
            "d_day": str(d_day),
        },
    )


async def _send_teacher_push(session: AsyncSession, proposal: SubscriptionProposal, notification_type: str) -> bool:
    """Best-effort push + in-app notif to the teacher. Silent on failure so cron stays green."""
    try:
        from app.services.notification_service import NotificationService

        notif_service = NotificationService(session)
        await notif_service.create_and_send(
            user_id=proposal.teacher_id,
            notification_type=notification_type,
            title="입금 대기 알림",
            body="학생 입금 대기 진행 중",
            data={
                "proposalId": proposal.id,
                "studentId": proposal.student_id,
                "source": "payment_pending_reminder",
            },
            action_url=f"/payments/pending?highlight={proposal.id}",
            action_label="입금 대기 보기",
        )
        return True
    except Exception:  # noqa: BLE001
        logger.exception("payment reminder push failed proposal=%s type=%s", proposal.id, notification_type)
        return False


async def _run_payment_reminder(
    *,
    n_days: int,
    reminder_field: str,
    notification_type: str,
    job_id: str,
    session: AsyncSession | None = None,
) -> dict[str, Any]:
    """Common D+N runner. Pass `session` from tests; production opens a fresh one."""

    async def _do(s: AsyncSession) -> dict[str, Any]:
        now = datetime.now(UTC)
        window_end = now - timedelta(days=n_days)
        window_start = now - timedelta(days=n_days + 1)

        column = getattr(SubscriptionProposal, reminder_field)

        result = await s.scalars(
            select(SubscriptionProposal).where(
                SubscriptionProposal.status.in_(_ACTIVE),
                SubscriptionProposal.created_at >= window_start,
                SubscriptionProposal.created_at < window_end,
                column.is_(None),
                SubscriptionProposal.expires_at > now,
            )
        )
        candidates = list(result.all())
        sent = 0
        for proposal in candidates:
            ok = await _send_teacher_push(s, proposal, notification_type)
            # #423 — alimtalk to student/parent in parallel with the teacher push.
            try:
                await _send_student_alimtalk(s, proposal, n_days)
            except Exception:  # noqa: BLE001
                logger.exception(
                    "alimtalk LNZ_PAYMENT_REMINDER_D%d trigger failed proposal=%s",
                    n_days,
                    proposal.id,
                )
            setattr(proposal, reminder_field, now)
            proposal.last_reminder_sent_at = now
            if ok:
                sent += 1
        await s.commit()
        return {
            "job_id": job_id,
            "candidates": len(candidates),
            "sent": sent,
            "n_days": n_days,
        }

    if session is not None:
        return await _do(session)

    async with AsyncSessionLocal() as new_session:
        lock_key = advisory_lock_key(job_id)
        acquired = await try_advisory_lock(new_session, key=lock_key)
        if not acquired:
            logger.info("%s: advisory lock not acquired, skip cycle", job_id)
            return {"job_id": job_id, "candidates": 0, "sent": 0, "n_days": n_days, "lock_acquired": False}
        out = await _do(new_session)
        out["lock_acquired"] = True
        return out


async def run_payment_reminder_d1(session: AsyncSession | None = None) -> dict[str, Any]:
    """D+1 reminder — fired daily at 09:00 KST."""
    return await _run_payment_reminder(
        n_days=1,
        reminder_field="reminder_d1_sent_at",
        notification_type="payment.pending_d1",
        job_id=JOB_ID_D1,
        session=session,
    )


async def run_payment_reminder_d3(session: AsyncSession | None = None) -> dict[str, Any]:
    return await _run_payment_reminder(
        n_days=3,
        reminder_field="reminder_d3_sent_at",
        notification_type="payment.pending_d3",
        job_id=JOB_ID_D3,
        session=session,
    )


async def run_payment_reminder_d7_final(session: AsyncSession | None = None) -> dict[str, Any]:
    return await _run_payment_reminder(
        n_days=7,
        reminder_field="reminder_d7_sent_at",
        notification_type="payment.pending_d7_final",
        job_id=JOB_ID_D7,
        session=session,
    )
