"""Vacation period service (#431 G3 휴가 모드).

Spec: docs/specs/schedule/teacher_vacation_mode.md.

본 모듈 범위:
- 휴가 등록 (POST) — VacationPeriod 생성 + 영향 수강권의 auto_extended_days 자동 증가
- 영향 미리보기 (GET impact) — 기간 입력 시 영향 받는 레슨/학생 집계
- 휴가 목록 (GET) — 활성/취소 분리 + include_cancelled 옵션 (H-001 후속 PR)
- 24h 내 일괄 취소 (DELETE) — auto_extended_days revert + cancelled_at 설정 (H-001 후속 PR)

후속 PR 범위 (본 모듈에 미포함):
- 3 처리 옵션 분기 (makeupCredit / freeCancel / rollForward) 의 실제 후속 작업
- 알림톡 발송 (LNZ_TEACHER_VACATION)
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# Recovery window — spec §7.2
RECOVERY_WINDOW_HOURS = 24

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
    VacationListResponse,
    VacationPeriodCreate,
    VacationPeriodResponse,
)

# Recovery window — spec §7.2
RECOVERY_WINDOW_HOURS = 24

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

        # spec §4.2 — per-student disposition overrides stored as JSON.
        # Effective per-student handling (makeupCredit / freeCancel) is a follow-up.
        per_student = (
            {sid: d.value for sid, d in data.per_student_disposition.items()} if data.per_student_disposition else None
        )

        period = VacationPeriod(
            teacher_id=teacher_id,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            default_disposition=_to_model_disposition(data.default_disposition),
            per_student_disposition=per_student,
        )
        self.db.add(period)
        await self.db.flush()  # need period.id before processing dispositions

        # spec §5 — disposition-aware processing per affected booking.
        override_map = data.per_student_disposition or {}
        await self._apply_dispositions(
            period=period,
            default_disposition=data.default_disposition,
            override_map=override_map,
            vacation_days=vacation_days,
        )

        await self.db.flush()
        await self.db.refresh(period)
        return VacationPeriodResponse.model_validate(period)

    async def _apply_dispositions(
        self,
        *,
        period: VacationPeriod,
        default_disposition: VacationDisposition,
        override_map: dict[str, VacationDisposition],
        vacation_days: int,
    ) -> None:
        """Route every impacted booking through its effective disposition.

        Per-student `override_map` wins over `default_disposition`. rollForward
        bookings stay active and the subscription's `auto_extended_days` grows
        once per impacted subscription. freeCancel / makeupCredit cancel the
        booking and link it back to the period via `vacation_period_id` so
        Recovery can revert it cleanly.
        """
        from app.services.makeup_credit_service import MakeupCreditService

        bookings = await self._impacted_bookings(
            teacher_id=period.teacher_id,
            start_date=period.start_date,
            end_date=period.end_date,
        )
        if not bookings:
            return

        roll_forward_sub_ids: set[str] = set()
        makeup_service: MakeupCreditService | None = None

        for booking in bookings:
            effective = override_map.get(booking.student_id, default_disposition)

            if effective == VacationDisposition.rollForward:
                if booking.subscription_id is not None:
                    roll_forward_sub_ids.add(booking.subscription_id)
                continue

            # freeCancel / makeupCredit both cancel the booking.
            booking.status = BookingStatus.cancelled
            booking.vacation_period_id = period.id

            if effective == VacationDisposition.makeupCredit:
                if makeup_service is None:
                    makeup_service = MakeupCreditService(self.db)
                await makeup_service.accrue_for_vacation(
                    student_id=booking.student_id,
                    teacher_id=period.teacher_id,
                    vacation_id=period.id,
                    vacation_end_date=datetime.combine(period.end_date, datetime.min.time(), tzinfo=UTC),
                    source_lesson_id=booking.id,
                )

        if roll_forward_sub_ids:
            await self._auto_extend_subscriptions(roll_forward_sub_ids, vacation_days)

    # ------------------------------------------------------------------
    # List vacations (read-only)
    # ------------------------------------------------------------------

    async def list_vacations(
        self,
        teacher_id: str,
        *,
        include_cancelled: bool = False,
    ) -> VacationListResponse:
        """Return the teacher's vacation periods (active only by default)."""
        stmt = select(VacationPeriod).where(VacationPeriod.teacher_id == teacher_id)
        if not include_cancelled:
            stmt = stmt.where(VacationPeriod.cancelled_at.is_(None))
        stmt = stmt.order_by(VacationPeriod.start_date.desc())
        periods = list((await self.db.scalars(stmt)).all())
        return VacationListResponse(
            vacations=[VacationPeriodResponse.model_validate(p) for p in periods],
            total_count=len(periods),
        )

    # ------------------------------------------------------------------
    # Cancel vacation (Recovery, spec §7)
    # ------------------------------------------------------------------

    async def cancel_vacation(self, period_id: str, teacher_id: str) -> VacationPeriodResponse:
        """Cancel a vacation within the 24h recovery window.

        Reverts subscription.auto_extended_days that were added by this vacation
        (rollForward disposition). Cannot be undone after the vacation has
        already started or 24h have passed (spec §7.2).
        """
        period = await self.db.get(VacationPeriod, period_id)
        if period is None or period.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vacation not found")
        if period.cancelled_at is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 취소된 휴가입니다.",
            )

        now = datetime.now(UTC)
        created = period.created_at if period.created_at.tzinfo else period.created_at.replace(tzinfo=UTC)
        if (now - created) > timedelta(hours=RECOVERY_WINDOW_HOURS):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"휴가 등록 후 {RECOVERY_WINDOW_HOURS}시간이 지나 취소할 수 없습니다.",
            )
        if period.start_date < now.date():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 시작된 휴가는 취소할 수 없습니다.",
            )

        period.cancelled_at = now
        vacation_days = (period.end_date - period.start_date).days + 1
        await self._revert_dispositions(period=period, vacation_days=vacation_days)

        await self.db.flush()
        await self.db.refresh(period)
        return VacationPeriodResponse.model_validate(period)

    async def _revert_dispositions(
        self,
        *,
        period: VacationPeriod,
        vacation_days: int,
    ) -> None:
        """Undo every disposition this vacation performed.

        - rollForward → subtract `auto_extended_days` from any subscription that
          was paired with a still-active booking when the vacation registered.
        - freeCancel / makeupCredit → restore the booking back to `confirmed`
          and detach `vacation_period_id`. makeup credits keyed by the period
          are removed in bulk.
        """
        from app.models.makeup_credit import MakeupCredit

        # 1) Restore bookings cancelled by this vacation.
        cancelled_bookings = (
            await self.db.scalars(
                select(LessonBooking).where(
                    LessonBooking.vacation_period_id == period.id,
                )
            )
        ).all()
        revived_sub_ids: set[str] = set()
        for booking in cancelled_bookings:
            booking.status = BookingStatus.confirmed
            booking.vacation_period_id = None
            if booking.subscription_id is not None:
                revived_sub_ids.add(booking.subscription_id)

        # 2) Drop accrued credits for this vacation.
        accrued_credits = (
            await self.db.scalars(select(MakeupCredit).where(MakeupCredit.source_event_id == period.id))
        ).all()
        for credit in accrued_credits:
            await self.db.delete(credit)

        # 3) Revert rollForward auto-extend. The legacy path only knew the
        # default disposition; now we revert any subscription whose booking
        # is *still* active inside the window (i.e. survived as rollForward).
        await self._revert_auto_extended_days(
            teacher_id=period.teacher_id,
            start_date=period.start_date,
            end_date=period.end_date,
            vacation_days=vacation_days,
        )

    async def _revert_auto_extended_days(
        self,
        teacher_id: str,
        start_date: date,
        end_date: date,
        vacation_days: int,
    ) -> int:
        """Mirror of _auto_extend_impacted_subscriptions — subtracts the same delta."""
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
            sub.auto_extended_days = max(0, (sub.auto_extended_days or 0) - vacation_days)
        return len(subscriptions)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    async def _impacted_bookings(
        self,
        *,
        teacher_id: str,
        start_date: date,
        end_date: date,
    ) -> list[LessonBooking]:
        result = await self.db.scalars(
            select(LessonBooking)
            .where(LessonBooking.teacher_id == teacher_id)
            .where(LessonBooking.scheduled_date >= start_date)
            .where(LessonBooking.scheduled_date <= end_date)
            .where(LessonBooking.status.in_(_ACTIVE_BOOKING_STATUSES))
        )
        return list(result.all())

    async def _auto_extend_subscriptions(
        self,
        subscription_ids: set[str],
        vacation_days: int,
    ) -> int:
        """Add vacation_days to auto_extended_days for the given subscriptions."""
        if not subscription_ids:
            return 0
        subscriptions = (await self.db.scalars(select(Subscription).where(Subscription.id.in_(subscription_ids)))).all()
        for sub in subscriptions:
            sub.auto_extended_days = (sub.auto_extended_days or 0) + vacation_days
        return len(subscriptions)

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
