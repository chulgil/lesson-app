"""Makeup credit API schemas (#432).

Spec: docs/specs/subscription/makeup_credit_spec.md §8.
FE: frontend/lib/features/subscription/data/repositories/remote_makeup_credit_repository.dart
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field


class MakeupCreditReason(str, enum.Enum):
    """Mirrors backend.app.models.makeup_credit.MakeupCreditReason for API I/O."""

    teacherVacation = "teacherVacation"
    noShowExempt = "noShowExempt"
    bulkChangeLoss = "bulkChangeLoss"
    manualGrant = "manualGrant"
    fifthWeekBonus = "fifthWeekBonus"


class MakeupCreditResponse(BaseModel):
    """One makeup credit returned to the client. Snake-case matches FE wire format."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    student_id: str
    teacher_id: str
    source_subscription_id: str | None = None
    reason: MakeupCreditReason
    created_at: _dt.datetime
    expires_at: _dt.datetime
    used_at: _dt.datetime | None = None
    used_lesson_id: str | None = None
    source_event_id: str | None = None


class MakeupCreditListResponse(BaseModel):
    """Spec §8.1 GET responses — `{credits: [...]}`."""

    credits: list[MakeupCreditResponse] = []


class MakeupCreditGrantRequest(BaseModel):
    """Spec §8.1 POST body — teacher grant.

    Two reasons a teacher can trigger from this endpoint:
    - manualGrant (default, §4.4 safety net)
    - noShowExempt (§4.2 discretionary no-show exemption) — requires `lesson_id`
    """

    student_id: str
    source_subscription_id: str | None = None
    reason_note: str | None = Field(default=None, max_length=500)
    reason: MakeupCreditReason = MakeupCreditReason.manualGrant
    lesson_id: str | None = Field(
        default=None,
        description="Required when reason=noShowExempt (spec §4.2 sourceEventId).",
    )
