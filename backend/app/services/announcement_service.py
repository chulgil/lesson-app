"""Teacher announcement service."""

from __future__ import annotations

from datetime import date
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import NotificationPriority
from app.models.subscription import SubscriptionStatus, SubscriptionType
from app.schemas.teacher_announcement import (
    AffectedLesson,
    TeacherAnnouncementCreate,
    TeacherAnnouncementDayOffsResponse,
    TeacherAnnouncementResponse,
    TeacherAnnouncementUpdate,
)
from app.services.notification_service import NotificationService
from app.services.teacher_id_resolver import resolve_teacher_id

ACTIVE_SUBSCRIPTION_STATUSES = {SubscriptionStatus.active, SubscriptionStatus.expiringSoon}


class AnnouncementService:
    """Handle teacher announcement creation and querying."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_announcement(
        self,
        body: TeacherAnnouncementCreate,
        current_user: Any,
    ) -> TeacherAnnouncementResponse:
        """Create announcement and notify active students."""
        from app.models.teacher_announcement import (
            TeacherAnnouncement,
            TeacherAnnouncementDate,
            TeacherAnnouncementType,
        )

        teacher_id = await self._authorize_teacher(body.teacher_id, current_user)
        normalized_dates = self._normalize_dates(body.dates)

        announcement = TeacherAnnouncement(
            teacher_id=teacher_id,
            type=(TeacherAnnouncementType.day_off if body.type == "dayOff" else TeacherAnnouncementType.general),
            message=body.message,
        )
        self.db.add(announcement)
        await self.db.flush()

        if body.type == "dayOff":
            for announcement_date in normalized_dates:
                self.db.add(
                    TeacherAnnouncementDate(
                        teacher_announcement_id=announcement.id,
                        announcement_date=announcement_date,
                    )
                )

        active_students = await self._active_students_with_active_subscription(teacher_id)

        affected_lessons = []
        if body.type == "dayOff":
            affected_lessons = await self._collect_affected_lessons(
                teacher_id=teacher_id,
                dates=normalized_dates,
                target_students=set(active_students),
            )

        notified_count = await self._notify_active_students(
            announcement_type=body.type,
            message=body.message,
            teacher_id=teacher_id,
            students=active_students,
            announcement_id=announcement.id,
        )
        announcement.notified_count = notified_count

        await self.db.flush()
        await self.db.refresh(announcement)

        return TeacherAnnouncementResponse(
            id=announcement.id,
            teacher_id=announcement.teacher_id,
            type=body.type,
            dates=normalized_dates,
            message=announcement.message,
            created_at=announcement.created_at,
            notified_count=announcement.notified_count,
            affected_lessons=affected_lessons,
        )

    async def list_announcements(
        self,
        *,
        teacher_id: str | None,
        current_user: Any,
    ) -> list[TeacherAnnouncementResponse]:
        """List announcements for a teacher, newest first."""
        from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementType

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        rows = await self.db.scalars(
            select(TeacherAnnouncement)
            .where(TeacherAnnouncement.teacher_id == resolved_teacher_id)
            .order_by(TeacherAnnouncement.created_at.desc())
        )

        results: list[TeacherAnnouncementResponse] = []
        for announcement in rows.all():
            dates: list[date] = []
            affected_lessons: list[AffectedLesson] = []
            if announcement.type == TeacherAnnouncementType.day_off:
                dates = await self._announcement_dates(announcement.id)
                affected_lessons = await self._collect_affected_lessons(
                    teacher_id=resolved_teacher_id,
                    dates=dates,
                    target_students=None,
                )

            results.append(
                TeacherAnnouncementResponse(
                    id=announcement.id,
                    teacher_id=announcement.teacher_id,
                    type="dayOff" if announcement.type == TeacherAnnouncementType.day_off else "general",
                    dates=dates,
                    message=announcement.message,
                    created_at=announcement.created_at,
                    notified_count=announcement.notified_count,
                    affected_lessons=affected_lessons,
                )
            )
        return results

    async def list_day_offs(
        self,
        *,
        teacher_id: str | None,
        from_date: date,
        to_date: date,
        current_user: Any,
    ) -> TeacherAnnouncementDayOffsResponse:
        """Return day-off dates in range for a teacher."""
        from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementDate

        if from_date > to_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="from_date cannot be after to_date",
            )

        resolved_teacher_id = await self._authorize_teacher(teacher_id, current_user)
        rows = await self.db.scalars(
            select(TeacherAnnouncementDate.announcement_date)
            .join(
                TeacherAnnouncement,
                TeacherAnnouncement.id == TeacherAnnouncementDate.teacher_announcement_id,
            )
            .where(
                TeacherAnnouncement.teacher_id == resolved_teacher_id,
                TeacherAnnouncementDate.announcement_date >= from_date,
                TeacherAnnouncementDate.announcement_date <= to_date,
            )
            .order_by(TeacherAnnouncementDate.announcement_date.asc())
            .distinct()
        )
        return TeacherAnnouncementDayOffsResponse(dates=list(rows))

    async def update_announcement(
        self,
        announcement_id: str,
        body: TeacherAnnouncementUpdate,
        current_user: Any,
    ) -> TeacherAnnouncementResponse:
        """Update message (and dayOff dates); type is immutable, students are not re-notified."""
        from app.models.teacher_announcement import TeacherAnnouncementDate, TeacherAnnouncementType

        announcement = await self._load_owned_announcement(announcement_id, current_user)
        is_day_off = announcement.type == TeacherAnnouncementType.day_off
        normalized_dates = self._normalize_dates(body.dates)

        # dates 검증은 기존 announcement 의 type 기준 (type 은 불변).
        if is_day_off and not normalized_dates:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="dates required for dayOff type",
            )
        if not is_day_off and normalized_dates:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="dates must be empty for general type",
            )

        announcement.message = body.message

        if is_day_off:
            # 기존 날짜 행 전체 교체 (ORM cascade 미정의 → 수동 삭제 후 재삽입).
            existing = await self.db.scalars(
                select(TeacherAnnouncementDate).where(
                    TeacherAnnouncementDate.teacher_announcement_id == announcement.id
                )
            )
            for row in existing.all():
                await self.db.delete(row)
            await self.db.flush()
            for announcement_date in normalized_dates:
                self.db.add(
                    TeacherAnnouncementDate(
                        teacher_announcement_id=announcement.id,
                        announcement_date=announcement_date,
                    )
                )

        await self.db.flush()
        await self.db.refresh(announcement)

        dates: list[date] = []
        affected_lessons: list[AffectedLesson] = []
        if is_day_off:
            dates = await self._announcement_dates(announcement.id)
            affected_lessons = await self._collect_affected_lessons(
                teacher_id=announcement.teacher_id,
                dates=dates,
                target_students=None,
            )

        return TeacherAnnouncementResponse(
            id=announcement.id,
            teacher_id=announcement.teacher_id,
            type="dayOff" if is_day_off else "general",
            dates=dates,
            message=announcement.message,
            created_at=announcement.created_at,
            notified_count=announcement.notified_count,
            affected_lessons=affected_lessons,
        )

    async def delete_announcement(self, announcement_id: str, current_user: Any) -> None:
        """Delete an announcement and its day-off date rows (owner only).

        Notification 모델은 announcement 를 참조하는 FK/컬럼이 없다 (JSON data.announcementId
        메타데이터일 뿐). 참조 무결성 제약이 없으므로 dangling 도 없어, notification 은 삭제하지
        않고 이력으로 보존한다.
        """
        from app.models.teacher_announcement import TeacherAnnouncementDate

        announcement = await self._load_owned_announcement(announcement_id, current_user)

        # 날짜 행을 먼저 지워 FK 위반을 피한다 (ORM cascade 미정의).
        existing = await self.db.scalars(
            select(TeacherAnnouncementDate).where(TeacherAnnouncementDate.teacher_announcement_id == announcement.id)
        )
        for row in existing.all():
            await self.db.delete(row)

        await self.db.delete(announcement)
        await self.db.flush()

    async def _load_owned_announcement(self, announcement_id: str, current_user: Any) -> Any:
        """Load an announcement by id and assert the caller owns it (404/403)."""
        from app.models.teacher_announcement import TeacherAnnouncement

        announcement = await self.db.get(TeacherAnnouncement, announcement_id)
        if announcement is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Announcement not found",
            )
        resolved_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if announcement.teacher_id != resolved_teacher_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Teacher access denied",
            )
        return announcement

    async def _notify_active_students(
        self,
        *,
        announcement_type: str,
        message: str,
        teacher_id: str,
        students: dict[str, str | None],
        announcement_id: str,
    ) -> int:
        """Notify students with active subscription and return notified count."""
        service = NotificationService(self.db)

        title = "휴강 안내" if announcement_type == "dayOff" else "선생님 공지"
        priority = NotificationPriority.high if announcement_type == "dayOff" else NotificationPriority.normal

        notified = 0
        for student_id, user_id in students.items():
            if user_id is None:
                continue

            await service.create_and_send(
                user_id=user_id,
                notification_type="generalAnnouncement",
                title=title,
                body=message,
                priority=priority,
                data={
                    "teacherId": teacher_id,
                    "announcementId": announcement_id,
                    "type": announcement_type,
                    "source": "teacher_announcement",
                    "studentId": student_id,
                },
            )
            notified += 1
        return notified

    async def _active_students_with_active_subscription(
        self,
        teacher_id: str,
    ) -> dict[str, str | None]:
        """Return mapping student_id → user_id for active subscriptions."""
        from app.models.lesson import ClassMembership, LessonClass
        from app.models.student import Student
        from app.models.subscription import Subscription

        rows = await self.db.execute(
            select(Subscription.student_id, Student.user_id)
            .join(ClassMembership, Subscription.membership_id == ClassMembership.id)
            .join(LessonClass, ClassMembership.lesson_class_id == LessonClass.id)
            .join(Student, Student.id == Subscription.student_id)
            .where(
                LessonClass.teacher_id == teacher_id,
                Student.is_active.is_(True),
                or_(
                    Subscription.status.in_(ACTIVE_SUBSCRIPTION_STATUSES),
                    and_(
                        Subscription.type == SubscriptionType.trial,
                        Subscription.status.in_(ACTIVE_SUBSCRIPTION_STATUSES),
                    ),
                ),
            )
            .order_by(Subscription.created_at.desc(), Subscription.id.desc())
        )

        students: dict[str, str | None] = {}
        for student_id, user_id in rows.all():
            students.setdefault(student_id, user_id)
        return students

    async def _collect_affected_lessons(
        self,
        *,
        teacher_id: str,
        dates: list[date],
        target_students: set[str] | None,
    ) -> list[AffectedLesson]:
        """Collect lessons impacted by 휴강 date set."""
        from app.models.lesson import Lesson, LessonStatus

        if not dates:
            return []

        lessons_query = (
            select(Lesson)
            .where(
                Lesson.teacher_id == teacher_id,
                Lesson.date.in_(dates),
                Lesson.status.in_([LessonStatus.scheduled, LessonStatus.reschedulePending]),
            )
            .order_by(Lesson.date.asc(), Lesson.start_time.asc(), Lesson.id.asc())
        )
        if target_students is not None:
            lessons_query = lessons_query.where(Lesson.student_id.in_(target_students))

        lessons = (await self.db.scalars(lessons_query)).all()
        if not lessons:
            return []

        lessons_with_subscription = [lesson for lesson in lessons if lesson.subscription_id is not None]
        session_map = await self._session_number_by_lesson_id(lessons_with_subscription)

        return [
            AffectedLesson(
                student_id=lesson.student_id,
                student_name=lesson.student_name,
                instrument=lesson.instrument,
                start_time=lesson.start_time,
                session_number=session_map.get(lesson.id),
                subscription_id=lesson.subscription_id,
            )
            for lesson in sorted(lessons, key=lambda row: (row.date, row.start_time, row.id))
        ]

    async def _session_number_by_lesson_id(
        self,
        lessons_with_subscription: list[Any],
    ) -> dict[str, int]:
        """Map lesson_id → session number within the subscription."""
        from app.models.lesson import Lesson

        if not lessons_with_subscription:
            return {}

        subscription_ids = sorted(
            {lesson.subscription_id for lesson in lessons_with_subscription if lesson.subscription_id is not None}
        )
        if not subscription_ids:
            return {}

        all_lessons = await self.db.scalars(
            select(Lesson)
            .where(Lesson.subscription_id.in_(subscription_ids))
            .order_by(Lesson.date.asc(), Lesson.start_time.asc(), Lesson.id.asc())
        )

        counters: dict[str, int] = {}
        lesson_to_session: dict[str, int] = {}
        for lesson in all_lessons:
            if lesson.subscription_id is None:
                continue
            if lesson.session_number is not None:
                lesson_to_session[lesson.id] = lesson.session_number
                counters[lesson.subscription_id] = max(
                    counters.get(lesson.subscription_id, 0),
                    lesson.session_number,
                )
                continue
            position = counters.get(lesson.subscription_id, 0) + 1
            counters[lesson.subscription_id] = position
            lesson_to_session[lesson.id] = position

        return lesson_to_session

    async def _announcement_dates(self, announcement_id: str) -> list[date]:
        """Collect dates for a day-off announcement."""
        from app.models.teacher_announcement import TeacherAnnouncementDate

        rows = await self.db.scalars(
            select(TeacherAnnouncementDate.announcement_date)
            .where(TeacherAnnouncementDate.teacher_announcement_id == announcement_id)
            .order_by(TeacherAnnouncementDate.announcement_date.asc())
        )
        return list(rows)

    async def _authorize_teacher(self, teacher_id: str | None, current_user: Any) -> str:
        resolved_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if teacher_id is None:
            return resolved_teacher_id
        if teacher_id not in {current_user.id, resolved_teacher_id}:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access denied")
        return resolved_teacher_id

    def _normalize_dates(self, dates: list[date]) -> list[date]:
        """Normalize/sort/unique dates."""
        return sorted(set(dates))

    async def list_visible_announcements(
        self,
        *,
        current_user: Any,
    ) -> list[TeacherAnnouncementResponse]:
        """학생/학부모 시점 — 본인이 연결된 활성 선생님(들)의 announcement 본문 조회.

        spec student_home_master.md / notification_master.md — 학생이 휴강 공지 본문을 직접
        조회할 수 있도록 한다. notifications 메타데이터로만 보고 본문 알 수 없던 P0 보완.

        권한:
        - student / parent: 본인이 student 면 자기 학생의 활성 선생님 announcement 만.
        - parent 면 자녀들의 활성 선생님 announcement 합집합.
        """
        from app.models.relationship import RelationStatus, TeacherStudentRelation
        from app.models.student import Student
        from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementType

        # 1) caller 의 student 식별 (parent 면 자녀들).
        student_ids: list[str] = []
        my_student = await self.db.scalar(select(Student).where(Student.user_id == current_user.id))
        if my_student is not None:
            student_ids.append(my_student.id)
        else:
            # parent 케이스 — children 조회.
            # FIX (Phase 23): ParentChildRelation.parent_id 는 Parent.id 인데 current_user.id 는
            # User.id. 이전 (Phase 22) 코드는 두 ID 를 직접 비교해 매칭 0건 → 학부모는 자녀 선생님
            # announcement 본문 영구 0건. Parent 를 user_id 로 먼저 resolve.
            from app.models.parent import Parent, ParentChildRelation

            parent_profile_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == current_user.id))
            if parent_profile_id is not None:
                parent_rel = await self.db.scalars(
                    select(ParentChildRelation.student_id).where(ParentChildRelation.parent_id == parent_profile_id)
                )
                student_ids.extend(s for s in parent_rel.all() if s)

        if not student_ids:
            return []

        # 2) 활성 선생님 ID 들 — invitePending/disconnected/expired/inactive 제외.
        active_relations = await self.db.scalars(
            select(TeacherStudentRelation.teacher_id)
            .where(TeacherStudentRelation.student_id.in_(student_ids))
            .where(
                TeacherStudentRelation.status.in_(
                    [RelationStatus.active, RelationStatus.trialBooked, RelationStatus.pending]
                )
            )
        )
        teacher_ids = list({tid for tid in active_relations.all() if tid})
        if not teacher_ids:
            return []

        # 3) 그 선생님들의 announcement 들 newest first.
        rows = await self.db.scalars(
            select(TeacherAnnouncement)
            .where(TeacherAnnouncement.teacher_id.in_(teacher_ids))
            .order_by(TeacherAnnouncement.created_at.desc())
        )

        results: list[TeacherAnnouncementResponse] = []
        for announcement in rows.all():
            dates: list[date] = []
            affected_lessons: list[AffectedLesson] = []
            if announcement.type == TeacherAnnouncementType.day_off:
                dates = await self._announcement_dates(announcement.id)
            results.append(
                TeacherAnnouncementResponse(
                    id=announcement.id,
                    teacher_id=announcement.teacher_id,
                    type="dayOff" if announcement.type == TeacherAnnouncementType.day_off else "general",
                    dates=dates,
                    message=announcement.message,
                    created_at=announcement.created_at,
                    notified_count=announcement.notified_count,
                    affected_lessons=affected_lessons,
                )
            )
        return results
