"""P2-2 그룹 수업 알림 emit — 5전이의 수신자 해소와 문구를 한곳에 모은다.

FE 로컬 알림은 액터 기기에서만 뜬다(#1191). 예약된 학생·학부모는 서버가 row 를
남기지 않으면 목록을 새로고침하기 전까지 아무것도 모른다. 그래서 다음 5전이는
BE 가 ``Notification`` 을 쓴다.

  1. 드롭인 예약 확정 → 예약 학생
  2. 전일 리마인더 → 예약 학생 (배치)
  3. 당일 리마인더 → 예약 학생 (배치)
  4. 드롭인 회차 오픈 → 담당 교사의 학생 브로드캐스트
  5. 노쇼 처리 → 학생 + 연결된 학부모

대기승급·자동취소 통지는 #1207 이 이미 담당한다 — 여기서 다시 내지 않는다.

수신자 해소는 ``notification_recipient`` (FK-safe) 를 쓴다. ``student_id`` 는
Student.id 일 수도 User.id 일 수도 있고, 해소 결과가 실 User 가 아니면 emit 을
건너뛴다 — 알림 실패가 예약·출석 같은 핵심 흐름을 깨뜨리지 않게 한다.

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P2-2.
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# 저장된 회차 시각은 KST 벽시계다 (schedule_ext_service 와 같은 규약).
from app.core.timezones import KST as _KST
from app.models.notification import NotificationPriority
from app.services.notification_recipient import resolve_student_user_id

logger = logging.getLogger(__name__)

TYPE_BOOKING_CONFIRMED = "groupBookingConfirmed"
TYPE_REMINDER_DAY_BEFORE = "groupLessonReminderDayBefore"
TYPE_REMINDER_DAY_OF = "groupLessonReminderDayOf"
TYPE_DROPIN_OPENED = "groupDropInOpened"
TYPE_NO_SHOW_WARNING = "groupNoShowWarning"

# notification_service 의 역할 필터 등록용 — 5종 모두 학생/학부모 인박스 대상.
GROUP_NOTIFICATION_TYPES = frozenset(
    {
        TYPE_BOOKING_CONFIRMED,
        TYPE_REMINDER_DAY_BEFORE,
        TYPE_REMINDER_DAY_OF,
        TYPE_DROPIN_OPENED,
        TYPE_NO_SHOW_WARNING,
    }
)

_ACTION_URL = "/schedule"


def as_kst(value: datetime) -> datetime:
    """저장된 회차 시각을 KST 로 정규화. naive 는 KST 벽시계로 간주한다.

    SQLite 는 timezone 을 되돌려주지 않아 naive 로 로드된다 — 쓸 때 KST aware 로
    넣었으므로 naive 값의 벽시계가 곧 KST 다.
    """
    if value.tzinfo is None:
        return value.replace(tzinfo=_KST)
    return value.astimezone(_KST)


def _when(schedule: Any) -> str:
    """알림 본문에 넣을 '8월 1일(금) 18:00' 형태의 KST 표기."""
    start = as_kst(schedule.start_time)
    weekday = "월화수목금토일"[start.weekday()]
    return f"{start.month}월 {start.day}일({weekday}) {start:%H:%M}"


class GroupNotificationService:
    """Emit group-class notifications for the five P2-2 transitions."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # 수신자 해소
    # ------------------------------------------------------------------

    async def _student_profile_id(self, student_id: str) -> str | None:
        """Student.id-or-User.id → Student.id. 프로필이 없으면 None."""
        from app.models.student import Student

        row = await self.db.scalar(select(Student.id).where(Student.id == student_id))
        if row is not None:
            return row
        return await self.db.scalar(select(Student.id).where(Student.user_id == student_id))

    async def _guardian_user_ids(self, student_id: str) -> list[str]:
        """학생과 활성 연결된 학부모의 User.id 목록. 없으면 빈 리스트."""
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
        from app.models.user import User

        profile_id = await self._student_profile_id(student_id)
        if profile_id is None:
            return []
        rows = await self.db.scalars(
            select(Parent.user_id)
            .join(ParentChildRelation, ParentChildRelation.parent_id == Parent.id)
            .where(
                ParentChildRelation.student_id == profile_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        candidates = [uid for uid in rows.all() if uid]
        if not candidates:
            return []
        # FK-safe — 실재하는 User 만 남긴다.
        existing = await self.db.scalars(select(User.id).where(User.id.in_(candidates)))
        return list(existing.all())

    async def _emit(
        self,
        *,
        user_id: str,
        notification_type: str,
        title: str,
        body: str,
        priority: NotificationPriority,
        data: dict[str, Any] | None = None,
    ) -> None:
        from app.services.notification_service import NotificationService

        await NotificationService(self.db).create_and_send(
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            body=body,
            priority=priority,
            data=data,
            action_url=_ACTION_URL,
        )

    # ------------------------------------------------------------------
    # 1. 예약 확정
    # ------------------------------------------------------------------

    async def notify_booking_confirmed(self, *, booking: Any, schedule: Any, group_class: Any) -> None:
        """확정된 그룹 예약을 학생에게 알린다. 대기 등록은 호출부에서 걸러낸다."""
        recipient = await resolve_student_user_id(self.db, booking.student_id)
        if not recipient:
            return
        await self._emit(
            user_id=recipient,
            notification_type=TYPE_BOOKING_CONFIRMED,
            title="예약이 확정되었어요",
            body=f"{group_class.name} {_when(schedule)} 수업 예약이 확정되었어요.",
            priority=NotificationPriority.high,
            data={"groupClassId": group_class.id, "scheduleId": schedule.id, "bookingId": booking.id},
        )

    # ------------------------------------------------------------------
    # 2·3. 리마인더 (배치에서 호출)
    # ------------------------------------------------------------------

    async def notify_lesson_reminder(
        self,
        *,
        booking: Any,
        schedule: Any,
        group_class: Any,
        notification_type: str,
    ) -> bool:
        """전일/당일 리마인더 1건. 수신자를 못 찾으면 False (배치가 집계에서 뺀다)."""
        recipient = await resolve_student_user_id(self.db, booking.student_id)
        if not recipient:
            return False
        is_day_of = notification_type == TYPE_REMINDER_DAY_OF
        await self._emit(
            user_id=recipient,
            notification_type=notification_type,
            title="오늘 그룹 수업이 있어요" if is_day_of else "내일 그룹 수업이 있어요",
            body=f"{group_class.name} {_when(schedule)} 수업이 예정되어 있어요.",
            priority=NotificationPriority.normal,
            data={"groupClassId": group_class.id, "scheduleId": schedule.id, "bookingId": booking.id},
        )
        return True

    # ------------------------------------------------------------------
    # 4. 드롭인 오픈
    # ------------------------------------------------------------------

    async def notify_dropin_opened(self, *, schedule: Any, group_class: Any) -> int:
        """드롭인 회차 오픈을 담당 교사의 학생 전원에게 알린다. 발송 건수 반환."""
        from app.models.student import Student
        from app.models.user import User

        rows = await self.db.scalars(
            select(Student.user_id).where(
                Student.teacher_id == group_class.teacher_id,
                Student.user_id.is_not(None),
            )
        )
        candidates = [uid for uid in rows.all() if uid]
        if not candidates:
            return 0
        recipients = list((await self.db.scalars(select(User.id).where(User.id.in_(candidates)))).all())

        for user_id in recipients:
            await self._emit(
                user_id=user_id,
                notification_type=TYPE_DROPIN_OPENED,
                title="새 드롭인 수업이 열렸어요",
                body=f"{group_class.name} {_when(schedule)} 회차가 열렸어요. 정원 {schedule.max_capacity}명.",
                priority=NotificationPriority.normal,
                data={"groupClassId": group_class.id, "scheduleId": schedule.id},
            )
        return len(recipients)

    # ------------------------------------------------------------------
    # 5. 노쇼 경고
    # ------------------------------------------------------------------

    async def notify_no_show_warning(
        self, *, booking: Any, schedule: Any, group_class: Any, outcome: str | None = None
    ) -> int:
        """노쇼 처리를 학생 + 연결된 학부모에게 알린다. 발송 건수 반환.

        ``outcome`` 은 J5b 정책 집행 결과 문구 — 조용한 차감 금지 원칙(3중 고지,
        옵시디언 54)에 따라 차감/보강권 결과를 body 에 함께 싣는다.
        """
        recipients: list[str] = []
        student_user_id = await resolve_student_user_id(self.db, booking.student_id)
        if student_user_id:
            recipients.append(student_user_id)
        recipients.extend(uid for uid in await self._guardian_user_ids(booking.student_id) if uid not in recipients)

        body = f"{group_class.name} {_when(schedule)} 수업이 결석(노쇼)으로 처리되었어요."
        if outcome:
            body = f"{body} {outcome}"
        for user_id in recipients:
            await self._emit(
                user_id=user_id,
                notification_type=TYPE_NO_SHOW_WARNING,
                title="결석으로 처리되었어요",
                body=body,
                priority=NotificationPriority.urgent,
                data={"groupClassId": group_class.id, "scheduleId": schedule.id, "bookingId": booking.id},
            )
        return len(recipients)
