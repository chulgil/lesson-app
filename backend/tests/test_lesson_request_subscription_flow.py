"""E2E tests: LessonRequest → SubscriptionProposal → Subscription flow.

Verifies GAP-1 through GAP-6 integration.
"""

from __future__ import annotations

import datetime as dt

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TEACHER_ID = "test-user-id"
TEACHER_PROF_ID = "test-user-id-prof"
STUDENT_ID = "test-student-id"


async def _create_lesson_request(
    db: AsyncSession,
    *,
    request_type: str = "regular",
    instrument: str = "violin",
    preferred_day: int = 2,  # Wednesday
    preferred_time: str = "15:00",
    preferred_duration: int = 60,
    preferred_slots: list | None = None,
) -> str:
    """Insert a LessonRequest with timeConfirmed status (negotiation already done)."""
    from app.models.schedule import LessonRequest

    lr = LessonRequest(
        student_id=STUDENT_ID,
        teacher_id=TEACHER_PROF_ID,
        request_type=request_type,
        instrument=instrument,
        preferred_day=preferred_day,
        preferred_time=preferred_time,
        preferred_duration=preferred_duration,
        preferred_slots=preferred_slots,
        status="timeConfirmed",
        expires_at=dt.datetime.now(dt.UTC) + dt.timedelta(days=7),
        current_round=1,
        is_returning_student=False,
    )
    db.add(lr)
    await db.flush()
    return lr.id


async def _create_template(db: AsyncSession, *, sub_type: str = "monthly", lessons: int = 4) -> str:
    """Insert a SubscriptionTemplate."""
    from app.models.subscription import SubscriptionTemplate

    t = SubscriptionTemplate(
        teacher_id=TEACHER_PROF_ID,
        name="테스트 템플릿",
        type=sub_type,
        lessons_count=lessons,
        amount=200000,
    )
    db.add(t)
    await db.flush()
    return t.id


async def _create_relationship(db: AsyncSession) -> str:
    """Insert a TeacherStudentRelation in pending state."""
    from app.models.relationship import TeacherStudentRelation
    from app.models.student import Student

    db.add(
        Student(
            id=STUDENT_ID,
            teacher_id=TEACHER_PROF_ID,
            name="Student",
            instrument="violin",
            user_id=STUDENT_ID,
        )
    )
    await db.flush()

    rel = TeacherStudentRelation(
        teacher_id=TEACHER_PROF_ID,
        student_id=STUDENT_ID,
        status="pending",
    )
    db.add(rel)
    await db.flush()
    return rel.id


# ---------------------------------------------------------------------------
# Service instantiation
# ---------------------------------------------------------------------------


def _sub_svc(db: AsyncSession):
    from app.services.subscription_service import SubscriptionService

    return SubscriptionService(db)


def _card_svc(db: AsyncSession):
    from app.services.schedule_confirmation_service import ScheduleConfirmationService

    return ScheduleConfirmationService(db)


class _FakeUser:
    def __init__(self, uid: str, role: str = "teacher"):
        self.id = uid
        self.role = role


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_full_happy_path_regular(db_session: AsyncSession, create_test_user):
    """GAP 1~6: Regular subscription full flow."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    lr_id = await _create_lesson_request(db_session)
    tmpl_id = await _create_template(db_session)
    rel_id = await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID, "teacher")
    student = _FakeUser(STUDENT_ID, "student")

    # Step 1: Teacher creates proposal linked to LessonRequest
    from app.schemas.subscription import SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(
            student_id=STUDENT_ID,
            recommended_template_id=tmpl_id,
            lesson_request_id=lr_id,
        ),
        teacher,
    )

    # GAP-1: Verify bidirectional link
    assert proposal.lesson_request_id == lr_id

    from app.models.schedule import LessonRequest

    lr = await db_session.get(LessonRequest, lr_id)
    assert lr.proposal_id == proposal.id
    assert lr.status == "proposalSent"  # GAP-6

    # Step 2: Student responds (notify payment)
    from app.schemas.subscription import ProposalRespondRequest

    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )

    await db_session.refresh(lr)
    assert lr.status == "paymentNotified"  # GAP-6

    # Step 3: Teacher confirms deposit
    result = await svc.confirm_proposal(proposal.id, teacher)
    assert result.status == "confirmed"
    assert result.subscription_id is not None

    # GAP-2: membership_id is real (not empty)
    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, result.subscription_id)
    assert sub.membership_id != ""
    assert sub.membership_id is not None

    # GAP-3: Relationship activated
    from app.models.relationship import TeacherStudentRelation

    rel = await db_session.get(TeacherStudentRelation, rel_id)
    assert rel.status == "active"
    assert rel.active_subscription_id == sub.id

    # GAP-4: Confirmation card created
    from app.models.policy import ScheduleConfirmationCard

    cards = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == sub.id)
        )
    ).all()
    assert len(cards) == 1
    card = cards[0]
    assert card.proposed_day == "2"
    assert card.proposed_time == "15:00"

    # GAP-6: LessonRequest status
    await db_session.refresh(lr)
    assert lr.status == "subscriptionIssued"

    # Step 4: Student confirms schedule card → bookings created (GAP-5)
    card_svc = _card_svc(db_session)
    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await card_svc.confirm_card(
        card.id,
        ScheduleConfirmationCardConfirm(action="confirmed"),
        student,
    )

    from app.models.lesson import Lesson
    from app.models.schedule import LessonBooking

    bookings = (
        await db_session.scalars(
            select(LessonBooking).where(
                LessonBooking.student_id == STUDENT_ID,
                LessonBooking.teacher_id == TEACHER_PROF_ID,
            )
        )
    ).all()
    assert len(bookings) == 4  # monthly, total_lessons=4
    assert all(booking.subscription_id == sub.id for booking in bookings)

    lessons = (
        await db_session.scalars(
            select(Lesson).where(
                Lesson.student_id == STUDENT_ID,
                Lesson.teacher_id == TEACHER_PROF_ID,
                Lesson.subscription_id == sub.id,
            )
        )
    ).all()
    assert len(lessons) == 4
    assert all(lesson.lesson_source == "subscriptionGenerated" for lesson in lessons)


@pytest.mark.asyncio
async def test_trial_single_booking(db_session: AsyncSession, create_test_user):
    """Trial subscription creates only 1 LessonBooking."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    lr_id = await _create_lesson_request(db_session, request_type="trial")
    tmpl_id = await _create_template(db_session, sub_type="trial", lessons=1)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    # Confirm card
    from app.models.policy import ScheduleConfirmationCard

    card = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
        )
    ).first()

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.lesson import Lesson
    from app.models.schedule import LessonBooking

    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 1
    assert bookings[0].lesson_type == "trial"
    assert all(booking.subscription_id == result.subscription_id for booking in bookings)

    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == STUDENT_ID))).all()
    assert len(lessons) == 1
    assert lessons[0].lesson_source == "subscriptionGenerated"


@pytest.mark.asyncio
async def test_package_first_booking_only(db_session: AsyncSession, create_test_user):
    """Package subscription creates only 1 LessonBooking initially."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    lr_id = await _create_lesson_request(db_session, request_type="package")
    tmpl_id = await _create_template(db_session, sub_type="package", lessons=12)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard

    card = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
        )
    ).first()

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.lesson import Lesson
    from app.models.schedule import LessonBooking

    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 1  # Package: first lesson only
    assert all(booking.subscription_id == result.subscription_id for booking in bookings)

    lessons = (await db_session.scalars(select(Lesson).where(Lesson.student_id == STUDENT_ID))).all()
    assert len(lessons) == 1
    assert lessons[0].lesson_source == "subscriptionGenerated"


@pytest.mark.asyncio
async def test_backward_compat_no_lesson_request(db_session: AsyncSession, create_test_user):
    """Proposal without lesson_request_id still works (backward compatibility)."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    tmpl_id = await _create_template(db_session)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    # No lesson_request_id
    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id),
        teacher,
    )
    assert proposal.lesson_request_id is None

    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)
    assert result.status == "confirmed"
    assert result.subscription_id is not None

    # membership_id should still be real (not empty)
    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, result.subscription_id)
    assert sub.membership_id != ""


@pytest.mark.asyncio
async def test_existing_membership_reused(db_session: AsyncSession, create_test_user):
    """Existing active membership is reused, not duplicated."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    # Pre-create a LessonClass + ClassMembership
    from app.models.lesson import ClassMembership, LessonClass

    lc = LessonClass(teacher_id=TEACHER_PROF_ID, name="기존 클래스", type="private")
    db_session.add(lc)
    await db_session.flush()

    existing_membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=STUDENT_ID,
        instrument="violin",
        status="active",
    )
    db_session.add(existing_membership)
    await db_session.flush()
    existing_id = existing_membership.id

    tmpl_id = await _create_template(db_session)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.subscription import Subscription

    sub = await db_session.get(Subscription, result.subscription_id)
    assert sub.membership_id == existing_id  # Reused, not new


@pytest.mark.asyncio
async def test_card_rejected_no_bookings(db_session: AsyncSession, create_test_user):
    """Rejecting confirmation card creates no bookings."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    lr_id = await _create_lesson_request(db_session)
    tmpl_id = await _create_template(db_session)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard

    card = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
        )
    ).first()

    # Reject the card
    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await _card_svc(db_session).confirm_card(
        card.id,
        ScheduleConfirmationCardConfirm(action="rejected"),
        student,
    )

    from app.models.schedule import LessonBooking

    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 0


@pytest.mark.asyncio
async def test_regular_multislot_distributes_across_weekly_slots(db_session: AsyncSession, create_test_user):
    """#301: proposed_slots(주N회)는 모든 주간 슬롯에 레슨을 분배해야 한다 (첫 슬롯만 X)."""
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    lr_id = await _create_lesson_request(db_session)
    tmpl_id = await _create_template(db_session)  # monthly, 4 lessons
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID, "teacher")
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard

    card = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
        )
    ).one()

    # 주2회: 월(0) 10:00 + 수(2) 15:00
    card.proposed_slots = [{"day": "0", "time": "10:00"}, {"day": "2", "time": "15:00"}]
    await db_session.flush()

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.lesson import Lesson

    lessons = (await db_session.scalars(select(Lesson).where(Lesson.subscription_id == result.subscription_id))).all()
    assert len(lessons) == 4  # total_lessons=4 across 2 weekly slots
    assert sorted(lsn.date.weekday() for lsn in lessons) == [0, 0, 2, 2]
    assert sorted(lsn.session_number for lsn in lessons) == [1, 2, 3, 4]
    assert {lsn.start_time for lsn in lessons} == {"10:00", "15:00"}


@pytest.mark.asyncio
async def test_auto_card_carries_preferred_slots_to_proposed_slots(db_session: AsyncSession, create_test_user):
    """#301 상류: 주N회 합의(preferred_slots)가 자동 확인카드의 proposed_slots 로 실려야 한다.

    수동 주입 없이 발급 → 카드 자동 생성 → 두 요일 분배까지 end-to-end 로 확인한다.
    """
    await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", name="Student", email="s@t.com")

    # 주2회 합의: 월(0) 10:00-11:00 + 수(2) 15:00-16:00
    lr_id = await _create_lesson_request(
        db_session,
        preferred_day=0,
        preferred_time="10:00",
        preferred_slots=[
            {"priority": 1, "day_of_week": 0, "start_time": "10:00", "end_time": "11:00"},
            {"priority": 2, "day_of_week": 2, "start_time": "15:00", "end_time": "16:00"},
        ],
    )
    tmpl_id = await _create_template(db_session)  # monthly, 4 lessons
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID, "teacher")
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id),
        student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard

    card = (
        await db_session.scalars(
            select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
        )
    ).one()

    # 상류 핵심: 카드가 두 슬롯을 그대로 운반 (수동 주입 없음).
    assert card.proposed_slots is not None
    assert [int(s["day"]) for s in card.proposed_slots] == [0, 2]
    assert {s["time"] for s in card.proposed_slots} == {"10:00", "15:00"}
    assert all(s["duration"] == 60 for s in card.proposed_slots)

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm

    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.lesson import Lesson

    lessons = (await db_session.scalars(select(Lesson).where(Lesson.subscription_id == result.subscription_id))).all()
    assert len(lessons) == 4
    assert sorted(lsn.date.weekday() for lsn in lessons) == [0, 0, 2, 2]
    assert {lsn.start_time for lsn in lessons} == {"10:00", "15:00"}
