"""Vacation period service (#431 G3 휴가 모드).

Spec: docs/specs/schedule/teacher_vacation_mode.md.

본 모듈은 1차 BE 작업 범위만 포함:
- 휴가 등록 (POST) — VacationPeriod 생성 + 영향 수강권의 auto_extended_days 자동 증가
- 영향 미리보기 (GET impact) — 기간 입력 시 영향 받는 레슨/학생 집계

후속 PR 범위 (본 모듈에 미포함):
- 3 처리 옵션 분기 (makeupCredit / freeCancel / rollForward) 의 실제 후속 작업
- 알림톡 발송 (LNZ_TEACHER_VACATION)
- 24h 내 일괄 취소 (DELETE)
"""

from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.schedule import (
    BookingStatus,
    LessonBooking,
    VacationPeriod,
)
from app.models.schedule import (
    VacationDisposition as VacationDispositionModel,
)
from app.models.student import Student
from app.models.subscription import Subscription
from app.schemas.vacation import (
    VacationDisposition,
    VacationImpactedStudent,
    VacationImpactPreview,
    VacationPeriodCreate,
    VacationPeriodResponse,
)

# Booking statuses considered "active" — i.e. would be impacted by a vacation
_ACTIVE_BOOKING_STATUSES: tuple[BookingStatus, ...] = (
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.changeRequested,
)


class VacationService:
    """Handle vacation period registration and impact analysis."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Impact preview (read-only)
    # ------------------------------------------------------------------

    async def preview_impact(
        self,
        teacher_id: str,
        start_date: date,
        end_date: date,
    ) -> VacationImpactPreview:
        """Return the lesson/student impact summary for a candidate period.

        Spec §4.1 step 2 — used by the registration UI before confirming.
        """
        if end_date < start_date:
            raise ValueError("end_date must be >= start_date")

        bookings = (
            await self.db.scalars(
                select(LessonBooking)
                .where(LessonBooking.teacher_id == teacher_id)
                .where(LessonBooking.scheduled_date >= start_date)
                .where(LessonBooking.scheduled_date <= end_date)
                .where(LessonBooking.status.in_(_ACTIVE_BOOKING_STATUSES))
            )
        ).all()

        by_student: dict[str, int] = {}
        for booking in bookings:
            by_student[booking.student_id] = by_student.get(booking.student_id, 0) + 1

        students_meta = await self._load_student_names(list(by_student.keys()))
        impacted = [
            VacationImpactedStudent(
                student_id=sid,
                student_name=students_meta.get(sid),
                lesson_count=count,
            )
            for sid, count in sorted(by_student.items(), key=lambda kv: -kv[1])
        ]

        return VacationImpactPreview(
            start_date=start_date,
            end_date=end_date,
            impacted_lesson_count=len(bookings),
            impacted_student_count=len(by_student),
            impacted_students=impacted,
        )

    # ------------------------------------------------------------------
    # Register vacation (mutating)
    # ------------------------------------------------------------------

    async def register_vacation(
        self,
        teacher_id: str,
        data: VacationPeriodCreate,
    ) -> VacationPeriodResponse:
        """Create a VacationPeriod and auto-extend impacted subscriptions.

        Spec §5.3: rollForward (default) — 영향 받는 수강권의
        auto_extended_days += vacation_days.

        본 1차 작업은 rollForward 의 만료일 자동 연장만 수행한다.
        makeupCredit / freeCancel 의 실제 처리 (MakeupCredit 적립, 레슨 취소)는
        후속 PR.
        """
        vacation_days = (data.end_date - data.start_date).days + 1
        if vacation_days <= 0:
            raise ValueError("vacation period must cover at least 1 day")

        period = VacationPeriod(
            teacher_id=teacher_id,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            default_disposition=_to_model_disposition(data.default_disposition),
        )
        self.db.add(period)

        if data.default_disposition == VacationDisposition.rollForward:
            await self._auto_extend_impacted_subscriptions(
                teacher_id=teacher_id,
                start_date=data.start_date,
                end_date=data.end_date,
                vacation_days=vacation_days,
            )

        await self.db.flush()
        await self.db.refresh(period)
        return VacationPeriodResponse.model_validate(period)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    async def _auto_extend_impacted_subscriptions(
        self,
        teacher_id: str,
        start_date: date,
        end_date: date,
        vacation_days: int,
    ) -> int:
        """Increase auto_extended_days for subscriptions tied to impacted bookings.

        Returns the number of subscriptions updated.
        Spec §5.3: Subscription.autoExtendedDays += vacation_days.
        """
        bookings = (
            await self.db.scalars(
                select(LessonBooking)
                .where(LessonBooking.teacher_id == teacher_id)
                .where(LessonBooking.scheduled_date >= start_date)
                .where(LessonBooking.scheduled_date <= end_date)
                .where(LessonBooking.status.in_(_ACTIVE_BOOKING_STATUSES))
            )
        ).all()

        impacted_subscription_ids = {b.subscription_id for b in bookings if b.subscription_id is not None}
        if not impacted_subscription_ids:
            return 0

        subscriptions = (
            await self.db.scalars(select(Subscription).where(Subscription.id.in_(impacted_subscription_ids)))
        ).all()

        for sub in subscriptions:
            sub.auto_extended_days = (sub.auto_extended_days or 0) + vacation_days

        return len(subscriptions)

    async def _load_student_names(self, student_ids: list[str]) -> dict[str, str]:
        """Resolve student id → display name for impact preview."""
        if not student_ids:
            return {}
        rows = (await self.db.scalars(select(Student).where(Student.id.in_(student_ids)))).all()
        return {s.id: s.name for s in rows}


def _to_model_disposition(value: VacationDisposition) -> VacationDispositionModel:
    """Schema-enum → ORM-enum (same string value, but distinct Python classes)."""
    return VacationDispositionModel(value.value)
