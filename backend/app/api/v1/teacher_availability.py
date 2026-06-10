"""Issue #606 — 가용시간 SSOT 마이그레이션 단계 1 (dual-write).

POST /api/v1/teacher/availability/onboarding 가 호출되면 TeacherAvailability
(SSOT) 와 TeacherSettings.available_slots (역호환) 두 저장소에 동시 기록.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_db
from app.models.user import User

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
    from app.models.schedule import AvailabilityTimeSlot, TeacherAvailability
    from app.models.settings import TeacherSettings
    from app.services.teacher_id_resolver import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db, current_user.id)

    # 1. SSOT — 기존 availability 전체 교체.
    existing = await db.scalars(select(TeacherAvailability).where(TeacherAvailability.teacher_id == teacher_id))
    for avail in existing.all():
        child_slots = await db.scalars(
            select(AvailabilityTimeSlot).where(AvailabilityTimeSlot.availability_id == avail.id)
        )
        for slot in child_slots.all():
            await db.delete(slot)
        await db.delete(avail)
    await db.flush()

    schedule_slot_count = 0
    # 요일별 그룹 — 한 day_of_week 당 한 row, 그 안에 여러 time slot.
    by_dow: dict[int, list[OnboardingSlot]] = {}
    for s in body.slots:
        by_dow.setdefault(s.day_of_week, []).append(s)

    for dow, slots in by_dow.items():
        avail = TeacherAvailability(teacher_id=teacher_id, day_of_week=dow)
        db.add(avail)
        await db.flush()
        for s in slots:
            db.add(
                AvailabilityTimeSlot(
                    availability_id=avail.id,
                    start_time=s.start_time,
                    end_time=s.end_time,
                )
            )
            schedule_slot_count += 1
    await db.flush()

    # 2. 역호환 — TeacherSettings.available_slots JSON.
    settings = await db.scalar(select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id))
    if settings is None:
        settings = TeacherSettings(teacher_id=teacher_id)
        db.add(settings)
        await db.flush()
    flat = [{"day_of_week": s.day_of_week, "start_time": s.start_time, "end_time": s.end_time} for s in body.slots]
    settings.available_slots = flat
    await db.flush()

    return OnboardingAvailabilityResponse(
        schedule_slot_count=schedule_slot_count,
        settings_slot_count=len(flat),
    )
