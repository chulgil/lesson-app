"""#1198 — pending lesson-request(14d) + subscription-proposal(7d) expiry jobs.

이 만료는 그동안 internal-API 엔드포인트로만 집행돼 외부 cron 미설정 시 영구
pending 잔존 위험이 있었다. in-process daily job 으로 등록되므로, 여기서는 job
runner 가 만료 대상만 정확히 expired 로 전이하고 미만료는 건드리지 않음을 가드한다.
"""

from __future__ import annotations

import datetime as dt

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.jobs.pending_expiry_jobs import (
    run_lesson_request_expiry_job,
    run_proposal_expiry_job,
)


def _now() -> dt.datetime:
    return dt.datetime.now(dt.UTC)


async def _add_request(db: AsyncSession, *, status: str, expires_at: dt.datetime) -> str:
    from app.models.schedule import LessonRequest

    lr = LessonRequest(
        student_id="s-expiry",
        teacher_id="t-expiry",
        request_type="regular",
        instrument="violin",
        preferred_day=2,
        preferred_time="15:00",
        preferred_duration=60,
        status=status,
        expires_at=expires_at,
        current_round=1,
        is_returning_student=False,
    )
    db.add(lr)
    await db.flush()
    return lr.id


async def _add_proposal(db: AsyncSession, *, status: str, expires_at: dt.datetime) -> str:
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    p = SubscriptionProposal(
        teacher_id="t-expiry",
        student_id="s-expiry",
        status=ProposalStatus(status),
        expires_at=expires_at,
    )
    db.add(p)
    await db.flush()
    return p.id


@pytest.mark.asyncio
async def test_lesson_request_expiry_transitions_past_due(db_session: AsyncSession) -> None:
    from app.models.schedule import LessonRequest

    rid = await _add_request(db_session, status="pending", expires_at=_now() - dt.timedelta(days=1))

    result = await run_lesson_request_expiry_job(session=db_session)

    assert result["expired"] == 1
    lr = await db_session.get(LessonRequest, rid)
    assert lr is not None and lr.status == "expired"


@pytest.mark.asyncio
async def test_lesson_request_expiry_leaves_future_pending(db_session: AsyncSession) -> None:
    from app.models.schedule import LessonRequest

    rid = await _add_request(db_session, status="pending", expires_at=_now() + dt.timedelta(days=3))

    result = await run_lesson_request_expiry_job(session=db_session)

    assert result["expired"] == 0
    lr = await db_session.get(LessonRequest, rid)
    assert lr is not None and lr.status == "pending"


@pytest.mark.asyncio
async def test_proposal_expiry_transitions_past_due(db_session: AsyncSession) -> None:
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    pid = await _add_proposal(db_session, status="pending", expires_at=_now() - dt.timedelta(days=1))

    result = await run_proposal_expiry_job(session=db_session)

    assert result["expired"] == 1
    p = await db_session.get(SubscriptionProposal, pid)
    assert p is not None and p.status == ProposalStatus.expired


@pytest.mark.asyncio
async def test_proposal_expiry_leaves_future_pending(db_session: AsyncSession) -> None:
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    pid = await _add_proposal(db_session, status="pending", expires_at=_now() + dt.timedelta(days=3))

    result = await run_proposal_expiry_job(session=db_session)

    assert result["expired"] == 0
    p = await db_session.get(SubscriptionProposal, pid)
    assert p is not None and p.status == ProposalStatus.pending
