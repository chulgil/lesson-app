"""Lesson and lesson-class service."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from typing import Any, NamedTuple

from fastapi import HTTPException, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.date_utils import to_date
from app.schemas.common import PaginatedResponse
from app.schemas.lesson import (
    LessonClassCreate,
    LessonClassResponse,
    LessonClassUpdate,
    LessonCreate,
    LessonFeedbackUpdate,
    LessonResponse,
    LessonSlotPayload,
    LessonUpdate,
    MembershipCreate,
    MembershipResponse,
    MembershipUpdate,
)
from app.services.teacher_id_resolver import resolve_teacher_id

# #1167 — default body when a teacher grants no custom compensation message.
_DEFAULT_COMPENSATION_MESSAGE = "지각 취소로 다음 레슨에 보너스 연습시간을 제공해 드립니다."


class _LateCancelCompensation(NamedTuple):
    """Resolved compensation policy for a late student cancellation (#1167).

    The policy is snapshotted on ``academy_subscriptions`` for academy-owned
    subscriptions; otherwise the teacher-default values (matching the
    ``CancellationDefaults`` FE entity defaults) apply. The per-teacher toggle
    for non-academy teachers is stored client-side only, so the backend cannot
    honour a non-academy teacher's toggle-off without a schema change.
    """

    enabled: bool
    include_text: bool
    message: str
    notify_owner: bool
    owner_user_id: str | None


class LessonService:
    """Handle lesson and lesson-class business logic."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Lessons
    # ------------------------------------------------------------------

    async def get_all(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        date: str | None = None,
        date_from: str | None = None,
        date_to: str | None = None,
        status: str | None = None,
    ) -> PaginatedResponse[LessonResponse]:
        """List lessons with filters."""
        from app.models.lesson import Lesson

        tid = await resolve_teacher_id(self.db, user.id)
        query = select(Lesson).where(Lesson.teacher_id == tid, Lesson.is_archived == False)  # noqa: E712
        if student_id:
            query = query.where(Lesson.student_id == student_id)
        if date:
            query = query.where(Lesson.date == to_date(date))
        if date_from:
            query = query.where(Lesson.date >= to_date(date_from))
        if date_to:
            query = query.where(Lesson.date <= to_date(date_to))
        if status:
            query = query.where(Lesson.status == status)

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.order_by(Lesson.date.desc()).offset(offset).limit(size))
        items = [LessonResponse.model_validate(lesson) for lesson in result.all()]

        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create(self, data: LessonCreate, current_user: Any) -> LessonResponse:
        """Create a new lesson."""
        from app.models.lesson import Lesson, LessonSource
        from app.models.student import Student
        from app.services.user_service import UserService

        tid = await resolve_teacher_id(self.db, current_user.id)

        student_name = data.student_id
        student = None
        if data.student_id:
            student = await self.db.get(Student, data.student_id)
            if student:
                if student.teacher_id != tid:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Student access denied",
                    )
                student_name = student.name

        # 0702 audit M4: defense-in-depth against API-direct double booking.
        # Same conflict semantics as the #301 recurring path (active lessons +
        # bookings only); vacation/operating-hours stay FE-advisory so the
        # teacher's manual create remains an intentional override.
        from app.services.schedule_confirmation_service import ScheduleConfirmationService

        has_conflict = await ScheduleConfirmationService(self.db).check_time_conflict(
            teacher_id=tid,
            scheduled_date=data.date,
            scheduled_time=data.start_time or "00:00",
            duration=data.duration,
        )
        if has_conflict:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Lesson time conflicts with an existing lesson or booking",
            )

        subscription_id = data.subscription_id
        if subscription_id:
            await self._assert_subscription_matches_lesson(
                subscription_id=subscription_id,
                student_id=data.student_id,
            )

        is_preview = False
        makeup_credit_id: str | None = None
        if data.overflow_mode is not None:
            subscription_id, is_preview, makeup_credit_id = await self._apply_overflow_mode(
                mode=data.overflow_mode,
                subscription_id=subscription_id,
                student_id=data.student_id,
                teacher_id=tid,
            )
        elif not subscription_id:
            # Auto-find or create subscription
            subscription_id = await self._find_or_create_subscription(
                teacher_id=tid,
                student_id=data.student_id,
                lesson_date=data.date,
            )

        session_number = data.session_number
        # Preview lessons get their session number on renewal confirmation; credit
        # lessons never get one — makeup sessions stay outside the regular count
        # (makeup_credit_spec §2 "보강 회차는 정규 수강권에서 분리").
        if subscription_id and not is_preview and makeup_credit_id is None:
            if session_number is None:
                session_number = await self._next_subscription_session_number(subscription_id)

        lesson = Lesson(
            teacher_id=tid,
            student_id=data.student_id,
            student_name=student_name,
            instrument=data.instrument or "",
            date=data.date,
            start_time=data.start_time or "00:00",
            duration=data.duration,
            subscription_id=subscription_id,
            session_number=session_number,
            location_name=data.location_name,
            lesson_source=LessonSource.manual,
            is_preview=is_preview,
        )
        self.db.add(lesson)
        await self.db.flush()
        await self.db.refresh(lesson)

        if makeup_credit_id is not None:
            # §5.3 side-effects: stamp used_at / used_lesson_id. The completion
            # deduction path skips credit-funded lessons (see _deduct_if_completed).
            from app.services.makeup_credit_service import MakeupCreditService

            try:
                await MakeupCreditService(self.db).use_credit(credit_id=makeup_credit_id, lesson_id=lesson.id)
            except ValueError as exc:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=str(exc),
                ) from exc

        await UserService(self.db).complete_onboarding_quest(current_user, "teacher.firstLesson")

        # Notify student about new lesson. Preview lessons stay silent — the
        # renewal proposal is the student-facing message for that flow.
        if student and student.user_id and not is_preview:
            from app.services.notification_service import NotificationPriority, NotificationService

            notification_service = NotificationService(self.db)
            await notification_service.create_and_send(
                user_id=student.user_id,
                notification_type="lessonBooked",
                title="새 레슨이 등록되었습니다",
                body=f"{data.date} 레슨이 등록되었습니다",
                priority=NotificationPriority.normal,
                action_url=f"/lessons/{lesson.id}",
                action_label="레슨 확인",
            )

        return LessonResponse.model_validate(lesson)

    async def _assert_subscription_matches_lesson(self, *, subscription_id: str, student_id: str) -> None:
        """Ensure a lesson cannot point at another student's subscription."""
        from app.models.subscription import Subscription

        subscription = await self.db.get(Subscription, subscription_id)
        if subscription is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
        if subscription.student_id != student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="subscription_id does not belong to student_id",
            )

    async def _apply_overflow_mode(
        self, *, mode: str, subscription_id: str | None, student_id: str, teacher_id: str
    ) -> tuple[str, bool, str | None]:
        """Resolve the target subscription for an explicit overflow mode.

        subscription_required_spec §2.6.2 — called only when the FE sent
        ``overflow_mode`` (S3 sheet / S4 toggle). The legacy silent path
        (auto bonus in ``_find_or_create_subscription``) stays untouched.
        Returns ``(subscription_id, is_preview, makeup_credit_id)`` —
        ``makeup_credit_id`` is consumed by the caller after the lesson row
        exists (``use_credit`` needs the lesson id).
        """
        from app.models.subscription import Subscription, SubscriptionStatus

        async def _latest_active_subscription() -> Any:
            return (
                await self.db.execute(
                    select(Subscription)
                    .where(
                        Subscription.student_id == student_id,
                        Subscription.status == SubscriptionStatus.active,
                    )
                    .order_by(Subscription.created_at.desc())
                    .limit(1)
                )
            ).scalar_one_or_none()

        if mode == "makeup_credit":
            # S4 — allowed regardless of remaining sessions (§5.4). FIFO credit,
            # lesson attaches to the credit's source subscription first.
            from app.services.makeup_credit_service import MakeupCreditService

            credits = await MakeupCreditService(self.db).list_active_credits(
                student_id=student_id,
                teacher_id=teacher_id,
                limit=1,
            )
            if not credits:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="No active makeup credit available",
                )
            credit = credits[0]

            sub_id = subscription_id or credit.source_subscription_id
            if sub_id is None:
                latest = await _latest_active_subscription()
                sub_id = latest.id if latest else None
            if sub_id is None:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="overflow_mode requires a subscription to attach the lesson to",
                )
            return sub_id, False, credit.id

        sub = (
            await self.db.get(Subscription, subscription_id) if subscription_id else await _latest_active_subscription()
        )
        if sub is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="overflow_mode requires an active subscription",
            )

        from app.services.subscription_service import remaining_lessons

        remaining = remaining_lessons(sub)
        if remaining is None or remaining > 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="overflow_mode requires an exhausted subscription",
            )

        if mode == "bonus":
            # bonus_count only — total_lessons stays the paid base. Bumping both
            # double-counted the bonus in remaining (= total + bonus - used).
            sub.bonus_count = (sub.bonus_count or 0) + 1
            if not sub.bonus_reason:
                sub.bonus_reason = "teacher_goodwill"
            await self.db.flush()
            return sub.id, False, None

        # renewal_pending: preview lesson only — no counter mutation.
        return sub.id, True, None

    async def _assert_trial_regeneration_allowed(self, student_id: str) -> None:
        """§2.6.5 (D2) — an app-connected student gets exactly one auto trial.

        A prior zero-amount trial subscription for this student means the free
        pass was already used; the FE shows the issue-subscription CTA instead
        (S6). Unconnected (manual) students are exempt (§2.7, D4) — lightweight
        schedule-keeping stays possible without forcing a paid subscription.
        Students are teacher-owned rows, so student_id already scopes the check.
        """
        from app.models.student import Student
        from app.models.subscription import Subscription, SubscriptionType

        prior_trial = await self.db.scalar(
            select(Subscription.id)
            .where(
                Subscription.student_id == student_id,
                Subscription.type == SubscriptionType.trial,
                Subscription.amount == 0,
            )
            .limit(1)
        )
        if prior_trial is None:
            return
        student = await self.db.get(Student, student_id)
        if student is not None and student.connected_at is not None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="trial_already_used",
            )

    async def _find_or_create_subscription(self, *, teacher_id: str, student_id: str, lesson_date: date | None) -> str:
        """Find active subscription for the student or create a trial one.

        If the active subscription has no remaining lessons (bonus included),
        auto-expand it as a bonus lesson (bonus_count += 1).
        """
        from app.models.subscription import Subscription, SubscriptionStatus
        from app.services.subscription_service import remaining_lessons

        active_sub = (
            await self.db.execute(
                select(Subscription)
                .where(
                    Subscription.student_id == student_id,
                    Subscription.status == SubscriptionStatus.active,
                )
                .order_by(Subscription.created_at.desc())
                .limit(1)
            )
        ).scalar_one_or_none()

        if active_sub:
            remaining = remaining_lessons(active_sub)
            if remaining is not None and remaining <= 0:
                # Bonus lesson: bonus_count only — total_lessons stays the paid
                # base (bumping both double-counted the bonus in remaining).
                active_sub.bonus_count = (active_sub.bonus_count or 0) + 1
                if not active_sub.bonus_reason:
                    active_sub.bonus_reason = "teacher_goodwill"
                await self.db.flush()
            return active_sub.id

        await self._assert_trial_regeneration_allowed(student_id)

        return await self._create_trial_subscription(
            teacher_id=teacher_id,
            student_id=student_id,
            lesson_date=lesson_date,
        )

    async def _create_trial_subscription(self, *, teacher_id: str, student_id: str, lesson_date: date | None) -> str:
        """Create a 1-lesson trial subscription for auto-assignment."""
        from app.models.subscription import Subscription, SubscriptionStatus, SubscriptionType

        membership_id = await self._find_or_create_class_membership(teacher_id, student_id)

        end_date = (lesson_date + timedelta(days=30)) if lesson_date else None

        sub = Subscription(
            student_id=student_id,
            membership_id=membership_id,
            type=SubscriptionType.trial,
            total_lessons=1,
            used_lessons=0,
            amount=0,
            start_date=lesson_date,
            end_date=end_date,
            status=SubscriptionStatus.active,
            payment_confirmed=True,
            total_reschedule_allowance=0,
        )
        self.db.add(sub)
        await self.db.flush()
        await self.db.refresh(sub)
        return sub.id

    async def _find_or_create_class_membership(self, teacher_id: str, student_id: str) -> str:
        """Find existing ClassMembership or create one via a default private class."""
        from app.models.lesson import ClassMembership, LessonClass

        existing = await self.db.scalar(
            select(ClassMembership.id)
            .join(LessonClass, LessonClass.id == ClassMembership.lesson_class_id)
            .where(
                LessonClass.teacher_id == teacher_id,
                ClassMembership.student_id == student_id,
                ClassMembership.status.in_(["active", "trial"]),
            )
        )
        if existing:
            return existing

        default_class = await self.db.scalar(
            select(LessonClass).where(
                LessonClass.teacher_id == teacher_id,
                LessonClass.type == "private",
                LessonClass.is_archived == False,  # noqa: E712
            )
        )
        if default_class is None:
            default_class = LessonClass(
                teacher_id=teacher_id,
                name="개인 레슨",
                type="private",
            )
            self.db.add(default_class)
            await self.db.flush()
            await self.db.refresh(default_class)

        membership = ClassMembership(
            lesson_class_id=default_class.id,
            student_id=student_id,
            instrument="",
            status="active",
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return membership.id

    async def _next_subscription_session_number(self, subscription_id: str) -> int:
        """Return the next stable session number for a subscription-linked lesson."""
        from app.models.lesson import Lesson

        max_session = await self.db.scalar(
            select(func.max(Lesson.session_number)).where(
                Lesson.subscription_id == subscription_id,
                Lesson.session_number.is_not(None),
            )
        )
        if max_session is not None:
            return int(max_session) + 1

        existing_count = await self.db.scalar(select(func.count()).where(Lesson.subscription_id == subscription_id))
        return int(existing_count or 0) + 1

    async def get_by_id(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Return a lesson by ID."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        return LessonResponse.model_validate(lesson)

    async def update(self, lesson_id: str, data: LessonUpdate, current_user: Any) -> LessonResponse:
        """Update a lesson."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)

        # Capture the schedule before mutation so a genuine reschedule can be
        # distinguished from a no-op edit (#1131).
        old_date = lesson.date
        old_start_time = lesson.start_time

        update_data = data.model_dump(exclude_unset=True, exclude={"pieces"})
        for key, value in update_data.items():
            setattr(lesson, key, value)
        await self.db.flush()
        await self.db.refresh(lesson)

        # Notify the counterparty only when the date or start time actually
        # changed; same-value edits send nothing.
        if lesson.date != old_date or lesson.start_time != old_start_time:
            await self._notify_lesson_counterparty(
                lesson,
                current_user,
                notification_type="lessonRescheduled",
                title="레슨 일정이 변경되었습니다",
                body=f"{old_date} {old_start_time} → {lesson.date} {lesson.start_time} 로 변경되었습니다",
            )

        # NOTE: LessonUpdate has no ``status`` field — status transitions (and
        # thus completion deduction) only happen via ``update_status``.
        return LessonResponse.model_validate(lesson)

    async def _deduct_if_completed(self, lesson: Any) -> None:
        """Deduct one subscription session for a completed lesson.

        Shared entry point for manual (``update`` / ``update_status``) and auto
        completion. Relies on ``SubscriptionService.deduct_for_completed_lesson``
        being idempotent (skips when a usage row already exists for the lesson),
        so re-saving an already-completed lesson never double-deducts. Only
        ``completed`` deducts; 휴강/취소 statuses do not call this.
        """
        if not lesson.subscription_id:
            return
        # §2.6.2 — a preview lesson is not a real session until renewal
        # confirmation promotes it; completing it early must never deduct.
        # (Without this, a bonus expansion reviving the exhausted subscription
        # opens a mis-deduction path.)
        if getattr(lesson, "is_preview", False):
            return
        # makeup_credit_spec §5.3 — a credit-funded lesson already consumed a
        # MakeupCredit; completing it must not touch the regular counter. The
        # credit link (used_lesson_id) is the marker (§2.6.6 — no lesson-type enum).
        from app.models.makeup_credit import MakeupCredit

        credit_funded = await self.db.scalar(
            select(MakeupCredit.id).where(MakeupCredit.used_lesson_id == lesson.id).limit(1)
        )
        if credit_funded:
            return
        from app.services.subscription_service import SubscriptionService

        await SubscriptionService(self.db).deduct_for_completed_lesson(lesson.id, lesson.subscription_id)

    async def delete(self, lesson_id: str, current_user: Any) -> None:
        """Delete a lesson.

        LessonPiece/LessonRecording have no FK on lesson_id (so no ON DELETE
        CASCADE), so they're explicitly cleaned up here to avoid orphaned rows.
        """
        from app.models.lesson import LessonPiece, LessonRecording

        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        await self.db.execute(delete(LessonPiece).where(LessonPiece.lesson_id == lesson_id))
        await self.db.execute(delete(LessonRecording).where(LessonRecording.lesson_id == lesson_id))
        await self.db.delete(lesson)
        await self.db.flush()

    async def update_status(self, lesson_id: str, new_status: str, current_user: Any) -> LessonResponse:
        """Change lesson status."""
        from app.models.lesson import LessonStatus
        from app.models.request_event import RequestEvent, RequestEventType

        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        try:
            lesson.status = LessonStatus(new_status)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=f"Invalid lesson status: {new_status}",
            )

        # Phase 3 event logging
        role = getattr(getattr(current_user, "role", None), "value", None) or "teacher"
        if new_status == LessonStatus.completed.value:
            self.db.add(
                RequestEvent(
                    request_id=lesson.id,
                    actor_type=role,
                    actor_id=current_user.id,
                    event_type=RequestEventType.lessonCompleted,
                    subscription_id=lesson.subscription_id,
                )
            )
        elif new_status.startswith("cancelled") or new_status in (
            LessonStatus.noShow.value,
            LessonStatus.studentAbsent.value,
        ):
            self.db.add(
                RequestEvent(
                    request_id=lesson.id,
                    actor_type=role,
                    actor_id=current_user.id,
                    event_type=RequestEventType.lessonCancelled,
                    subscription_id=lesson.subscription_id,
                    message=new_status,
                )
            )
            # #1167 — late student cancel: resolve compensation policy so the
            # cancellation notice can echo the promise when the teacher opted in.
            compensation = (
                await self._resolve_late_cancel_compensation(lesson)
                if new_status == LessonStatus.cancelledByStudentLate.value
                else None
            )
            cancel_body = f"{lesson.date} {lesson.start_time} 레슨이 취소되었습니다"
            if compensation is not None and compensation.enabled and compensation.include_text:
                cancel_body = f"{cancel_body}\n{compensation.message}"
            await self._notify_lesson_counterparty(
                lesson,
                current_user,
                notification_type="lessonCancelled",
                title="레슨이 취소되었습니다",
                body=cancel_body,
            )
            if compensation is not None:
                await self._send_late_cancel_compensation(lesson, compensation)

        await self.db.flush()
        await self.db.refresh(lesson)

        # Unified completion deduction (product-approved 2026-06-04): manual and
        # auto completion both deduct one session.
        if new_status == LessonStatus.completed.value:
            await self._deduct_if_completed(lesson)
        elif new_status in (LessonStatus.noShow.value, LessonStatus.cancelledByStudentLate.value):
            # LessonPolicy.no_show_deducts_lesson / late_cancel_deducts_lesson: the
            # cancellation/no-show itself is never blocked, but a configured penalty
            # deducts a session. No LessonPolicy row for the teacher -> no deduction
            # (safe default, no behavior change for teachers who never configured one).
            await self._deduct_if_policy_penalty(lesson, new_status)

        return LessonResponse.model_validate(lesson)

    async def _deduct_if_policy_penalty(self, lesson: Any, new_status: str) -> None:
        """Deduct one subscription session for a no-show/late-cancel penalty.

        Reuses the same idempotent, user-agnostic deduction path as completion
        (SubscriptionService.deduct_for_completed_lesson) — it locks the
        subscription row and skips if a usage row already exists for this
        lesson_id, so re-saving the same status never double-deducts.
        """
        from app.models.lesson import LessonStatus
        from app.models.policy import LessonPolicy

        if not lesson.subscription_id or not lesson.teacher_id:
            return

        policy = await self.db.scalar(
            select(LessonPolicy).where(
                LessonPolicy.teacher_id == lesson.teacher_id,
                LessonPolicy.lesson_class_id.is_(None),
            )
        )
        if policy is None:
            return

        penalty_enabled = (
            policy.no_show_deducts_lesson
            if new_status == LessonStatus.noShow.value
            else policy.late_cancel_deducts_lesson
        )
        if not penalty_enabled:
            return

        from app.services.subscription_service import SubscriptionService

        await SubscriptionService(self.db).deduct_for_completed_lesson(lesson.id, lesson.subscription_id)

    async def archive(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Archive a lesson from active lesson lists."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        lesson.is_archived = True
        lesson.archived_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def unarchive(self, lesson_id: str, current_user: Any) -> LessonResponse:
        """Restore an archived lesson."""
        lesson = await self._get_accessible_lesson(lesson_id, current_user)
        lesson.is_archived = False
        lesson.archived_at = None
        await self.db.flush()
        await self.db.refresh(lesson)
        return LessonResponse.model_validate(lesson)

    async def update_feedback(self, lesson_id: str, data: LessonFeedbackUpdate, current_user: Any) -> LessonResponse:
        """Write or update feedback for a lesson."""
        from app.models.request_event import RequestEvent, RequestEventType
        from app.services.user_service import UserService

        lesson = await self._get_accessible_lesson(lesson_id, current_user)

        if data.feedback is not None:
            lesson.feedback = data.feedback
        if data.practice_tips is not None:
            lesson.practice_tips = data.practice_tips

        await UserService(self.db).complete_onboarding_quest(current_user, "teacher.firstNote")

        # Phase 3 event logging
        self.db.add(
            RequestEvent(
                request_id=lesson.id,
                actor_type="teacher",
                actor_id=current_user.id,
                event_type=RequestEventType.lessonNoteAdded,
                subscription_id=lesson.subscription_id,
            )
        )

        await self.db.flush()
        await self.db.refresh(lesson)

        # Notify student about new feedback
        if lesson.student_id:
            from app.models.student import Student
            from app.services.notification_service import NotificationPriority, NotificationService

            student = await self.db.get(Student, lesson.student_id)
            if student and student.user_id:
                notification_service = NotificationService(self.db)
                await notification_service.create_and_send(
                    user_id=student.user_id,
                    notification_type="lessonNoteShared",
                    title="레슨 피드백이 도착했습니다",
                    body=f"{lesson.date} 레슨의 피드백을 확인하세요",
                    priority=NotificationPriority.normal,
                    action_url=f"/lessons/{lesson.id}",
                    action_label="피드백 확인",
                )

        return LessonResponse.model_validate(lesson)

    async def _get_accessible_lesson(self, lesson_id: str, current_user: Any) -> Any:
        """Load a lesson and enforce the current teacher's ownership boundary."""
        from app.models.lesson import Lesson

        lesson = await self.db.get(Lesson, lesson_id)
        if lesson is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if lesson.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Lesson access denied")
        return lesson

    async def _notify_lesson_counterparty(
        self,
        lesson: Any,
        current_user: Any,
        *,
        notification_type: str,
        title: str,
        body: str,
    ) -> None:
        """Send a high-priority lesson event notification to the counterparty only.

        The actor (``current_user``) is excluded: a teacher actor notifies the
        student, and a student/parent actor notifies the teacher (#1131 §2.2).
        Silently skips when the counterparty has no linked user account.
        """
        from app.models.student import Student
        from app.models.teacher import Teacher
        from app.services.notification_service import NotificationPriority, NotificationService

        role = getattr(getattr(current_user, "role", None), "value", None) or "teacher"

        recipient_user_id: str | None = None
        if role == "teacher":
            if lesson.student_id:
                student = await self.db.get(Student, lesson.student_id)
                recipient_user_id = student.user_id if student else None
        else:
            if lesson.teacher_id:
                teacher = await self.db.get(Teacher, lesson.teacher_id)
                recipient_user_id = teacher.user_id if teacher else None

        if not recipient_user_id:
            return

        await NotificationService(self.db).create_and_send(
            user_id=recipient_user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            priority=NotificationPriority.high,
            action_url=f"/lessons/{lesson.id}",
        )

    async def _resolve_late_cancel_compensation(self, lesson: Any) -> _LateCancelCompensation:
        """Resolve the compensation policy for a late student cancellation (#1167).

        Academy-owned subscriptions snapshot the policy on ``academy_subscriptions``;
        for all other subscriptions the teacher's persisted ``cancellation_defaults``
        row applies (#1178), falling back to the enabled defaults when the teacher
        never saved the settings.
        """
        from app.models.academy import Academy
        from app.models.academy_billing import AcademySubscription

        academy_sub = None
        if lesson.subscription_id:
            academy_sub = await self.db.scalar(
                select(AcademySubscription).where(AcademySubscription.subscription_id == lesson.subscription_id)
            )
        if academy_sub is None:
            # #1178 — non-academy: use the teacher's persisted defaults when a
            # row exists (cancellation_defaults.teacher_id == teachers.id);
            # teachers who never saved the settings keep the enabled defaults.
            from app.models.settings import CancellationDefaults

            defaults = await self.db.scalar(
                select(CancellationDefaults).where(CancellationDefaults.teacher_id == lesson.teacher_id)
            )
            if defaults is None:
                return _LateCancelCompensation(
                    enabled=True,
                    include_text=True,
                    message=_DEFAULT_COMPENSATION_MESSAGE,
                    notify_owner=False,
                    owner_user_id=None,
                )
            return _LateCancelCompensation(
                enabled=defaults.student_compensation_extra_minutes_enabled,
                include_text=defaults.include_extra_minutes_text_on_late_cancel,
                message=defaults.student_compensation_extra_minutes_message or _DEFAULT_COMPENSATION_MESSAGE,
                notify_owner=False,  # owner notification is an academy-only concern
                owner_user_id=None,
            )

        owner_user_id = None
        if academy_sub.notify_owner_on_late_cancel:
            owner_user_id = await self.db.scalar(
                select(Academy.owner_user_id).where(Academy.id == academy_sub.academy_id)
            )
        message = academy_sub.student_compensation_extra_minutes_message or _DEFAULT_COMPENSATION_MESSAGE
        return _LateCancelCompensation(
            enabled=bool(academy_sub.student_compensation_extra_minutes_enabled),
            include_text=bool(academy_sub.include_extra_minutes_text_on_late_cancel),
            message=message,
            notify_owner=bool(academy_sub.notify_owner_on_late_cancel),
            owner_user_id=owner_user_id,
        )

    async def _send_late_cancel_compensation(self, lesson: Any, compensation: _LateCancelCompensation) -> None:
        """Notify the student (and academy owner) about late-cancel compensation (#1167).

        Produces the ``compensationApplied`` student notification mandated by
        notification_system.md §4 when compensation is enabled, and an oversight
        notice to the academy owner when the academy subscription opted in.
        """
        from app.models.student import Student
        from app.services.notification_service import NotificationPriority, NotificationService

        svc = NotificationService(self.db)

        if compensation.enabled and lesson.student_id:
            student = await self.db.get(Student, lesson.student_id)
            student_user_id = student.user_id if student else None
            if student_user_id:
                await svc.create_and_send(
                    user_id=student_user_id,
                    notification_type="compensationApplied",
                    title="보너스 연습시간이 적립되었습니다",
                    body=compensation.message,
                    priority=NotificationPriority.normal,
                    action_url=f"/lessons/{lesson.id}",
                )

        if compensation.notify_owner and compensation.owner_user_id:
            await svc.create_and_send(
                user_id=compensation.owner_user_id,
                notification_type="lessonCancelled",
                title="학생 지각 취소 알림",
                body=f"{lesson.student_name} 학생이 {lesson.date} {lesson.start_time} 레슨을 지각 취소했습니다.",
                priority=NotificationPriority.high,
                action_url=f"/lessons/{lesson.id}",
            )

    async def get_upcoming(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return upcoming lessons."""
        from app.models.lesson import Lesson

        today = date.today()
        result = await self.db.scalars(
            select(Lesson)
            .where(Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id), Lesson.date >= today)
            .order_by(Lesson.date)
            .limit(limit)
        )
        return [LessonResponse.model_validate(lesson) for lesson in result.all()]

    async def get_recent(self, current_user: Any, *, limit: int = 10) -> list[LessonResponse]:
        """Return recently completed lessons."""
        from app.models.lesson import Lesson

        result = await self.db.scalars(
            select(Lesson)
            .where(
                Lesson.teacher_id == await resolve_teacher_id(self.db, current_user.id),
                Lesson.status == "completed",
            )
            .order_by(Lesson.date.desc())
            .limit(limit)
        )
        return [LessonResponse.model_validate(lesson) for lesson in result.all()]

    # ------------------------------------------------------------------
    # Lesson classes
    # ------------------------------------------------------------------

    async def get_all_classes(
        self, current_user: Any, *, page: int, size: int, offset: int
    ) -> PaginatedResponse[LessonClassResponse]:
        """List lesson classes for the teacher."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        query = select(LessonClass).where(
            LessonClass.teacher_id == tid,
            LessonClass.is_archived == False,  # noqa: E712
        )
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [LessonClassResponse.model_validate(c) for c in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_class(self, data: LessonClassCreate, current_user: Any) -> LessonClassResponse:
        """Create a lesson class."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        lesson_class = LessonClass(
            teacher_id=tid,
            name=data.name,
            type=data.type,
            payment_type=data.payment_type,
            contact_person=data.contact_person,
            contact_phone=data.contact_phone,
            address=data.address,
        )
        self.db.add(lesson_class)
        await self.db.flush()
        await self.db.refresh(lesson_class)
        return LessonClassResponse.model_validate(lesson_class)

    async def get_class_by_id(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Return a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        return LessonClassResponse.model_validate(lc)

    async def update_class(self, class_id: str, data: LessonClassUpdate, current_user: Any) -> LessonClassResponse:
        """Update a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(lc, key, value)
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def delete_class(self, class_id: str, current_user: Any) -> None:
        """Archive a lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        lc.is_archived = True
        await self.db.flush()

    async def restore_class(self, class_id: str, current_user: Any) -> LessonClassResponse:
        """Restore an archived lesson class."""
        lc = await self._get_accessible_class(class_id, current_user)
        lc.is_archived = False
        await self.db.flush()
        await self.db.refresh(lc)
        return LessonClassResponse.model_validate(lc)

    async def reorder_classes(self, ordered_ids: list[str], current_user: Any) -> None:
        """Set display order for lesson classes."""
        from app.models.lesson import LessonClass

        tid = await resolve_teacher_id(self.db, current_user.id)
        for idx, class_id in enumerate(ordered_ids):
            lc = await self.db.get(LessonClass, class_id)
            if lc and lc.teacher_id == tid:
                lc.sort_order = idx
        await self.db.flush()

    async def _get_accessible_class(self, class_id: str, current_user: Any) -> Any:
        """Load a lesson class and enforce read access for the current user."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        lesson_class = await self.db.get(LessonClass, class_id)
        if lesson_class is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson class not found")

        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            if lesson_class.teacher_id == teacher_id:
                return lesson_class
        elif role == "parent":
            parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
            if parent_id is not None:
                linked_child_class = await self.db.scalar(
                    select(ClassMembership.id)
                    .join(ParentChildRelation, ParentChildRelation.student_id == ClassMembership.student_id)
                    .where(
                        ClassMembership.lesson_class_id == class_id,
                        ParentChildRelation.parent_id == parent_id,
                        ParentChildRelation.status == ParentChildRelationStatus.active,
                    )
                )
                if linked_child_class is not None:
                    return lesson_class
        elif role == "student":
            linked_class = await self.db.scalar(
                select(ClassMembership.id).where(
                    ClassMembership.lesson_class_id == class_id,
                    ClassMembership.student_id == current_user.id,
                )
            )
            if linked_class is not None:
                return lesson_class

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Lesson class access denied")

    # ------------------------------------------------------------------
    # Memberships
    # ------------------------------------------------------------------

    @staticmethod
    def _duration_from_slot(slot: LessonSlotPayload) -> int:
        start = datetime.strptime(slot.start_time, "%H:%M")
        end = datetime.strptime(slot.end_time, "%H:%M")
        if end <= start:
            end += timedelta(days=1)
        return int((end - start).total_seconds() // 60)

    @staticmethod
    def _day_of_week(value: str | None) -> int | None:
        if value is None:
            return None
        if value.isdigit():
            return int(value)
        return {
            "mon": 0,
            "monday": 0,
            "tue": 1,
            "tuesday": 1,
            "wed": 2,
            "wednesday": 2,
            "thu": 3,
            "thursday": 3,
            "fri": 4,
            "friday": 4,
            "sat": 5,
            "saturday": 5,
            "sun": 6,
            "sunday": 6,
        }.get(value.lower())

    @staticmethod
    def _end_time(start_time: str, duration_minutes: int) -> str:
        start = datetime.strptime(start_time, "%H:%M")
        return (start + timedelta(minutes=duration_minutes)).strftime("%H:%M")

    @classmethod
    def _membership_response(cls, membership: Any) -> MembershipResponse:
        response = MembershipResponse.model_validate(membership)
        day_of_week = cls._day_of_week(membership.lesson_day)
        if day_of_week is not None and membership.lesson_time is not None:
            response.lesson_slots = [
                LessonSlotPayload(
                    day_of_week=day_of_week,
                    start_time=membership.lesson_time,
                    end_time=cls._end_time(membership.lesson_time, membership.lesson_duration),
                )
            ]
        return response

    async def get_memberships_by_class(self, class_id: str, current_user: Any) -> list[MembershipResponse]:
        """List all memberships in a class."""
        from app.models.lesson import ClassMembership

        await self._get_accessible_class(class_id, current_user)
        result = await self.db.scalars(select(ClassMembership).where(ClassMembership.lesson_class_id == class_id))
        return [self._membership_response(m) for m in result.all()]

    async def get_memberships(
        self,
        current_user: Any,
        *,
        student_id: str | None = None,
        class_id: str | None = None,
    ) -> list[MembershipResponse]:
        """List memberships with flat student/class filters."""
        from app.models.lesson import ClassMembership, LessonClass

        role = getattr(getattr(current_user, "role", None), "value", None)
        query = select(ClassMembership)

        if student_id:
            query = query.where(ClassMembership.student_id == student_id)
        if class_id:
            query = query.where(ClassMembership.lesson_class_id == class_id)

        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            query = query.join(LessonClass, LessonClass.id == ClassMembership.lesson_class_id).where(
                LessonClass.teacher_id == teacher_id
            )
        elif role == "student":
            query = query.where(ClassMembership.student_id == current_user.id)
        elif role == "parent":
            from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

            parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
            if parent_id is None:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
            linked_child_ids = select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
            if student_id:
                linked = await self.db.scalar(
                    select(ParentChildRelation.id).where(
                        ParentChildRelation.parent_id == parent_id,
                        ParentChildRelation.student_id == student_id,
                        ParentChildRelation.status == ParentChildRelationStatus.active,
                    )
                )
                if linked is None:
                    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
            query = query.where(ClassMembership.student_id.in_(linked_child_ids))
        else:
            query = query.where(ClassMembership.student_id == current_user.id)

        result = await self.db.scalars(query)
        return [self._membership_response(membership) for membership in result.all()]

    async def get_membership_by_id(self, membership_id: str, current_user: Any) -> MembershipResponse:
        """Return a single membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user)
        return self._membership_response(m)

    async def add_membership(self, class_id: str, data: MembershipCreate, current_user: Any) -> MembershipResponse:
        """Add a student to a class."""
        from app.models.lesson import ClassMembership

        await self._get_accessible_class(class_id, current_user)
        lesson_day = data.lesson_day
        lesson_time = data.lesson_time
        lesson_duration = data.lesson_duration
        if data.lesson_slots:
            primary_slot = data.lesson_slots[0]
            lesson_day = str(primary_slot.day_of_week)
            lesson_time = primary_slot.start_time
            if "lesson_duration" not in data.model_fields_set:
                lesson_duration = self._duration_from_slot(primary_slot)

        membership = ClassMembership(
            lesson_class_id=class_id,
            student_id=data.student_id,
            instrument=data.instrument or "",
            monthly_fee=data.monthly_fee or 0,
            lessons_per_week=data.lessons_per_week or 1,
            lesson_day=lesson_day,
            lesson_time=lesson_time,
            lesson_duration=lesson_duration,
            lesson_location_id=data.lesson_location_id,
            travel_time_minutes=data.travel_time_minutes,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return self._membership_response(membership)

    async def update_membership(
        self, class_id: str, membership_id: str, data: MembershipUpdate, current_user: Any
    ) -> MembershipResponse:
        """Update a class membership."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user)

        update_data = data.model_dump(exclude_unset=True, exclude={"lesson_slots"})
        if data.lesson_slots:
            primary_slot = data.lesson_slots[0]
            update_data["lesson_day"] = str(primary_slot.day_of_week)
            update_data["lesson_time"] = primary_slot.start_time
            if "lesson_duration" not in data.model_fields_set:
                update_data["lesson_duration"] = self._duration_from_slot(primary_slot)
        for key, value in update_data.items():
            setattr(m, key, value)
        await self.db.flush()
        await self.db.refresh(m)
        return self._membership_response(m)

    async def remove_membership(self, class_id: str, membership_id: str, current_user: Any) -> None:
        """Remove a membership from a class."""
        await self.remove_membership_by_id(membership_id, current_user)

    async def update_membership_status(
        self,
        membership_id: str,
        new_status: str,
        current_user: Any,
    ) -> MembershipResponse:
        """Update only membership status."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user, require_teacher=True)
        try:
            m.status = ClassMembership.MembershipStatus(new_status)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=f"Invalid membership status: {new_status}",
            )
        await self.db.flush()
        await self.db.refresh(m)
        return self._membership_response(m)

    async def remove_membership_by_id(self, membership_id: str, current_user: Any) -> None:
        """Remove a membership without requiring class_id context."""
        from app.models.lesson import ClassMembership

        m = await self.db.get(ClassMembership, membership_id)
        if m is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membership not found")
        await self._assert_membership_access(m, current_user, require_teacher=True)
        await self.db.delete(m)
        await self.db.flush()

    async def _assert_membership_access(
        self,
        membership: Any,
        current_user: Any,
        *,
        require_teacher: bool = False,
    ) -> None:
        from app.models.lesson import LessonClass

        role = getattr(getattr(current_user, "role", None), "value", None)
        if role == "teacher":
            teacher_id = await resolve_teacher_id(self.db, current_user.id)
            class_teacher_id = await self.db.scalar(
                select(LessonClass.teacher_id).where(LessonClass.id == membership.lesson_class_id)
            )
            if class_teacher_id == teacher_id:
                return
        elif not require_teacher and role == "student" and membership.student_id == current_user.id:
            return

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to access membership")
