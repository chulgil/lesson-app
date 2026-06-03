"""Subscription expiry status transition + milestone scan — Plan C Phase 6b.

`Subscription.status` 자동 전이 (active → expiringSoon at D-7, expiringSoon → expired
at D < 0) + D-14/D-7/D-1/D-0 milestone 식별. KST 자정 기준 days_left 산정.

Phase 6c (notification dispatch) 는 본 service 의 milestones 결과를 입력으로 사용.
"""

from __future__ import annotations

import logging
from datetime import UTC, date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import ClassMembership, LessonClass
from app.models.subscription import Subscription, SubscriptionStatus

logger = logging.getLogger(__name__)

# Plan C §1 Lore-constraint: KST 자정 기준 D-day 산정
_KST = ZoneInfo("Asia/Seoul")

# Plan C §3.4 — 4 milestones (학생/학부모/선생님 알림 트리거)
NOTIFY_MILESTONES = (14, 7, 1, 0)

# Status 전이 임계
EXPIRING_THRESHOLD_DAYS = 7

# 만료 스캔 대상 status — paused 등 비활성은 제외
_SCAN_STATUSES = (SubscriptionStatus.active, SubscriptionStatus.expiringSoon, SubscriptionStatus.expired)
RELATION_PAST_AFTER_DAYS = 30


def compute_today_kst() -> date:
    """KST 자정 기준 오늘. UTC ↔ KST 경계 hazard 의 단일 진원지."""
    return datetime.now(_KST).date()


def compute_days_left(sub: Subscription, *, today_kst: date) -> int | None:
    """`(end_date - today_kst).days`. end_date NULL 이면 None."""
    if sub.end_date is None:
        return None
    return (sub.end_date - today_kst).days


def _next_status(current: SubscriptionStatus, days_left: int) -> SubscriptionStatus:
    """Idempotent 전이 결정 — 입력이 이미 목적지면 동일 값 반환.

    #468 (1c): days_left >= 0 이면 만료 상태(expired)도 복구된다. 예) 만료된
    수강권의 end_date 를 연장하면 days_left 가 다시 양수가 되어 active/
    expiringSoon 로 되돌아온다. (이전에는 한 번 expired 가 되면 영구 고착)
    """
    if days_left < 0:
        return SubscriptionStatus.expired
    if days_left <= EXPIRING_THRESHOLD_DAYS:
        return SubscriptionStatus.expiringSoon
    # 7 < days_left → active 로 복구/유지.
    # current 가 expired 였더라도 end_date 연장 시 active 로 되돌린다.
    if current == SubscriptionStatus.expired:
        return SubscriptionStatus.active
    return current


class SubscriptionExpiryService:
    """매일 1회 (KST 00:05) cron 으로 구동되는 만료 전이 + milestone 스캐너."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def run_daily_check(self) -> dict[str, Any]:
        """활성 sub 스캔 → status 전이 + milestone hit 목록 반환.

        반환 dict::

            {
                "transitions": int,                # status UPDATE 건수
                "milestones": list[{
                    "subscription_id": str,
                    "student_id": str,
                    "membership_id": str,
                    "teacher_id": str,
                    "days_left": int,             # 0 / 1 / 7 / 14
                    "end_date": date,
                }],
                "today_kst": date,
            }
        """
        today = compute_today_kst()

        rows = (
            await self.db.scalars(
                select(Subscription).where(
                    Subscription.status.in_(_SCAN_STATUSES),
                    Subscription.end_date.is_not(None),
                )
            )
        ).all()

        transitions = 0
        relationship_transitions = 0
        milestones: list[dict[str, Any]] = []

        for sub in rows:
            days_left = compute_days_left(sub, today_kst=today)
            if days_left is None:
                continue

            target = _next_status(sub.status, days_left)
            if target != sub.status:
                logger.info(
                    "subscription_expiry: %s status %s → %s (days_left=%d)",
                    sub.id,
                    sub.status.value,
                    target.value,
                    days_left,
                )
                sub.status = target
                transitions += 1

            relationship_transitions += await self._transition_relationship_for_subscription(
                sub,
                days_left=days_left,
                target_status=target,
            )

            if days_left in NOTIFY_MILESTONES:
                # Resolve teacher_id via membership → lesson_class (#250)
                teacher_id = ""
                membership = await self.db.get(ClassMembership, sub.membership_id)
                if membership:
                    lesson_class = await self.db.get(LessonClass, membership.lesson_class_id)
                    if lesson_class:
                        teacher_id = lesson_class.teacher_id

                milestones.append(
                    {
                        "subscription_id": sub.id,
                        "student_id": sub.student_id,
                        "membership_id": sub.membership_id,
                        "teacher_id": teacher_id,
                        "days_left": days_left,
                        "end_date": sub.end_date,
                    }
                )

        if transitions > 0:
            await self.db.flush()

        return {
            "transitions": transitions,
            "relationship_transitions": relationship_transitions,
            "milestones": milestones,
            "today_kst": today,
        }

    async def _transition_relationship_for_subscription(
        self,
        sub: Subscription,
        *,
        days_left: int,
        target_status: SubscriptionStatus,
    ) -> int:
        """Keep teacher-student relation aligned with subscription expiry lifecycle."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation

        membership = await self.db.get(ClassMembership, sub.membership_id)
        if membership is None:
            return 0
        lesson_class = await self.db.get(LessonClass, membership.lesson_class_id)
        if lesson_class is None:
            return 0

        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == lesson_class.teacher_id,
                TeacherStudentRelation.student_id == sub.student_id,
            )
        )
        if relation is None:
            return 0

        now = datetime.now(UTC)
        if (
            target_status == SubscriptionStatus.expired
            and days_left < 0
            and relation.status == RelationStatus.active
            and relation.active_subscription_id == sub.id
        ):
            relation.status = RelationStatus.expired
            relation.active_subscription_id = None
            relation.last_subscription_expired_at = now
            relation.expired_until = now + timedelta(days=RELATION_PAST_AFTER_DAYS)
            await self.db.flush()
            return 1

        if (
            target_status == SubscriptionStatus.expired
            and relation.status == RelationStatus.expired
            and relation.expired_until is not None
            and relation.expired_until <= now
        ):
            relation.status = RelationStatus.past
            await self.db.flush()
            return 1

        return 0
