"""Tests for payment tracking dashboard — #424.

Coverage:
- Aggregation: filter by status (pending/paymentNotified) + non-expired only
- D+N ordering (largest first)
- count endpoint
- Manual resend with 30-minute cooldown
- Revoke (cancel) authorization
- Cron idempotency: D+1/D+3/D+7 each fire only once
"""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

TEACHER_ID = "test-user-id-prof"
STUDENT_ID = "student-001"


async def _create_proposal(
    db_session: AsyncSession,
    *,
    teacher_id: str = TEACHER_ID,
    student_id: str = STUDENT_ID,
    status: str = "pending",
    created_days_ago: int = 0,
    expires_in_days: int = 7,
    reminder_d1_sent_at: datetime | None = None,
    reminder_d3_sent_at: datetime | None = None,
    reminder_d7_sent_at: datetime | None = None,
    last_reminder_sent_at: datetime | None = None,
) -> str:
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    now = datetime.now(UTC)
    proposal = SubscriptionProposal(
        teacher_id=teacher_id,
        student_id=student_id,
        status=ProposalStatus(status),
        expires_at=now + timedelta(days=expires_in_days),
        reminder_d1_sent_at=reminder_d1_sent_at,
        reminder_d3_sent_at=reminder_d3_sent_at,
        reminder_d7_sent_at=reminder_d7_sent_at,
        last_reminder_sent_at=last_reminder_sent_at,
    )
    db_session.add(proposal)
    await db_session.flush()
    if created_days_ago:
        proposal.created_at = now - timedelta(days=created_days_ago)
    await db_session.commit()
    return proposal.id


@pytest.mark.asyncio
async def test_payment_pending_count_empty(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """0 pending proposals → count 0."""
    await create_test_user(user_id="test-user-id", role="teacher")
    response = await client.get(
        "/api/v1/subscriptions/payment-pending/count",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["count"] == 0


@pytest.mark.asyncio
async def test_payment_pending_list_filters_status_and_expiry(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Only pending + paymentNotified + non-expired proposals are returned."""
    await create_test_user(user_id="test-user-id", role="teacher")
    p1 = await _create_proposal(db_session, status="pending", created_days_ago=2)
    p2 = await _create_proposal(db_session, status="paymentNotified", created_days_ago=5)
    # excluded:
    await _create_proposal(db_session, status="confirmed", created_days_ago=1)
    await _create_proposal(db_session, status="rejected", created_days_ago=1)
    await _create_proposal(db_session, status="cancelled", created_days_ago=1)
    await _create_proposal(db_session, status="pending", expires_in_days=-1)  # already expired

    response = await client.get(
        "/api/v1/subscriptions/payment-pending",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    returned_ids = {p["proposal_id"] for p in data["pending"]}
    assert returned_ids == {p1, p2}
    assert data["total_count"] == 2


@pytest.mark.asyncio
async def test_payment_pending_ordered_by_days_descending(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Largest D+N first (oldest proposal at the top)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    p_recent = await _create_proposal(db_session, created_days_ago=0)
    p_old = await _create_proposal(db_session, created_days_ago=5)
    p_mid = await _create_proposal(db_session, created_days_ago=2)

    response = await client.get(
        "/api/v1/subscriptions/payment-pending",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    order = [p["proposal_id"] for p in response.json()["pending"]]
    assert order == [p_old, p_mid, p_recent]


@pytest.mark.asyncio
async def test_payment_pending_other_teachers_excluded(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A teacher only sees their own pending proposals."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_proposal(db_session, teacher_id=TEACHER_ID, created_days_ago=1)
    await _create_proposal(db_session, teacher_id="other-teacher-prof", created_days_ago=1)

    response = await client.get(
        "/api/v1/subscriptions/payment-pending",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["total_count"] == 1


@pytest.mark.asyncio
async def test_resend_proposal_sets_last_reminder_and_returns_canResend_false(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Resend updates last_reminder_sent_at and the next list response has canResend=false."""
    await create_test_user(user_id="test-user-id", role="teacher")
    pid = await _create_proposal(db_session, created_days_ago=3)

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/resend",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    # Subsequent list must reflect cooldown.
    listing = await client.get(
        "/api/v1/subscriptions/payment-pending",
        headers=auth_headers,
    )
    rows = listing.json()["pending"]
    assert len(rows) == 1
    assert rows[0]["can_resend"] is False


@pytest.mark.asyncio
async def test_resend_within_30min_blocked_with_409(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Manual resend within 30 minutes of the previous reminder is rejected (409)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    just_now = datetime.now(UTC) - timedelta(minutes=10)
    pid = await _create_proposal(
        db_session,
        created_days_ago=3,
        last_reminder_sent_at=just_now,
    )

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/resend",
        headers=auth_headers,
    )
    assert response.status_code == 409, response.text
    assert "30" in response.json()["detail"] or "cooldown" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_resend_other_teacher_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """A different teacher cannot resend someone else's proposal."""
    await create_test_user(user_id="test-user-id", role="teacher")
    pid = await _create_proposal(db_session, created_days_ago=1)

    await create_test_user(
        user_id="other-teacher-id",
        role="teacher",
        name="Other Teacher",
        email="other@test.com",
    )
    other_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'other-teacher-id', 'role': 'teacher'})}"
    }

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/resend",
        headers=other_headers,
    )
    assert response.status_code in (403, 404)


@pytest.mark.asyncio
async def test_revoke_marks_proposal_cancelled(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Revoke transitions status to cancelled and removes from pending list."""
    from app.models.subscription import ProposalStatus, SubscriptionProposal

    await create_test_user(user_id="test-user-id", role="teacher")
    pid = await _create_proposal(db_session, created_days_ago=1)

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/revoke",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text

    proposal = await db_session.get(SubscriptionProposal, pid)
    await db_session.refresh(proposal)
    assert proposal.status == ProposalStatus.cancelled

    listing = await client.get(
        "/api/v1/subscriptions/payment-pending",
        headers=auth_headers,
    )
    assert listing.json()["total_count"] == 0


@pytest.mark.asyncio
async def test_revoke_already_confirmed_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Revoking a confirmed proposal is 400 — confirmed is irreversible at this endpoint."""
    await create_test_user(user_id="test-user-id", role="teacher")
    pid = await _create_proposal(db_session, status="confirmed", created_days_ago=1)

    response = await client.post(
        f"/api/v1/subscriptions-proposals/{pid}/revoke",
        headers=auth_headers,
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_d1_cron_is_idempotent(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """Running D+1 cron twice still results in only one reminder timestamp."""
    from app.jobs.payment_reminder_jobs import run_payment_reminder_d1
    from app.models.subscription import SubscriptionProposal

    await create_test_user(user_id="test-user-id", role="teacher")
    pid = await _create_proposal(db_session, created_days_ago=1)

    first = await run_payment_reminder_d1(db_session)
    assert first["candidates"] == 1
    assert first["sent"] == 1

    second = await run_payment_reminder_d1(db_session)
    assert second["candidates"] == 0
    assert second["sent"] == 0

    proposal = await db_session.get(SubscriptionProposal, pid)
    await db_session.refresh(proposal)
    assert proposal.reminder_d1_sent_at is not None


@pytest.mark.asyncio
async def test_d3_cron_targets_proposals_3_days_old(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """D+3 cron picks up proposals 3 days old (and ignores newer ones)."""
    from app.jobs.payment_reminder_jobs import run_payment_reminder_d3

    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_proposal(db_session, created_days_ago=1)  # too new
    pid_d3 = await _create_proposal(db_session, created_days_ago=3)

    result = await run_payment_reminder_d3(db_session)
    assert result["candidates"] == 1
    assert result["sent"] == 1

    from app.models.subscription import SubscriptionProposal

    proposal = await db_session.get(SubscriptionProposal, pid_d3)
    await db_session.refresh(proposal)
    assert proposal.reminder_d3_sent_at is not None


@pytest.mark.asyncio
async def test_d7_cron_targets_proposals_about_to_expire(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """D+7 cron picks up proposals created 7 days ago."""
    from app.jobs.payment_reminder_jobs import run_payment_reminder_d7_final

    await create_test_user(user_id="test-user-id", role="teacher")
    await _create_proposal(db_session, created_days_ago=3)  # too new
    pid_d7 = await _create_proposal(db_session, created_days_ago=7)

    result = await run_payment_reminder_d7_final(db_session)
    assert result["candidates"] == 1
    assert result["sent"] == 1

    from app.models.subscription import SubscriptionProposal

    proposal = await db_session.get(SubscriptionProposal, pid_d7)
    await db_session.refresh(proposal)
    assert proposal.reminder_d7_sent_at is not None
