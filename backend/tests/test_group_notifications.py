"""P2-2 그룹 알림 5종 BE emit — 전이별 Notification row 검증.

그룹 수업에서 "상대가 알게 되는가" 를 서버 row 로 고정한다. FE 로컬 알림은
액터 기기에서만 뜨므로(#1191) 예약된 학생·학부모는 서버가 쓰지 않으면 끝까지
모른다. 5전이를 덮는다.

1. 드롭인 예약 확정 → 학생 (대기 등록은 제외 — 확정이 아니다)
2. 전일 리마인더 (KST 내일 회차, 배치)
3. 당일 리마인더 (KST 오늘 회차, 배치)
4. 드롭인 회차 오픈 → 담당 교사의 학생 브로드캐스트 (반 회차는 제외)
5. 노쇼 처리 → 학생 + 연결된 학부모 (출석은 제외)

기존 대기승급·자동취소 알림(#1207)은 본 스코프 밖 — 여기서 재발행하지 않는다.

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P2-2.
"""

from __future__ import annotations

import datetime as dt
from types import SimpleNamespace
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.schedule_ext_service import ScheduleExtService

_KST = ZoneInfo("Asia/Seoul")


# ---------------------------------------------------------------------------
# fixtures / helpers
# ---------------------------------------------------------------------------


async def _notifications(db_session: AsyncSession, notification_type: str | None = None) -> list:
    from app.models.notification import Notification

    query = select(Notification)
    if notification_type is not None:
        query = query.where(Notification.type == notification_type)
    rows = await db_session.scalars(query.order_by(Notification.created_at))
    return list(rows.all())


async def _make_teacher(create_test_user, user_id: str = "t-user") -> SimpleNamespace:
    """User + Teacher 프로필. current_user 대용 객체를 돌려준다."""
    await create_test_user(user_id=user_id, role="teacher", email=f"{user_id}@test.com")
    return SimpleNamespace(id=user_id, role="teacher")


async def _make_student(
    db_session: AsyncSession,
    create_test_user,
    *,
    user_id: str,
    teacher_id: str,
    name: str = "학생",
) -> str:
    """User + Student 프로필 생성 후 Student.id 반환."""
    from app.models.student import Student

    await create_test_user(user_id=user_id, role="student", name=name, email=f"{user_id}@test.com")
    student = Student(id=f"{user_id}-prof", user_id=user_id, teacher_id=teacher_id, name=name)
    db_session.add(student)
    await db_session.flush()
    return student.id


async def _make_group_class(
    db_session: AsyncSession,
    *,
    teacher_id: str,
    class_type: str = "dropIn",
    max_capacity: int = 6,
    waitlist_capacity: int | None = 2,
) -> str:
    from app.models.schedule import GroupClass, GroupClassType

    group_class = GroupClass(
        teacher_id=teacher_id,
        name="원데이 특강",
        type=GroupClassType(class_type),
        max_capacity=max_capacity,
        waitlist_capacity=waitlist_capacity,
    )
    db_session.add(group_class)
    await db_session.flush()
    return group_class.id


async def _make_schedule(
    db_session: AsyncSession,
    *,
    group_class_id: str,
    start: dt.datetime,
    max_capacity: int = 6,
    waitlist_capacity: int | None = 2,
) -> str:
    from app.models.schedule_ext import GroupClassSchedule

    schedule = GroupClassSchedule(
        group_class_id=group_class_id,
        start_time=start,
        end_time=start + dt.timedelta(hours=1),
        max_capacity=max_capacity,
        waitlist_capacity=waitlist_capacity,
    )
    db_session.add(schedule)
    await db_session.flush()
    return schedule.id


async def _teacher_profile_id(db_session: AsyncSession, user_id: str) -> str:
    from app.models.teacher import Teacher

    return await db_session.scalar(select(Teacher.id).where(Teacher.user_id == user_id))


# ---------------------------------------------------------------------------
# 1. 예약 확정
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_confirmed_booking_notifies_the_student(db_session: AsyncSession, create_test_user) -> None:
    """드롭인 예약이 확정되면 예약한 학생 User 에게 알림 row 가 남는다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    class_id = await _make_group_class(db_session, teacher_id=teacher_id)
    schedule_id = await _make_schedule(
        db_session,
        group_class_id=class_id,
        start=dt.datetime.now(dt.UTC) + dt.timedelta(days=3),
    )

    service = ScheduleExtService(db_session)
    await service.create_group_booking({"schedule_id": schedule_id, "student_id": student_id}, teacher)

    rows = await _notifications(db_session, "groupBookingConfirmed")
    assert len(rows) == 1, "확정 예약 1건당 알림 1건"
    assert rows[0].user_id == "s1", "수신자는 Student.id 가 아니라 학생 User.id"
    assert "원데이 특강" in rows[0].body


@pytest.mark.asyncio
async def test_waitlisted_booking_does_not_notify_confirmation(db_session: AsyncSession, create_test_user) -> None:
    """정원이 차서 대기로 들어간 예약은 '확정' 알림을 내지 않는다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    first = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    second = await _make_student(db_session, create_test_user, user_id="s2", teacher_id=teacher_id)
    class_id = await _make_group_class(db_session, teacher_id=teacher_id, max_capacity=1)
    schedule_id = await _make_schedule(
        db_session,
        group_class_id=class_id,
        start=dt.datetime.now(dt.UTC) + dt.timedelta(days=3),
        max_capacity=1,
    )

    service = ScheduleExtService(db_session)
    await service.create_group_booking({"schedule_id": schedule_id, "student_id": first}, teacher)
    await service.create_group_booking({"schedule_id": schedule_id, "student_id": second}, teacher)

    rows = await _notifications(db_session, "groupBookingConfirmed")
    assert [r.user_id for r in rows] == ["s1"], "대기 등록(s2)은 확정 알림 대상이 아니다"


# ---------------------------------------------------------------------------
# 2. 드롭인 오픈
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_dropin_schedule_open_broadcasts_to_teacher_students(db_session: AsyncSession, create_test_user) -> None:
    """드롭인 회차를 열면 그 교사의 학생 전원에게 오픈 알림이 나간다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await _make_student(db_session, create_test_user, user_id="s2", teacher_id=teacher_id)
    # 다른 교사의 학생 — 수신 대상이 아니다.
    other = await _make_teacher(create_test_user, user_id="t2-user")
    other_teacher_id = await _teacher_profile_id(db_session, other.id)
    await _make_student(db_session, create_test_user, user_id="s3", teacher_id=other_teacher_id)

    class_id = await _make_group_class(db_session, teacher_id=teacher_id, class_type="dropIn")
    service = ScheduleExtService(db_session)
    start = dt.datetime.now(dt.UTC) + dt.timedelta(days=5)
    await service.create_group_schedule(
        {"group_class_id": class_id, "start_time": start, "end_time": start + dt.timedelta(hours=1)},
        teacher,
    )

    rows = await _notifications(db_session, "groupDropInOpened")
    assert sorted(r.user_id for r in rows) == ["s1", "s2"], "담당 교사의 학생에게만 브로드캐스트"


@pytest.mark.asyncio
async def test_regular_class_schedule_does_not_broadcast_open(db_session: AsyncSession, create_test_user) -> None:
    """반(regular) 회차는 자동 생성되는 정기 일정이라 오픈 브로드캐스트 대상이 아니다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    class_id = await _make_group_class(db_session, teacher_id=teacher_id, class_type="regular")

    service = ScheduleExtService(db_session)
    start = dt.datetime.now(dt.UTC) + dt.timedelta(days=5)
    await service.create_group_schedule(
        {"group_class_id": class_id, "start_time": start, "end_time": start + dt.timedelta(hours=1)},
        teacher,
    )

    assert await _notifications(db_session, "groupDropInOpened") == []


# ---------------------------------------------------------------------------
# 3. 노쇼 경고
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_no_show_warns_student_and_linked_parent(db_session: AsyncSession, create_test_user) -> None:
    """노쇼 처리 시 학생 본인과 연결된 학부모 양쪽에 경고가 간다."""
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)

    await create_test_user(user_id="p1", role="parent", name="학부모", email="p1@test.com")
    parent = Parent(user_id="p1", name="학부모")
    db_session.add(parent)
    await db_session.flush()
    db_session.add(
        ParentChildRelation(
            parent_id=parent.id,
            student_id=student_id,
            status=ParentChildRelationStatus.active,
        )
    )
    await db_session.flush()

    class_id = await _make_group_class(db_session, teacher_id=teacher_id)
    schedule_id = await _make_schedule(
        db_session,
        group_class_id=class_id,
        start=dt.datetime.now(dt.UTC) - dt.timedelta(hours=2),
    )
    service = ScheduleExtService(db_session)
    booking = await service.create_group_booking({"schedule_id": schedule_id, "student_id": student_id}, teacher)

    await service.mark_attendance(booking.id, False, teacher)

    rows = await _notifications(db_session, "groupNoShowWarning")
    assert sorted(r.user_id for r in rows) == ["p1", "s1"], "학생 + 연결된 학부모"


@pytest.mark.asyncio
async def test_attendance_does_not_warn(db_session: AsyncSession, create_test_user) -> None:
    """출석 확정은 노쇼 경고를 내지 않는다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    class_id = await _make_group_class(db_session, teacher_id=teacher_id)
    schedule_id = await _make_schedule(
        db_session,
        group_class_id=class_id,
        start=dt.datetime.now(dt.UTC) - dt.timedelta(hours=2),
    )
    service = ScheduleExtService(db_session)
    booking = await service.create_group_booking({"schedule_id": schedule_id, "student_id": student_id}, teacher)

    await service.mark_attendance(booking.id, True, teacher)

    assert await _notifications(db_session, "groupNoShowWarning") == []


# ---------------------------------------------------------------------------
# 4. 리마인더 배치 (전일 / 당일)
# ---------------------------------------------------------------------------


async def _booked_schedule_at(
    db_session: AsyncSession,
    create_test_user,
    *,
    start_kst: dt.datetime,
) -> str:
    """KST 벽시계 기준 지정 시각에 확정 예약 1건이 달린 회차를 만든다."""
    teacher = await _make_teacher(create_test_user)
    teacher_id = await _teacher_profile_id(db_session, teacher.id)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    class_id = await _make_group_class(db_session, teacher_id=teacher_id)
    # 회차 시각은 프로덕션과 같은 규약으로 KST aware 저장 (J3 반복 생성과 동일).
    schedule_id = await _make_schedule(db_session, group_class_id=class_id, start=start_kst)
    service = ScheduleExtService(db_session)
    await service.create_group_booking({"schedule_id": schedule_id, "student_id": student_id}, teacher)
    return schedule_id


@pytest.mark.asyncio
async def test_day_before_reminder_targets_tomorrow_only(db_session: AsyncSession, create_test_user) -> None:
    """전일 리마인더는 KST '내일' 회차만 집는다."""
    from app.jobs.group_lesson_reminder_jobs import run_group_lesson_reminder_day_before

    tomorrow = dt.datetime.now(_KST).replace(hour=18, minute=0, second=0, microsecond=0) + dt.timedelta(days=1)
    await _booked_schedule_at(db_session, create_test_user, start_kst=tomorrow)

    result = await run_group_lesson_reminder_day_before(db_session)

    assert result["sent"] == 1
    rows = await _notifications(db_session, "groupLessonReminderDayBefore")
    assert [r.user_id for r in rows] == ["s1"]


@pytest.mark.asyncio
async def test_day_before_reminder_skips_far_future(db_session: AsyncSession, create_test_user) -> None:
    """모레 이후 회차는 전일 리마인더 대상이 아니다."""
    from app.jobs.group_lesson_reminder_jobs import run_group_lesson_reminder_day_before

    far = dt.datetime.now(_KST).replace(hour=18, minute=0, second=0, microsecond=0) + dt.timedelta(days=5)
    await _booked_schedule_at(db_session, create_test_user, start_kst=far)

    result = await run_group_lesson_reminder_day_before(db_session)

    assert result["sent"] == 0
    assert await _notifications(db_session, "groupLessonReminderDayBefore") == []


@pytest.mark.asyncio
async def test_day_of_reminder_targets_today(db_session: AsyncSession, create_test_user) -> None:
    """당일 리마인더는 KST '오늘' 회차를 집는다."""
    from app.jobs.group_lesson_reminder_jobs import run_group_lesson_reminder_day_of

    today = dt.datetime.now(_KST).replace(hour=23, minute=30, second=0, microsecond=0)
    await _booked_schedule_at(db_session, create_test_user, start_kst=today)

    result = await run_group_lesson_reminder_day_of(db_session)

    assert result["sent"] == 1
    rows = await _notifications(db_session, "groupLessonReminderDayOf")
    assert [r.user_id for r in rows] == ["s1"]


@pytest.mark.asyncio
async def test_reminder_job_is_idempotent(db_session: AsyncSession, create_test_user) -> None:
    """같은 배치를 두 번 돌려도 알림은 1건 — 재실행 안전(멱등)."""
    from app.jobs.group_lesson_reminder_jobs import run_group_lesson_reminder_day_before

    tomorrow = dt.datetime.now(_KST).replace(hour=18, minute=0, second=0, microsecond=0) + dt.timedelta(days=1)
    await _booked_schedule_at(db_session, create_test_user, start_kst=tomorrow)

    first = await run_group_lesson_reminder_day_before(db_session)
    second = await run_group_lesson_reminder_day_before(db_session)

    assert (first["sent"], second["sent"]) == (1, 0)
    assert len(await _notifications(db_session, "groupLessonReminderDayBefore")) == 1


@pytest.mark.asyncio
async def test_cancelled_booking_gets_no_reminder(db_session: AsyncSession, create_test_user) -> None:
    """취소된 예약은 리마인더 대상이 아니다."""
    from app.jobs.group_lesson_reminder_jobs import run_group_lesson_reminder_day_before
    from app.models.schedule_ext import GroupBookingStatus, GroupClassBooking

    tomorrow = dt.datetime.now(_KST).replace(hour=18, minute=0, second=0, microsecond=0) + dt.timedelta(days=1)
    schedule_id = await _booked_schedule_at(db_session, create_test_user, start_kst=tomorrow)
    booking = await db_session.scalar(select(GroupClassBooking).where(GroupClassBooking.schedule_id == schedule_id))
    booking.status = GroupBookingStatus.cancelled
    await db_session.flush()

    result = await run_group_lesson_reminder_day_before(db_session)

    assert result["sent"] == 0


# ---------------------------------------------------------------------------
# 5. 타입 등록 계약 — 역할 필터가 학생/학부모 인박스에 노출하는가
# ---------------------------------------------------------------------------


def test_group_types_are_registered_for_student_role() -> None:
    """5종이 학생 역할 타깃으로 등록되어야 인앱 목록/뱃지에서 걸러지지 않는다."""
    from app.services.notification_service import STUDENT_NOTIFICATION_TYPES

    assert {
        "groupBookingConfirmed",
        "groupLessonReminderDayBefore",
        "groupLessonReminderDayOf",
        "groupDropInOpened",
        "groupNoShowWarning",
    } <= STUDENT_NOTIFICATION_TYPES
