"""#1192 — accepting a confirmed-lesson schedule change must move the Lesson.

Bug: `LessonRequestService.add_event(scheduleChangeAccepted)` only recorded a
timeline event; it never moved the target `Lesson` (calendar SSOT) nor its
`LessonBooking` (conflict/credit SSOT). The weekly/daily calendar therefore kept
the old time even after both parties agreed → no-show risk.

These tests drive the *live* path (POST /schedule/lesson-requests/{id}/events →
LessonRequestService.add_event) at the service layer with hand-built rows.
FK enforcement is OFF by default in this suite, so a Subscription bridge row can
link the request to its lessons without creating FK parents.
"""

from __future__ import annotations

import datetime as dt
from types import SimpleNamespace

import pytest

from app.models.lesson import Lesson, LessonSource
from app.models.schedule import (
    BookingLessonType,
    BookingStatus,
    LessonBooking,
    LessonRequest,
)
from app.models.subscription import SubscriptionProposal
from app.schemas.request_event import RequestEventCreate, TimeSlotOptionSchema
from app.services.lesson_request_service import LessonRequestService

STUDENT_USER_ID = "stu-user"
TEACHER_USER_ID = "tch-user"
STUDENT_PROFILE_ID = "stu-profile"
REQUEST_ID = "req-1"
PROPOSAL_ID = "prop-1"
SUBSCRIPTION_ID = "sub-1"


def _student_user() -> SimpleNamespace:
    return SimpleNamespace(id=STUDENT_USER_ID, role="student")


def _teacher_user() -> SimpleNamespace:
    return SimpleNamespace(id=TEACHER_USER_ID, role="teacher")


def _next_monday(reference: dt.date) -> dt.date:
    """Return a strictly-future Monday (avoids today-edge ambiguity)."""
    days = (7 - reference.weekday()) % 7
    return reference + dt.timedelta(days=days or 7)


async def _seed_request_and_subscription(db_session) -> None:
    db_session.add(
        LessonRequest(
            id=REQUEST_ID,
            student_id=STUDENT_USER_ID,
            teacher_id=TEACHER_USER_ID,
            status="subscriptionIssued",
            proposal_id=PROPOSAL_ID,
            expires_at=dt.datetime.now(dt.UTC) + dt.timedelta(days=30),
        )
    )
    # Bridge: request → proposal → subscription_id (Subscription.lesson_request_id
    # does not exist; the link lives on SubscriptionProposal).
    db_session.add(
        SubscriptionProposal(
            id=PROPOSAL_ID,
            lesson_request_id=REQUEST_ID,
            subscription_id=SUBSCRIPTION_ID,
            teacher_id=TEACHER_USER_ID,
            student_id=STUDENT_PROFILE_ID,
            expires_at=dt.datetime.now(dt.UTC) + dt.timedelta(days=30),
        )
    )


async def _seed_lesson(
    db_session,
    *,
    lesson_id: str,
    date: dt.date,
    start_time: str,
    session_number: int,
    subscription_id: str = SUBSCRIPTION_ID,
    status: str = "scheduled",
) -> None:
    db_session.add(
        Lesson(
            id=lesson_id,
            teacher_id=TEACHER_USER_ID,
            student_id=STUDENT_PROFILE_ID,
            student_name="시나리오 학생",
            instrument="violin",
            date=date,
            start_time=start_time,
            duration=60,
            status=status,
            subscription_id=subscription_id,
            session_number=session_number,
            lesson_source=LessonSource.subscription_generated,
        )
    )
    db_session.add(
        LessonBooking(
            teacher_id=TEACHER_USER_ID,
            student_id=STUDENT_PROFILE_ID,
            lesson_type=BookingLessonType.regular,
            scheduled_date=date,
            scheduled_time=start_time,
            duration=60,
            instrument="violin",
            subscription_id=subscription_id,
            status=BookingStatus.confirmed,
        )
    )


async def _propose_then_accept(
    db_session,
    *,
    change_type: str,
    new_day_of_week: int,
    new_time: str,
) -> None:
    svc = LessonRequestService(db_session)
    await svc.add_event(
        REQUEST_ID,
        RequestEventCreate(
            request_id=REQUEST_ID,
            actor_type="student",
            actor_id=STUDENT_USER_ID,
            event_type="scheduleChangeProposed",
            schedule_change_type=change_type,
            suggested_slots=[
                TimeSlotOptionSchema(
                    id="slot-1",
                    day_of_week=new_day_of_week,
                    start_time=new_time,
                    end_time="17:00",
                )
            ],
            message="시간 변경 제안",
        ),
        _student_user(),
    )
    await svc.add_event(
        REQUEST_ID,
        RequestEventCreate(
            request_id=REQUEST_ID,
            actor_type="teacher",
            actor_id=TEACHER_USER_ID,
            event_type="scheduleChangeAccepted",
            selected_slot_index=0,
            message="네, 변경할게요.",
        ),
        _teacher_user(),
    )


@pytest.mark.asyncio
async def test_single_accept_moves_next_upcoming_lesson(db_session):
    """single change → next upcoming lesson moves to the new weekday+time (same week)."""
    monday = _next_monday(dt.date.today())
    await _seed_request_and_subscription(db_session)
    await _seed_lesson(db_session, lesson_id="les-1", date=monday, start_time="14:00", session_number=1)
    await db_session.flush()

    # Wednesday 16:00 (day_of_week 2)
    await _propose_then_accept(db_session, change_type="singleLesson", new_day_of_week=2, new_time="16:00")

    lesson = await db_session.get(Lesson, "les-1")
    assert lesson.start_time == "16:00", "single accept must move Lesson.start_time"
    assert lesson.date == monday + dt.timedelta(days=2), "single accept must move Lesson.date to the new weekday"

    booking = (
        await db_session.execute(
            LessonBooking.__table__.select().where(LessonBooking.subscription_id == SUBSCRIPTION_ID)
        )
    ).first()
    assert booking is not None
    assert str(booking.scheduled_time) == "16:00", "matching LessonBooking must move too"
    assert booking.scheduled_date == monday + dt.timedelta(days=2)


@pytest.mark.asyncio
async def test_bulk_accept_moves_all_future_lessons(db_session):
    """bulk change → all future confirmed lessons shift to the new weekday+time."""
    monday = _next_monday(dt.date.today())
    await _seed_request_and_subscription(db_session)
    for i in range(3):
        await _seed_lesson(
            db_session,
            lesson_id=f"les-{i + 1}",
            date=monday + dt.timedelta(weeks=i),
            start_time="14:00",
            session_number=i + 1,
        )
    await db_session.flush()

    # Thursday 10:00 (day_of_week 3)
    await _propose_then_accept(db_session, change_type="bulkChange", new_day_of_week=3, new_time="10:00")

    for i in range(3):
        lesson = await db_session.get(Lesson, f"les-{i + 1}")
        expected = monday + dt.timedelta(weeks=i, days=3)
        assert lesson.start_time == "10:00", f"bulk accept must move lesson {i + 1} time"
        assert lesson.date == expected, f"bulk accept must move lesson {i + 1} date to its week's Thursday"


@pytest.mark.asyncio
async def test_accept_rejects_when_new_slot_conflicts(db_session):
    """A conflicting existing booking at the new slot → 409, and the lesson stays put."""
    from fastapi import HTTPException

    monday = _next_monday(dt.date.today())
    await _seed_request_and_subscription(db_session)
    await _seed_lesson(db_session, lesson_id="les-1", date=monday, start_time="14:00", session_number=1)
    # Another subscription already occupies Wednesday 16:00 for the same teacher.
    conflict_date = monday + dt.timedelta(days=2)
    db_session.add(
        LessonBooking(
            teacher_id=TEACHER_USER_ID,
            student_id="other-student",
            lesson_type=BookingLessonType.regular,
            scheduled_date=conflict_date,
            scheduled_time="16:00",
            duration=60,
            subscription_id="sub-other",
            status=BookingStatus.confirmed,
        )
    )
    await db_session.flush()

    with pytest.raises(HTTPException) as exc:
        await _propose_then_accept(db_session, change_type="singleLesson", new_day_of_week=2, new_time="16:00")
    assert exc.value.status_code == 409

    lesson = await db_session.get(Lesson, "les-1")
    assert lesson.start_time == "14:00", "conflicting accept must NOT move the lesson"
    assert lesson.date == monday


@pytest.mark.asyncio
async def test_accept_with_no_future_lessons_is_noop(db_session):
    """No future confirmed lessons → accept still succeeds without error, nothing moves."""
    past = dt.date.today() - dt.timedelta(days=7)
    await _seed_request_and_subscription(db_session)
    await _seed_lesson(db_session, lesson_id="les-past", date=past, start_time="14:00", session_number=1)
    await db_session.flush()

    await _propose_then_accept(db_session, change_type="singleLesson", new_day_of_week=2, new_time="16:00")

    lesson = await db_session.get(Lesson, "les-past")
    assert lesson.start_time == "14:00"
    assert lesson.date == past
