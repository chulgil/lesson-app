"""#1207 — 협상·전환 상대 통지 BE 알림 emit ('상대가 알게 되는가' 축 완성).

FE 로컬 알림(actor 기기 전용)은 PR #1206 에서 제거했고, 상대 통지는 BE
Notification row 로 단일화한다. 이 테스트는 미발행이던 5개 전이가 상대
userId 로 Notification row 를 만드는지 검증한다.

기존 FE 타입 재사용 우선:
  - 교사 승인/거절 → scheduleChangeApproved / scheduleChangeRejected
  - 확정레슨 변경수락 → scheduleChangeApproved (제안자에게)
  - 예약 취소 → lessonCancelled (상대에게)
  - 그룹 대기승격 → lessonBooked / 대기 자동취소 → lessonCancelled
신규 타입은 신청 생성만: lessonRequestReceived (교사 인박스).

채팅 메시지 통지는 스팸 위험으로 이번 범위에서 제외(리스트/뱃지 갱신에 위임).
"""

from __future__ import annotations

import datetime as dt

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification

TEACHER_ID = "test-user-id"
TEACHER_PROF_ID = "test-user-id-prof"
STUDENT_ID = "test-student-id"

_SLOT = {"day_of_week": 2, "start_time": "15:00", "end_time": "16:00"}


async def _make_request(db: AsyncSession, *, status: str = "pending", teacher_id: str = TEACHER_PROF_ID) -> str:
    from app.models.schedule import LessonRequest

    lr = LessonRequest(
        student_id=STUDENT_ID,
        teacher_id=teacher_id,
        request_type="regular",
        instrument="violin",
        preferred_day=2,
        preferred_time="15:00",
        preferred_duration=60,
        preferred_slots=[],
        status=status,
        expires_at=dt.datetime.now(dt.UTC) + dt.timedelta(days=7),
        current_round=0,
        is_returning_student=False,
    )
    db.add(lr)
    await db.flush()
    return lr.id


async def _notifs(db: AsyncSession, user_id: str, notif_type: str) -> list[Notification]:
    return (
        await db.scalars(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.type == notif_type,
            )
        )
    ).all()


# ---------------------------------------------------------------------------
# HIGH — 교사 초기 승인/거절 (해피패스 확정이 상대에 안 닿음)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_teacher_approve_notifies_student(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import LessonRequestStatusUpdate
    from app.services.lesson_request_service import LessonRequestService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", email="c1@test.com")
    rid = await _make_request(db_session)

    await LessonRequestService(db_session).update_status(rid, LessonRequestStatusUpdate(status="approved"), teacher)

    notifs = await _notifs(db_session, STUDENT_ID, "scheduleChangeApproved")
    assert len(notifs) == 1, "teacher approve must create one in-app row for the student"
    assert notifs[0].action_url == f"/schedule/request/{rid}"


@pytest.mark.asyncio
async def test_teacher_reject_notifies_student(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import LessonRequestStatusUpdate
    from app.services.lesson_request_service import LessonRequestService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", email="c2@test.com")
    rid = await _make_request(db_session)

    await LessonRequestService(db_session).update_status(
        rid,
        LessonRequestStatusUpdate(status="rejected", decline_reason="시간이 맞지 않아요"),
        teacher,
    )

    notifs = await _notifs(db_session, STUDENT_ID, "scheduleChangeRejected")
    assert len(notifs) == 1, "teacher reject must create one in-app row for the student"


@pytest.mark.asyncio
async def test_student_cancel_does_not_notify_via_approve_type(db_session: AsyncSession, create_test_user):
    """학생의 취소(cancel)는 승인/거절 통지 경로를 타지 않는다 (전이 범위 한정)."""
    from app.schemas.lesson_request import LessonRequestStatusUpdate
    from app.services.lesson_request_service import LessonRequestService

    await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="c2b@test.com")
    rid = await _make_request(db_session)

    await LessonRequestService(db_session).update_status(rid, LessonRequestStatusUpdate(status="cancelled"), student)

    assert await _notifs(db_session, TEACHER_ID, "scheduleChangeApproved") == []
    assert await _notifs(db_session, TEACHER_ID, "scheduleChangeRejected") == []


# ---------------------------------------------------------------------------
# HIGH — scheduleChangeAccepted: Lesson 이동은 되나 제안자 미통지
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_schedule_change_accepted_notifies_proposer(db_session: AsyncSession, create_test_user):
    from app.schemas.request_event import RequestEventCreate
    from app.services.lesson_request_service import LessonRequestService

    await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="c3@test.com")
    rid = await _make_request(db_session, status="negotiating")

    await LessonRequestService(db_session).add_event(
        rid,
        RequestEventCreate(
            request_id=rid,
            actor_type="student",
            actor_id=STUDENT_ID,
            event_type="scheduleChangeAccepted",
        ),
        student,
    )

    notifs = await _notifs(db_session, TEACHER_ID, "scheduleChangeApproved")
    assert len(notifs) == 1, "accepting a schedule change must notify the proposer (teacher)"


# ---------------------------------------------------------------------------
# MED — 예약/슬롯 취소 미통지
# ---------------------------------------------------------------------------


async def _make_booking(db: AsyncSession) -> str:
    from app.models.schedule import BookingStatus, LessonBooking

    booking = LessonBooking(
        teacher_id=TEACHER_PROF_ID,
        student_id=STUDENT_ID,
        lesson_type="regular",
        scheduled_date=dt.date(2026, 4, 1),
        scheduled_time="15:00",
        duration=60,
        status=BookingStatus.confirmed,
    )
    db.add(booking)
    await db.flush()
    return booking.id


@pytest.mark.asyncio
async def test_cancel_booking_by_teacher_notifies_student(db_session: AsyncSession, create_test_user):
    from app.services.schedule_service import ScheduleService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", email="c4@test.com")
    booking_id = await _make_booking(db_session)

    await ScheduleService(db_session).cancel_booking(booking_id, "개인 사정", teacher)

    notifs = await _notifs(db_session, STUDENT_ID, "lessonCancelled")
    assert len(notifs) == 1, "teacher cancelling a booking must notify the student"


@pytest.mark.asyncio
async def test_cancel_booking_by_student_notifies_teacher(db_session: AsyncSession, create_test_user):
    from app.services.schedule_service import ScheduleService

    await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="c5@test.com")
    booking_id = await _make_booking(db_session)

    await ScheduleService(db_session).cancel_booking(booking_id, "개인 사정", student)

    notifs = await _notifs(db_session, TEACHER_ID, "lessonCancelled")
    assert len(notifs) == 1, "student cancelling a booking must notify the teacher"


# ---------------------------------------------------------------------------
# MED — 신청 생성 → 교사 미통지 (신규 타입 lessonRequestReceived)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_request_create_notifies_teacher(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import LessonRequestCreate
    from app.services.lesson_request_service import LessonRequestService

    await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="c6@test.com")

    await LessonRequestService(db_session).create(
        LessonRequestCreate(
            teacher_id=TEACHER_PROF_ID,
            request_type="regular",
            instrument="violin",
            preferred_slots=[],
        ),
        student,
    )

    notifs = await _notifs(db_session, TEACHER_ID, "lessonRequestReceived")
    assert len(notifs) == 1, "student creating a request must notify the teacher"


# ---------------------------------------------------------------------------
# MED — 그룹수업 대기승격 / 자동취소 상대 통지
# ---------------------------------------------------------------------------


async def _make_group_schedule(db: AsyncSession, *, class_id: str = "gc-1", waitlist_count: int = 1) -> str:
    from app.models.lesson import LessonClass, LessonClassType
    from app.models.schedule import GroupClass, GroupClassType, NoShowPolicy
    from app.models.schedule_ext import GroupClassSchedule, GroupScheduleStatus

    if await db.scalar(select(LessonClass).where(LessonClass.id == class_id)) is None:
        db.add(
            LessonClass(id=class_id, teacher_id=TEACHER_PROF_ID, name="테스트 그룹수업", type=LessonClassType.private)
        )
        await db.flush()
    # P1-0 이후 ``group_class_id`` 는 ``group_classes`` 를 참조하고 소유권도 여기서
    # 해석된다. 마이그레이션의 백필과 같게 **같은 id** 의 GroupClass 를 미러링한다.
    if await db.scalar(select(GroupClass).where(GroupClass.id == class_id)) is None:
        db.add(
            GroupClass(
                id=class_id,
                teacher_id=TEACHER_PROF_ID,
                name="테스트 그룹수업",
                type=GroupClassType.regular,
                max_capacity=1,
                waitlist_capacity=3,
                no_show_policy=NoShowPolicy.deductCredit,
                duration_minutes=60,
                booking_deadline_minutes=60,
                cancel_deadline_minutes=1440,
                is_active=True,
            )
        )
        await db.flush()
    schedule = GroupClassSchedule(
        group_class_id=class_id,
        start_time=dt.datetime(2026, 4, 1, 10, tzinfo=dt.UTC),
        end_time=dt.datetime(2026, 4, 1, 11, tzinfo=dt.UTC),
        max_capacity=1,
        waitlist_capacity=3,
        current_bookings=0,
        waitlist_count=waitlist_count,
        status=GroupScheduleStatus.open,
    )
    db.add(schedule)
    await db.flush()
    return schedule.id


@pytest.mark.asyncio
async def test_waitlist_promotion_notifies_student(db_session: AsyncSession, create_test_user):
    from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking
    from app.services.schedule_ext_service import ScheduleExtService

    await create_test_user(user_id=TEACHER_ID, role="teacher")
    # 승격 대상 학생 — GroupClassBooking.student_id 에 실 User.id 를 직접 사용(FK-safe 해소).
    await create_test_user(user_id="u-promoted", role="student", email="c7@test.com")
    schedule_id = await _make_group_schedule(db_session, waitlist_count=1)

    wl = GroupClassBooking(
        schedule_id=schedule_id,
        student_id="u-promoted",
        status=GroupBookingStatus.waitlist,
        waitlist_position=1,
    )
    db_session.add(wl)
    await db_session.flush()

    await ScheduleExtService(db_session)._promote_from_waitlist(schedule_id)

    notifs = await _notifs(db_session, "u-promoted", "lessonBooked")
    assert len(notifs) == 1, "auto-promoted waitlist student must be notified their spot is confirmed"


@pytest.mark.asyncio
async def test_auto_cancel_waitlist_notifies_students(db_session: AsyncSession, create_test_user):
    from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking
    from app.services.schedule_ext_service import ScheduleExtService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id="u-wl1", role="student", email="c8a@test.com")
    await create_test_user(user_id="u-wl2", role="student", email="c8b@test.com")
    schedule_id = await _make_group_schedule(db_session, waitlist_count=2)

    for i, uid in enumerate(("u-wl1", "u-wl2"), start=1):
        db_session.add(
            GroupClassBooking(
                schedule_id=schedule_id,
                student_id=uid,
                status=GroupBookingStatus.waitlist,
                waitlist_position=i,
            )
        )
    await db_session.flush()

    await ScheduleExtService(db_session).auto_cancel_waitlist(schedule_id, teacher)

    assert len(await _notifs(db_session, "u-wl1", "lessonCancelled")) == 1
    assert len(await _notifs(db_session, "u-wl2", "lessonCancelled")) == 1
