"""Subscription expiry notification dispatcher — Plan C Phase 6c.

`SubscriptionExpiryService.run_daily_check()` 의 milestones 결과를 입력받아
학생/학부모에게 FCM + in-app 알림을 발송. 선생님은 #240 결정에 따라 제외 (대시보드 뱃지로 대체).

Dedup 키: (subscription_id, milestone, sent_date, recipient_user_id) UNIQUE
- 같은 날 두 번째 dispatch 호출 시 중복 발송 차단
- 다중 인스턴스 발화 시 advisory_lock + 본 dedup table 의 이중 방어

Notification payload:
- type="subscription_expiring"
- priority=high (D≤1) / normal (D=7,14)
- data={"subscriptionId": ..., "daysLeft": ...}
- action_url=f"/subscriptions/{sub_id}"
"""

from __future__ import annotations

import logging
from datetime import UTC, date, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import NotificationPriority
from app.models.parent import Parent, ParentChildRelation
from app.models.student import Student
from app.models.subscription_expiry import SubscriptionExpiryDispatchLog
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)

NOTIFICATION_TYPE = "subscription_expiring"
HIGH_PRIORITY_THRESHOLD = 1


def _build_title_body(days_left: int) -> tuple[str, str]:
    if days_left <= 0:
        return ("수강권이 오늘 만료됩니다", "수강권이 오늘 만료됩니다. 갱신을 진행해주세요.")
    return (f"수강권 만료 D-{days_left}", f"수강권이 {days_left}일 후 만료됩니다.")


def _priority_for(days_left: int) -> NotificationPriority:
    return NotificationPriority.high if days_left <= HIGH_PRIORITY_THRESHOLD else NotificationPriority.normal


class SubscriptionExpiryDispatcher:
    """학생 + 학부모 만료 알림 dispatch + dedup_log 기록."""

    def __init__(self, db: AsyncSession, notification_service: NotificationService | None = None) -> None:
        self.db = db
        self._notification_service = notification_service or NotificationService(db)

    async def _resolve_recipients(self, student_id: str) -> list[tuple[str, str]]:
        """Return [(user_id, role), ...] for student + linked parents.

        - student.user_id 가 NULL 이면 학생 항목 제외
        - 학부모는 ParentChildRelation 조회 후 Parent.user_id 매핑
        """
        recipients: list[tuple[str, str]] = []

        student = await self.db.get(Student, student_id)
        if student is not None and student.user_id:
            recipients.append((student.user_id, "student"))

        rels = (
            await self.db.scalars(select(ParentChildRelation).where(ParentChildRelation.student_id == student_id))
        ).all()
        for rel in rels:
            parent = await self.db.get(Parent, rel.parent_id)
            if parent is not None and parent.user_id:
                recipients.append((parent.user_id, "parent"))

        return recipients

    async def _is_already_sent(
        self, *, subscription_id: str, milestone: int, sent_date: date, recipient_user_id: str
    ) -> bool:
        existing = await self.db.scalar(
            select(SubscriptionExpiryDispatchLog.id).where(
                SubscriptionExpiryDispatchLog.subscription_id == subscription_id,
                SubscriptionExpiryDispatchLog.milestone == milestone,
                SubscriptionExpiryDispatchLog.sent_date == sent_date,
                SubscriptionExpiryDispatchLog.recipient_user_id == recipient_user_id,
            )
        )
        return existing is not None

    async def _dispatch_one(
        self,
        *,
        milestone: dict[str, Any],
        recipient_user_id: str,
        recipient_role: str,
        today_kst: date,
    ) -> bool:
        """Send 1 notification + insert dispatch_log. Return True if sent."""
        sub_id = milestone["subscription_id"]
        days_left = milestone["days_left"]

        if await self._is_already_sent(
            subscription_id=sub_id,
            milestone=days_left,
            sent_date=today_kst,
            recipient_user_id=recipient_user_id,
        ):
            return False

        title, body = _build_title_body(days_left)
        priority = _priority_for(days_left)

        await self._notification_service.create_and_send(
            user_id=recipient_user_id,
            notification_type=NOTIFICATION_TYPE,
            title=title,
            body=body,
            priority=priority,
            data={"subscriptionId": sub_id, "daysLeft": days_left},
            action_url=f"/subscriptions/{sub_id}",
        )

        self.db.add(
            SubscriptionExpiryDispatchLog(
                subscription_id=sub_id,
                milestone=days_left,
                recipient_user_id=recipient_user_id,
                recipient_role=recipient_role,
                sent_date=today_kst,
                sent_at=datetime.now(UTC),
            )
        )
        await self.db.flush()
        return True

    async def dispatch_milestones(self, milestones: list[dict[str, Any]], *, today_kst: date) -> dict[str, int]:
        """Dispatch FCM + in-app notifications for each milestone hit.

        Args:
            milestones: SubscriptionExpiryService.run_daily_check() 결과의 milestones list.
            today_kst: KST 자정 기준 today (dedup sent_date 키).

        Returns:
            {"sent": int, "deduplicated": int}
        """
        sent = 0
        deduplicated = 0

        for milestone in milestones:
            student_id = milestone["student_id"]
            recipients = await self._resolve_recipients(student_id)

            for recipient_user_id, recipient_role in recipients:
                try:
                    if await self._dispatch_one(
                        milestone=milestone,
                        recipient_user_id=recipient_user_id,
                        recipient_role=recipient_role,
                        today_kst=today_kst,
                    ):
                        sent += 1
                    else:
                        deduplicated += 1
                except Exception:
                    logger.exception(
                        "subscription_expiry_dispatcher: failed sub=%s recipient=%s milestone=%d",
                        milestone["subscription_id"],
                        recipient_user_id,
                        milestone["days_left"],
                    )

        return {"sent": sent, "deduplicated": deduplicated}
