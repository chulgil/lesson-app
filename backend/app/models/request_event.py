"""RequestEvent SSOT model — backend port of frontend Hive entity.

Frontend SSOT: `frontend/lib/features/schedule/domain/entities/request_event.dart`
- RequestEventType (Hive typeId 130) — 31 values
- RequestEvent (Hive typeId 131) — 14 fields
- ScheduleChangeType (Hive typeId 132) — 2 values

Plan A Phase 1 (Issue #235, audit P0-2/P0-4).
"""

# ruff: noqa: N815, UP042

import enum

from sqlalchemy import JSON, Boolean, Enum, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class RequestEventType(str, enum.Enum):
    """31 event types in a lesson request lifecycle (chat history)."""

    # Phase 1 — 레슨 신청
    initialRequest = "initialRequest"
    approve = "approve"
    reject = "reject"
    proposeAlternative = "proposeAlternative"
    counterPropose = "counterPropose"
    acceptAlternative = "acceptAlternative"
    cancel = "cancel"
    expire = "expire"
    proposalSent = "proposalSent"
    proposalAccepted = "proposalAccepted"
    paymentNotified = "paymentNotified"
    completed = "completed"
    withdrawApproval = "withdrawApproval"

    # Phase 2 — 수강권 & 결제
    paymentRequested = "paymentRequested"
    paymentConfirmed = "paymentConfirmed"
    subscriptionIssued = "subscriptionIssued"

    # Phase 3 — 레슨 진행
    lessonCompleted = "lessonCompleted"
    lessonCancelled = "lessonCancelled"
    scheduleChanged = "scheduleChanged"
    lessonNoteAdded = "lessonNoteAdded"
    subscriptionRenewed = "subscriptionRenewed"
    subscriptionCompleted = "subscriptionCompleted"

    # Phase 3 — 스케줄 변경 협상
    scheduleChangeProposed = "scheduleChangeProposed"
    scheduleChangeAccepted = "scheduleChangeAccepted"
    scheduleChangeRejected = "scheduleChangeRejected"
    scheduleChangeCountered = "scheduleChangeCountered"

    # General
    message = "message"

    # Phase 3 — 레슨 취소 확정 + 크레딧 반환
    lessonCancellationConfirmed = "lessonCancellationConfirmed"
    cancellationCreditRefunded = "cancellationCreditRefunded"

    # Phase 3 — 선생님 일괄 작업
    lesson_cancelled_by_teacher = "lessonCancelledByTeacher"
    teacher_announcement = "teacherAnnouncement"


class ScheduleChangeType(str, enum.Enum):
    """Schedule change scope — 1회성 vs 일괄."""

    singleLesson = "singleLesson"
    bulkChange = "bulkChange"


class RequestEvent(UUIDMixin, TimestampMixin, Base):
    """A single event in a lesson request's history (chat message).

    1:1 mapping with frontend Hive RequestEvent (typeId 131).
    Replaces legacy time_proposals JSON dump (deprecated in Plan A Phase 4).
    """

    __tablename__ = "request_events"

    request_id: Mapped[str] = mapped_column(String(36), nullable=False)
    actor_type: Mapped[str] = mapped_column(String(20), nullable=False)
    actor_id: Mapped[str] = mapped_column(String(36), nullable=False)
    event_type: Mapped[RequestEventType] = mapped_column(
        Enum(RequestEventType, native_enum=True),
        nullable=False,
    )
    suggested_slots: Mapped[list | None] = mapped_column(JSON, nullable=True)
    selected_slot_index: Mapped[int | None] = mapped_column(Integer, nullable=True)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)

    schedule_change_type: Mapped[ScheduleChangeType | None] = mapped_column(
        Enum(ScheduleChangeType, native_enum=True),
        nullable=True,
    )
    proposed_day_of_week: Mapped[int | None] = mapped_column(Integer, nullable=True)
    proposed_time: Mapped[str | None] = mapped_column(String(5), nullable=True)

    subscription_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("subscriptions.id"), nullable=True)
    session_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    change_credit_used: Mapped[int | None] = mapped_column(Integer, nullable=True)
    change_credit_remaining_after: Mapped[int | None] = mapped_column(Integer, nullable=True)
    keeps_session_number: Mapped[bool | None] = mapped_column(Boolean, nullable=True)

    __table_args__ = (
        Index("idx_request_events_request_id", "request_id"),
        Index("idx_request_events_event_type", "event_type"),
        Index("idx_request_events_request_created", "request_id", "created_at"),
        Index(
            "idx_request_events_subscription_session_created",
            "subscription_id",
            "session_number",
            "created_at",
        ),
    )
