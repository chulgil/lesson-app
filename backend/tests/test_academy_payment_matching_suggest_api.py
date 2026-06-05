"""Tests for academy payment matching suggestion endpoints — AC-M3 §3 fuzzy.

Spec: docs/specs/web/academy/payment_matching_spec.md §3, §6.1, §6.2.

원칙 (§1):
- 자동 매칭 금지 — 알고리즘은 후보만 제시.
- 학원장이 1탭 확정 → suggestion user_decision='accepted'.
- 다른 pending 후보는 'rejected'.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_payment_matching import (
    AcademyBankTransaction,
    AcademyBankTransactionState,
    AcademyPaymentMatchSuggestion,
    AcademyPaymentMatchSuggestionDecision,
)
from app.services.academy_payment_matching_fuzzy import (
    STRONG_SUGGESTION_THRESHOLD,
    WEAK_SUGGESTION_THRESHOLD,
)

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


async def _setup(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    *,
    student_name: str = "김지민",
    invoice_amount: int = 200000,
    send_invoice: bool = True,
) -> tuple[str, str, str]:
    """학원 + 학생 + (sent) invoice 1건. Returns (academy_id, student_id, invoice_id)."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"sg-{uuid4().hex[:8]}", "name": "제안 테스트", "also_register_as_teacher": True},
    )
    academy_id = academy_resp.json()["id"]
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    student_resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": student_name, "instrument": "피아노", "teacher_member_id": teacher_member.id},
    )
    student_id = student_resp.json()["id"]
    invoice_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_id,
            "period_year": 2026,
            "period_month": 6,
            "base_amount": invoice_amount,
        },
    )
    invoice_id = invoice_resp.json()["id"]
    if send_invoice:
        await client.post(
            f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
            headers=_owner_headers(),
            json={"invoice_ids": [invoice_id]},
        )
    return academy_id, student_id, invoice_id


async def _create_tx(
    client: AsyncClient,
    academy_id: str,
    *,
    depositor: str,
    amount: int,
    tx_at: datetime | None = None,
    memo: str | None = None,
) -> str:
    """Helper: bank transaction 수기 입력 → tx_id 반환."""
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={
            "depositor_raw": depositor,
            "amount": amount,
            "tx_at": (tx_at or datetime.now(UTC)).isoformat(),
            **({"memo_raw": memo} if memo else {}),
        },
    )
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# §6.1 1건 매칭 — 강한 제안
# ---------------------------------------------------------------------------


async def test_suggest_strong_match_for_full_amount_and_family_title(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """김지민 어머니 / 200,000 / 발송 직후 → 강한 제안 (≥0.85), tx.state='suggested'."""
    academy_id, _, invoice_id = await _setup(client, db_session, create_test_user)
    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_count"] >= 1

    top = body["suggestions"][0]
    assert top["invoice_id"] == invoice_id
    assert top["score"] >= STRONG_SUGGESTION_THRESHOLD
    assert top["features"]["amount_exact"] == 1.0
    assert top["features"]["family_title"] == 1.0
    assert top["user_decision"] == "pending"

    # tx 상태 갱신.
    tx = await db_session.scalar(select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id))
    assert tx.state == AcademyBankTransactionState.suggested
    assert tx.match_score is not None and tx.match_score >= STRONG_SUGGESTION_THRESHOLD


# ---------------------------------------------------------------------------
# §6.1 약한 제안 — 부분 입금
# ---------------------------------------------------------------------------


async def test_suggest_weak_match_for_partial_amount(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """부분 입금 (100,000 / invoice 200,000) → 약한 제안 [0.60, 0.85)."""
    academy_id, _, _ = await _setup(client, db_session, create_test_user)
    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=100_000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["total_count"] == 1
    top = body["suggestions"][0]
    assert WEAK_SUGGESTION_THRESHOLD <= top["score"] < STRONG_SUGGESTION_THRESHOLD
    assert top["features"]["amount_exact"] == 0.5


# ---------------------------------------------------------------------------
# §3.1 임계 미달 — 후보 0건
# ---------------------------------------------------------------------------


async def test_suggest_returns_empty_when_below_threshold(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """완전 다른 입금자 + 다른 금액 + 시각 멀어짐 → 0건."""
    academy_id, _, _ = await _setup(client, db_session, create_test_user)
    # 시각 60일 차이, 다른 이름, 초과 금액.
    tx_at = datetime.now(UTC) + timedelta(days=60)
    tx_id = await _create_tx(client, academy_id, depositor="박철수", amount=350_000, tx_at=tx_at)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["total_count"] == 0

    # tx 는 unmatched 유지.
    tx = await db_session.scalar(select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id))
    assert tx.state == AcademyBankTransactionState.unmatched


# ---------------------------------------------------------------------------
# §4 동명이인 / 형제 — 후보 2+
# ---------------------------------------------------------------------------


async def test_suggest_includes_multiple_candidates_for_homonyms(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """같은 학원에 동명이인 2명 → 후보 2개 반환 (학원장이 선택)."""
    academy_id, _, invoice_1 = await _setup(client, db_session, create_test_user, student_name="김지민")
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    # 동명이인 학생 + invoice 추가.
    student_2_resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": "김지민", "instrument": "바이올린", "teacher_member_id": teacher_member.id},
    )
    invoice_2_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_2_resp.json()["id"],
            "period_year": 2026,
            "period_month": 7,  # 다른 월 — 동일 학생/월 UNIQUE 회피
            "base_amount": 200_000,
        },
    )
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_2_resp.json()["id"]]},
    )

    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["total_count"] == 2
    invoice_ids = {s["invoice_id"] for s in body["suggestions"]}
    assert invoice_1 in invoice_ids
    assert invoice_2_resp.json()["id"] in invoice_ids


# ---------------------------------------------------------------------------
# §3 paid invoice 제외
# ---------------------------------------------------------------------------


async def test_suggest_excludes_paid_invoices(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """이미 paid 인 invoice 는 후보에서 제외."""
    academy_id, _, invoice_id = await _setup(client, db_session, create_test_user)
    # invoice 를 paid 처리 (다른 tx 로 매칭).
    tx_for_pay = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_for_pay}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200_000},
    )

    # 새 tx 입력 후 suggest → 0건.
    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    assert resp.json()["total_count"] == 0


# ---------------------------------------------------------------------------
# §6.3 confirm 시 suggestion accepted/rejected
# ---------------------------------------------------------------------------


async def test_confirm_match_marks_suggestion_accepted_others_rejected(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """1탭 확정 시 선택한 suggestion → accepted, 같은 tx 의 다른 pending → rejected."""
    academy_id, _, invoice_1 = await _setup(client, db_session, create_test_user, student_name="김지민")
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    # 동명이인 학생/invoice 추가 — suggestion 후보 2개 생성.
    student_2_resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": "김지민", "instrument": "바이올린", "teacher_member_id": teacher_member.id},
    )
    invoice_2_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_2_resp.json()["id"],
            "period_year": 2026,
            "period_month": 7,
            "base_amount": 200_000,
        },
    )
    invoice_2 = invoice_2_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_2]},
    )

    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )

    # invoice_1 으로 confirm.
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_1, "paid_amount": 200_000},
    )

    # suggestion 결정 audit.
    sugg_1 = await db_session.scalar(
        select(AcademyPaymentMatchSuggestion)
        .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx_id)
        .where(AcademyPaymentMatchSuggestion.invoice_id == invoice_1)
    )
    sugg_2 = await db_session.scalar(
        select(AcademyPaymentMatchSuggestion)
        .where(AcademyPaymentMatchSuggestion.bank_transaction_id == tx_id)
        .where(AcademyPaymentMatchSuggestion.invoice_id == invoice_2)
    )
    assert sugg_1.user_decision == AcademyPaymentMatchSuggestionDecision.accepted
    assert sugg_1.decided_at is not None
    assert sugg_2.user_decision == AcademyPaymentMatchSuggestionDecision.rejected
    assert sugg_2.decided_at is not None


# ---------------------------------------------------------------------------
# GET /suggestions — 기존 후보 조회 (재계산 없음)
# ---------------------------------------------------------------------------


async def test_list_suggestions_returns_stored_candidates(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """suggest 후 GET 으로 동일 후보 조회 가능 (재계산 없이)."""
    academy_id, _, _ = await _setup(client, db_session, create_test_user)
    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)

    suggest_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    total_after_suggest = suggest_resp.json()["total_count"]

    list_resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggestions",
        headers=_owner_headers(),
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["total_count"] == total_after_suggest


# ---------------------------------------------------------------------------
# 권한 / 에러
# ---------------------------------------------------------------------------


async def test_suggest_on_matched_tx_returns_409(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """이미 matched 인 tx 에 suggest → 409."""
    academy_id, _, invoice_id = await _setup(client, db_session, create_test_user)
    tx_id = await _create_tx(client, academy_id, depositor="김지민 어머니", amount=200_000)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200_000},
    )

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
        headers=_owner_headers(),
    )
    assert resp.status_code == 409
