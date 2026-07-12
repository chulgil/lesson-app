"""#1193 — 협상·수강권 제안 전환의 상대방 인앱 알림 emit.

감사 0712: FE 로컬 알림은 자기 기기에만 표시되므로(#1191) BE 가 상태 전환
시 상대방 Notification row 를 만들어야 상대가 인지할 수 있다. 협상 3전환
(제안/역제안/수락)과 수강권 제안 2전환(제안 도착/수락·입금통보)을 고정한다.
타입은 notification_master.md 의 기존 FE 타입만 사용한다.
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


async def _make_request(db: AsyncSession, *, status: str = "pending") -> str:
    from app.models.schedule import LessonRequest

    lr = LessonRequest(
        student_id=STUDENT_ID,
        teacher_id=TEACHER_PROF_ID,
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


@pytest.mark.asyncio
async def test_teacher_propose_notifies_student(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import TimeProposalCreate
    from app.services.lesson_request_service import LessonRequestService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    await create_test_user(user_id=STUDENT_ID, role="student", email="nn-s@test.com")
    request_id = await _make_request(db_session)

    await LessonRequestService(db_session).propose_alternatives(
        request_id,
        TimeProposalCreate(slots=[_SLOT], message="이 시간 어때요?"),
        teacher,
    )

    notifs = await _notifs(db_session, STUDENT_ID, "scheduleChangeAlternative")
    assert len(notifs) == 1, "teacher proposal must create one in-app row for the student"
    assert f"/schedule/request/{request_id}" == notifs[0].action_url


@pytest.mark.asyncio
async def test_student_counter_notifies_teacher(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import TimeProposalCreate
    from app.services.lesson_request_service import LessonRequestService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="nn-s2@test.com")
    request_id = await _make_request(db_session)

    svc = LessonRequestService(db_session)
    await svc.propose_alternatives(request_id, TimeProposalCreate(slots=[_SLOT]), teacher)
    await svc.counter_propose(
        request_id,
        TimeProposalCreate(slots=[{"day_of_week": 3, "start_time": "16:00", "end_time": "17:00"}]),
        student,
    )

    notifs = await _notifs(db_session, TEACHER_ID, "scheduleChangeRequested")
    assert len(notifs) == 1, "student counter must create one in-app row for the teacher"


@pytest.mark.asyncio
async def test_student_accept_notifies_teacher(db_session: AsyncSession, create_test_user):
    from app.schemas.lesson_request import AlternativeAccept, TimeProposalCreate
    from app.services.lesson_request_service import LessonRequestService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="nn-s3@test.com")
    request_id = await _make_request(db_session)

    svc = LessonRequestService(db_session)
    await svc.propose_alternatives(request_id, TimeProposalCreate(slots=[_SLOT]), teacher)
    await svc.accept_alternative(request_id, AlternativeAccept(selected_slot_index=0), student)

    notifs = await _notifs(db_session, TEACHER_ID, "scheduleChangeApproved")
    assert len(notifs) == 1, "student accept must create one in-app row for the teacher"


@pytest.mark.asyncio
async def test_proposal_created_and_accepted_notifications(db_session: AsyncSession, create_test_user):
    """수강권 제안 도착 → 학생 proposalReceived / 수락·입금통보 → 교사 proposalAccepted."""
    from app.models.subscription import SubscriptionTemplate
    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate
    from app.services.subscription_service import SubscriptionService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="nn-s4@test.com")

    template = SubscriptionTemplate(
        teacher_id=TEACHER_PROF_ID,
        name="테스트 템플릿",
        type="monthly",
        lessons_count=4,
        amount=200000,
    )
    db_session.add(template)
    await db_session.flush()

    svc = SubscriptionService(db_session)
    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=template.id),
        teacher,
    )

    received = await _notifs(db_session, STUDENT_ID, "proposalReceived")
    assert len(received) == 1, "proposal creation must create one in-app row for the student"

    await svc.respond_to_proposal(
        proposal.id,
        ProposalRespondRequest(action="notify_payment", selected_template_id=template.id),
        student,
    )

    accepted = await _notifs(db_session, TEACHER_ID, "proposalAccepted")
    assert len(accepted) == 1, "acceptance must create one in-app row for the teacher"


@pytest.mark.asyncio
async def test_reject_does_not_emit_untyped_notification(db_session: AsyncSession, create_test_user):
    """reject 는 전용 FE 타입이 없어 이번 범위에서 emit 하지 않는다 (잔여 — #1193 코멘트)."""
    from app.models.subscription import SubscriptionTemplate
    from app.schemas.subscription import ProposalRespondRequest, SubscriptionProposalCreate
    from app.services.subscription_service import SubscriptionService

    teacher = await create_test_user(user_id=TEACHER_ID, role="teacher")
    student = await create_test_user(user_id=STUDENT_ID, role="student", email="nn-s5@test.com")
    template = SubscriptionTemplate(
        teacher_id=TEACHER_PROF_ID,
        name="테스트 템플릿",
        type="monthly",
        lessons_count=4,
        amount=200000,
    )
    db_session.add(template)
    await db_session.flush()

    svc = SubscriptionService(db_session)
    proposal = await svc.create_proposal(
        SubscriptionProposalCreate(student_id=STUDENT_ID, recommended_template_id=template.id),
        teacher,
    )
    await svc.respond_to_proposal(
        proposal.id, ProposalRespondRequest(action="reject", rejection_reason="시간 안 맞음"), student
    )

    assert await _notifs(db_session, TEACHER_ID, "proposalAccepted") == []
