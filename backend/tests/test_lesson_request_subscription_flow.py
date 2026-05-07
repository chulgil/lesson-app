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
    cards = (await db_session.scalars(
        select(ScheduleConfirmationCard).where(
            ScheduleConfirmationCard.subscription_id == sub.id
        )
    )).all()
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

    from app.models.schedule import LessonBooking
    bookings = (await db_session.scalars(
        select(LessonBooking).where(
            LessonBooking.student_id == STUDENT_ID,
            LessonBooking.teacher_id == TEACHER_PROF_ID,
        )
    )).all()
    assert len(bookings) == 4  # monthly, total_lessons=4
    assert all(booking.subscription_id == sub.id for booking in bookings)


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

    from app.schemas.subscription import SubscriptionProposalCreate, ProposalRespondRequest

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id), student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    # Confirm card
    from app.models.policy import ScheduleConfirmationCard
    card = (await db_session.scalars(
        select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
    )).first()

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm
    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.schedule import LessonBooking
    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 1
    assert bookings[0].lesson_type == "trial"
    assert all(booking.subscription_id == result.subscription_id for booking in bookings)


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

    from app.schemas.subscription import SubscriptionProposalCreate, ProposalRespondRequest

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id), student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard
    card = (await db_session.scalars(
        select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
    )).first()

    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm
    await _card_svc(db_session).confirm_card(card.id, ScheduleConfirmationCardConfirm(action="confirmed"), student)

    from app.models.schedule import LessonBooking
    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 1  # Package: first lesson only
    assert all(booking.subscription_id == result.subscription_id for booking in bookings)


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

    from app.schemas.subscription import SubscriptionProposalCreate, ProposalRespondRequest

    # No lesson_request_id
    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id),
        teacher,
    )
    assert proposal.lesson_request_id is None

    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id), student,
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
        lesson_class_id=lc.id, student_id=STUDENT_ID, instrument="violin", status="active",
    )
    db_session.add(existing_membership)
    await db_session.flush()
    existing_id = existing_membership.id

    tmpl_id = await _create_template(db_session)
    await _create_relationship(db_session)

    svc = _sub_svc(db_session)
    teacher = _FakeUser(TEACHER_ID)
    student = _FakeUser(STUDENT_ID, "student")

    from app.schemas.subscription import SubscriptionProposalCreate, ProposalRespondRequest

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id), student,
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

    from app.schemas.subscription import SubscriptionProposalCreate, ProposalRespondRequest

    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=tmpl_id, lesson_request_id=lr_id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="notify_payment", selected_template_id=tmpl_id), student,
    )
    result = await svc.confirm_proposal(proposal.id, teacher)

    from app.models.policy import ScheduleConfirmationCard
    card = (await db_session.scalars(
        select(ScheduleConfirmationCard).where(ScheduleConfirmationCard.subscription_id == result.subscription_id)
    )).first()

    # Reject the card
    from app.schemas.schedule_confirmation import ScheduleConfirmationCardConfirm
    await _card_svc(db_session).confirm_card(
        card.id, ScheduleConfirmationCardConfirm(action="rejected"), student,
    )

    from app.models.schedule import LessonBooking
    bookings = (await db_session.scalars(select(LessonBooking).where(LessonBooking.student_id == STUDENT_ID))).all()
    assert len(bookings) == 0
