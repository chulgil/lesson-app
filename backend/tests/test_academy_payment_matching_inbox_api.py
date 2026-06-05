"""Tests for academy payment matching inbox endpoint — AC-M3 §6.2 일괄 매칭 화면.

Spec: docs/specs/web/academy/payment_matching_spec.md §6.2.

목적: 학원장이 한 화면에서 미매칭/제안 행을 빠르게 처리할 수 있게,
- tx 행 + 각 tx 의 top-1 suggestion + invoice 요약 + 학생 이름을
- 한 번의 API 호출로 받는다 (N+1 query 회피).

원칙: matched/ignored 행은 제외 — 일괄 매칭 화면은 처리 대기 행만.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


async def _setup_academy_with_invoice(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    *,
    student_name: str = "김지민",
    period_month: int = 6,
    amount: int = 200_000,
    send: bool = True,
) -> tuple[str, str, str]:
    """학원 + 학생 + (sent) invoice. Returns (academy_id, student_id, invoice_id)."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"ib-{uuid4().hex[:8]}", "name": "Inbox 테스트", "also_register_as_teacher": True},
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
            "period_month": period_month,
            "base_amount": amount,
        },
    )
    invoice_id = invoice_resp.json()["id"]
    if send:
        await client.post(
            f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
            headers=_owner_headers(),
            json={"invoice_ids": [invoice_id]},
        )
    return academy_id, student_id, invoice_id


async def _add_student_with_invoice(
    client: AsyncClient,
    db_session: AsyncSession,
    *,
    academy_id: str,
    name: str,
    period_month: int,
    amount: int = 200_000,
) -> tuple[str, str]:
    """기존 학원에 학생 + invoice 추가."""
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    student_resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": name, "instrument": "피아노", "teacher_member_id": teacher_member.id},
    )
    student_id = student_resp.json()["id"]
    invoice_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_id,
            "period_year": 2026,
            "period_month": period_month,
            "base_amount": amount,
        },
    )
    invoice_id = invoice_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_id]},
    )
    return student_id, invoice_id


async def _create_tx_and_suggest(
    client: AsyncClient,
    academy_id: str,
    *,
    depositor: str,
    amount: int,
    run_suggest: bool = True,
) -> str:
    """수기 입력 후 선택적으로 suggest 실행 → tx_id 반환."""
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={
            "depositor_raw": depositor,
            "amount": amount,
            "tx_at": datetime.now(UTC).isoformat(),
        },
    )
    tx_id = tx_resp.json()["id"]
    if run_suggest:
        await client.post(
            f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/suggest",
            headers=_owner_headers(),
        )
    return tx_id


# ---------------------------------------------------------------------------
# 핵심: 미매칭 + 제안 행을 묶음으로 반환
# ---------------------------------------------------------------------------


async def test_inbox_returns_suggested_and_unmatched_rows(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """state=suggested (top suggestion 있음) + state=unmatched (없음) 모두 inbox 에 포함."""
    academy_id, _, invoice_id = await _setup_academy_with_invoice(client, db_session, create_test_user)

    # 강한 제안 1건.
    tx_suggested = await _create_tx_and_suggest(client, academy_id, depositor="김지민 어머니", amount=200_000)
    # suggest 미실행 — unmatched 유지.
    tx_unmatched = await _create_tx_and_suggest(
        client, academy_id, depositor="무통장입금", amount=999_999, run_suggest=False
    )

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/inbox",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_count"] == 2
    assert body["suggested_count"] == 1
    assert body["unmatched_count"] == 1

    rows_by_tx = {row["bank_transaction"]["id"]: row for row in body["rows"]}
    suggested_row = rows_by_tx[tx_suggested]
    assert suggested_row["top_suggestion"] is not None
    assert suggested_row["top_suggestion"]["invoice_id"] == invoice_id
    assert suggested_row["top_invoice_id"] == invoice_id
    assert suggested_row["top_invoice_total"] == 200_000
    assert suggested_row["top_invoice_period"] == "2026-06"
    assert suggested_row["top_student_name"] == "김지민"

    unmatched_row = rows_by_tx[tx_unmatched]
    assert unmatched_row["top_suggestion"] is None
    assert unmatched_row["top_invoice_id"] is None
    assert unmatched_row["top_student_name"] is None


# ---------------------------------------------------------------------------
# top-1 은 점수가 가장 높은 후보
# ---------------------------------------------------------------------------


async def test_inbox_top_suggestion_is_highest_score(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """동명이인 → suggestion 2건 → top-1 은 더 높은 점수 (현재는 동점이면 둘 중 하나)."""
    academy_id, _, invoice_1 = await _setup_academy_with_invoice(
        client, db_session, create_test_user, student_name="김지민", period_month=6
    )
    _, invoice_2 = await _add_student_with_invoice(
        client, db_session, academy_id=academy_id, name="김지민", period_month=7, amount=180_000
    )

    # tx 가 200,000 — invoice_1 (200,000) 과 금액 정확 일치, invoice_2 (180,000) 은 초과 매칭(0).
    tx_id = await _create_tx_and_suggest(client, academy_id, depositor="김지민 어머니", amount=200_000)

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/inbox",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["total_count"] == 1
    row = body["rows"][0]
    assert row["bank_transaction"]["id"] == tx_id
    # 200,000 invoice 가 top — 금액 일치 1.0 가산.
    assert row["top_suggestion"]["invoice_id"] == invoice_1
    assert row["top_invoice_total"] == 200_000


# ---------------------------------------------------------------------------
# matched / ignored 제외
# ---------------------------------------------------------------------------


async def test_inbox_excludes_matched_and_ignored(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """일괄 매칭 화면은 처리 대기 행만 — matched/ignored 는 제외."""
    academy_id, _, invoice_id = await _setup_academy_with_invoice(client, db_session, create_test_user)

    # matched 1건.
    tx_matched = await _create_tx_and_suggest(client, academy_id, depositor="김지민 어머니", amount=200_000)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_matched}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200_000},
    )
    # ignored 1건.
    tx_ignored = await _create_tx_and_suggest(
        client, academy_id, depositor="무통장입금", amount=10_000, run_suggest=False
    )
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_ignored}/ignore",
        headers=_owner_headers(),
    )
    # 처리 대기 1건.
    await _create_tx_and_suggest(client, academy_id, depositor="박철수", amount=500_000, run_suggest=False)

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/inbox",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["total_count"] == 1
    assert body["unmatched_count"] == 1
    assert body["suggested_count"] == 0


# ---------------------------------------------------------------------------
# 권한
# ---------------------------------------------------------------------------


async def test_inbox_forbidden_for_non_owner(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id, _, _ = await _setup_academy_with_invoice(client, db_session, create_test_user)
    other_id = "other-user-id"
    await create_test_user(user_id=other_id, role="teacher", name="외부", email="other@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': other_id, 'role': 'teacher'})}"}

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/inbox",
        headers=other_headers,
    )
    assert resp.status_code == 403
