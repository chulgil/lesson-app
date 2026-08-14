"""Subscription refund request service — issue #1271.

Student submits bank account details to request a refund for a
subscription's unused remainder; the teacher transfers the money
externally (no in-app payment / PG refund) and marks the request
completed or rejected.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.refund_request import (
    RefundRequestCompleteRequest,
    RefundRequestCreate,
    RefundRequestRejectRequest,
    RefundRequestResponse,
)
from app.services.notification_recipient import resolve_student_user_id, resolve_teacher_user_id
from app.services.notification_service import NotificationPriority, NotificationService
from app.services.subscription_access_service import SubscriptionAccessService
from app.services.subscription_service import remaining_lessons

# spec §4 — 계좌 정보는 처리(완료/반려) 후 이 일수가 지나면 read-time redaction.
ACCOUNT_RETENTION_DAYS = 30

# spec §2 — "잔여 회차가 있는 활성/만료 수강권" 만 환불 요청 대상.
_REFUNDABLE_STATUSES = frozenset({"active", "expiringSoon", "expired"})


def _ensure_aware(dt: datetime) -> datetime:
    """SQLite returns naive datetimes even for DateTime(timezone=True) columns."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


def _mask_account_number(value: str) -> str:
    """뒤 4자리만 노출하는 마스킹 (개인정보 Level 1 — data-privacy.md)."""
    trimmed = value.strip()
    if len(trimmed) <= 4:
        return "*" * len(trimmed)
    return f"{'*' * (len(trimmed) - 4)}{trimmed[-4:]}"


class RefundRequestService:
    """Create, list, and process subscription refund requests."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.access = SubscriptionAccessService(db)

    async def create(self, payload: RefundRequestCreate, current_user: Any) -> RefundRequestResponse:
        from app.models.refund_request import RefundRequest

        role = self.access.actor_type(current_user)
        if role not in {"student", "parent"}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

        subscription = await self.access.get_subscription_for_user(payload.subscription_id, current_user)

        sub_status = getattr(subscription.status, "value", subscription.status)
        if sub_status not in _REFUNDABLE_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Subscription is not eligible for a refund request",
            )

        existing = await self.db.scalar(
            select(RefundRequest).where(
                RefundRequest.subscription_id == subscription.id,
                RefundRequest.status == "requested",
            )
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An active refund request already exists for this subscription",
            )

        teacher_id = await self._teacher_id_for_subscription(subscription)

        refund = RefundRequest(
            subscription_id=subscription.id,
            student_id=subscription.student_id,
            teacher_id=teacher_id,
            bank_name=payload.bank_name,
            account_number=payload.account_number,
            account_holder=payload.account_holder,
            reason=payload.reason,
            status="requested",
        )
        self.db.add(refund)
        await self.db.flush()
        await self.db.refresh(refund)

        await self._notify(
            teacher_id=refund.teacher_id,
            notification_type="refundRequested",
            title="환불 요청이 도착했습니다",
            body="학생이 환불을 요청했어요. 계좌 정보를 확인하고 처리해주세요.",
            subscription_id=refund.subscription_id,
        )

        return await self._to_response(refund, viewer_role="student", now=datetime.now(UTC))

    async def list_for_user(self, current_user: Any) -> list[RefundRequestResponse]:
        from app.models.refund_request import RefundRequest

        role = self.access.actor_type(current_user)
        if role == "teacher":
            query = select(RefundRequest).where(
                RefundRequest.teacher_id.in_(await self.access.teacher_identifiers(current_user))
            )
            viewer_role = "teacher"
        elif role in {"student", "parent"}:
            query = select(RefundRequest).where(
                RefundRequest.student_id.in_(await self.access.visible_student_ids(current_user))
            )
            viewer_role = "student"
        else:
            return []

        result = await self.db.scalars(query.order_by(RefundRequest.requested_at.desc()))
        now = datetime.now(UTC)
        return [await self._to_response(refund, viewer_role=viewer_role, now=now) for refund in result.all()]

    async def complete(
        self,
        refund_request_id: str,
        payload: RefundRequestCompleteRequest,
        current_user: Any,
    ) -> RefundRequestResponse:
        from app.models.subscription import Subscription, SubscriptionStatus

        refund = await self._require_teacher_refund(refund_request_id, current_user)
        if refund.status != "requested":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Refund request already processed")

        now = datetime.now(UTC)
        refund.status = "completed"
        refund.processed_amount = payload.processed_amount
        refund.processed_at = now

        subscription = await self.db.get(Subscription, refund.subscription_id)
        if subscription is not None:
            subscription.status = SubscriptionStatus.refunded
            # spec §2 — "잔여 회차 소멸". used_lessons 를 상한까지 올려 remaining_lessons()
            # 가 어디서 읽히든 0 이 되도록 한다 (status 체크 누락에도 방어).
            if subscription.total_lessons is not None:
                subscription.used_lessons = subscription.total_lessons + subscription.bonus_count
            elif getattr(subscription.type, "value", subscription.type) == "trial":
                subscription.used_lessons = 1 + subscription.bonus_count

        await self.db.flush()
        await self.db.refresh(refund)

        await self._notify(
            student_id=refund.student_id,
            notification_type="refundCompleted",
            title="환불 처리 완료",
            body="선생님이 환불을 완료했어요. 입금 내역을 확인해주세요.",
            subscription_id=refund.subscription_id,
        )

        return await self._to_response(refund, viewer_role="teacher", now=now)

    async def reject(
        self,
        refund_request_id: str,
        payload: RefundRequestRejectRequest,
        current_user: Any,
    ) -> RefundRequestResponse:
        refund = await self._require_teacher_refund(refund_request_id, current_user)
        if refund.status != "requested":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Refund request already processed")

        now = datetime.now(UTC)
        refund.status = "rejected"
        refund.reject_reason = payload.reject_reason
        refund.processed_at = now
        await self.db.flush()
        await self.db.refresh(refund)

        await self._notify(
            student_id=refund.student_id,
            notification_type="refundRejected",
            title="환불 요청 반려",
            body="선생님이 환불 요청을 반려했어요. 사유를 확인해주세요.",
            subscription_id=refund.subscription_id,
        )

        return await self._to_response(refund, viewer_role="teacher", now=now)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    async def _teacher_id_for_subscription(self, subscription: Any) -> str:
        from app.models.lesson import ClassMembership, LessonClass

        teacher_id = await self.db.scalar(
            select(LessonClass.teacher_id)
            .join(ClassMembership, ClassMembership.lesson_class_id == LessonClass.id)
            .where(ClassMembership.id == subscription.membership_id)
        )
        if teacher_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription has no owning class")
        return teacher_id

    async def _require_teacher_refund(self, refund_request_id: str, current_user: Any) -> Any:
        from app.models.refund_request import RefundRequest

        if self.access.actor_type(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

        refund = await self.db.get(RefundRequest, refund_request_id)
        if refund is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Refund request not found")
        if refund.teacher_id not in await self.access.teacher_identifiers(current_user):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return refund

    async def _to_response(self, refund: Any, *, viewer_role: str, now: datetime) -> RefundRequestResponse:
        purged = refund.processed_at is not None and (now - _ensure_aware(refund.processed_at)) > timedelta(
            days=ACCOUNT_RETENTION_DAYS
        )

        bank_name: str | None = refund.bank_name
        account_number: str | None = refund.account_number
        account_holder: str | None = refund.account_holder

        if purged:
            bank_name = None
            account_number = None
            account_holder = None
        elif viewer_role == "student":
            account_number = _mask_account_number(refund.account_number)

        estimated = await self._estimate_refund_amount(refund) if refund.status == "requested" else None

        return RefundRequestResponse(
            id=refund.id,
            subscription_id=refund.subscription_id,
            student_id=refund.student_id,
            teacher_id=refund.teacher_id,
            bank_name=bank_name,
            account_number=account_number,
            account_holder=account_holder,
            reason=refund.reason,
            status=refund.status,
            processed_amount=refund.processed_amount,
            reject_reason=refund.reject_reason,
            requested_at=refund.requested_at,
            processed_at=refund.processed_at,
            estimated_refund_amount=estimated,
        )

    async def _estimate_refund_amount(self, refund: Any) -> int | None:
        """참고용 예상 환불액 — 최종 금액은 선생님 재량(``processed_amount`` 직접 입력).

        산식: 단가(수강권 금액 / 총 회차) x 남은 회차 x 비율. 결제일(``paid_at``,
        없으면 ``start_date``) 로부터 정책의 ``full_refund_days`` 이내면 비율
        100%, 이후는 ``partial_refund_ratio``. 총 회차/금액을 알 수 없는
        수강권(개방형 정기결제 등)은 산정 불가로 ``None``.
        """
        from app.models.policy import LessonPolicy
        from app.models.subscription import Subscription

        subscription = await self.db.get(Subscription, refund.subscription_id)
        if subscription is None or subscription.amount is None:
            return None

        remaining = remaining_lessons(subscription)
        if remaining is None:
            return None
        if remaining <= 0:
            return 0

        type_value = getattr(subscription.type, "value", subscription.type)
        unit_lessons = 1 if type_value == "trial" else (subscription.total_lessons or subscription.lessons_per_month)
        if not unit_lessons:
            return None

        policy = await self.db.scalar(
            select(LessonPolicy).where(
                LessonPolicy.teacher_id == refund.teacher_id,
                LessonPolicy.lesson_class_id.is_(None),
            )
        )
        full_refund_days = policy.full_refund_days if policy is not None else 1
        partial_refund_ratio = (policy.partial_refund_ratio if policy is not None else 67) / 100

        reference_date = None
        if subscription.paid_at is not None:
            reference_date = subscription.paid_at.date()
        elif subscription.start_date is not None:
            reference_date = subscription.start_date

        ratio = partial_refund_ratio
        if reference_date is not None and (datetime.now(UTC).date() - reference_date).days <= full_refund_days:
            ratio = 1.0

        unit_price = subscription.amount / unit_lessons
        return round(unit_price * remaining * ratio)

    async def _notify(
        self,
        *,
        notification_type: str,
        title: str,
        body: str,
        subscription_id: str,
        teacher_id: str | None = None,
        student_id: str | None = None,
    ) -> None:
        """Best-effort recipient notification. FK-unsafe recipients are skipped (#1207 precedent)."""
        if teacher_id is not None:
            recipient_user_id = await resolve_teacher_user_id(self.db, teacher_id)
        elif student_id is not None:
            recipient_user_id = await resolve_student_user_id(self.db, student_id)
        else:
            return

        if not recipient_user_id:
            return

        await NotificationService(self.db).create_and_send(
            user_id=recipient_user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            priority=NotificationPriority.high,
            action_url=f"/subscriptions/{subscription_id}",
        )
