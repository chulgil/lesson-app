"""Issue #606 — 가용시간 SSOT 마이그레이션 단계 1 (dual-write).

POST /api/v1/teacher/availability/onboarding 가 호출되면 TeacherAvailability
(SSOT) 와 TeacherSettings.available_slots (역호환) 두 저장소에 동시 기록.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.services.availability_service import AvailabilityService
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


class OnboardingSlot(BaseModel):
    """단일 슬롯 — 요일 + 시작/종료 시각."""

    day_of_week: int  # 0=Mon ... 6=Sun
    start_time: str  # HH:MM
    end_time: str  # HH:MM


class OnboardingAvailabilityRequest(BaseModel):
    slots: list[OnboardingSlot]


class OnboardingAvailabilityResponse(BaseModel):
    """dual-write 결과 카운트."""

    schedule_slot_count: int
    settings_slot_count: int


@router.post(
    "/availability/onboarding",
    response_model=OnboardingAvailabilityResponse,
    status_code=status.HTTP_200_OK,
    summary="Dual-write onboarding availability (Issue #606)",
)
async def onboarding_availability(
    body: OnboardingAvailabilityRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> OnboardingAvailabilityResponse:
    """spec teacher-quest-system §6.3 단계 1 — 두 저장소 동시 기록.

    - TeacherAvailability + AvailabilityTimeSlot (SSOT)
    - TeacherSettings.available_slots (역호환 — JSON 평면 list)
    """
    teacher_id = await resolve_teacher_id(db, current_user.id)
    svc = AvailabilityService(db)
    schedule_slot_count, settings_slot_count = await svc.onboarding_dual_write(
        teacher_id=teacher_id,
        slots=body.slots,
    )
    return OnboardingAvailabilityResponse(
        schedule_slot_count=schedule_slot_count,
        settings_slot_count=settings_slot_count,
    )
