"""Tests for academy payment matching split-match endpoint — AC-M3 §7.1.

Spec: docs/specs/web/academy/payment_matching_spec.md §7.1.

§7.1 형제 합산 분할 매칭: 한 통장 입금을 여러 invoice (형제 2~N명) 에 분할.
모든 결과 payment 는 같은 bank_tx_ref 공유 — 분쟁 시 원천 추적.
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
from app.models.academy_billing import (
    AcademyInvoice,
    AcademyPayment,
    InvoiceStatus,
)
from app.models.academy_payment_matching import (
    AcademyBankTransaction,
    AcademyBankTransactionState,
)

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


async def _create_academy(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> tuple[str, str]:
    """학원 + teacher_member_id 반환."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"pm-{uuid4().hex[:8]}", "name": "분할 테스트", "also_register_as_teacher": True},
    )
    academy_id = academy_resp.json()["id"]
    teacher_member = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    return academy_id, teacher_member.id


async def _add_student_with_invoice(
    client: AsyncClient,
    *,
    academy_id: str,
    teacher_member_id: str,
    name: str,
    base_amount: int = 200000,
    period_month: int = 6,
) -> str:
    """학생 + sent invoice 추가 → invoice_id 반환."""
    student_resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_owner_headers(),
        json={"name": name, "instrument": "피아노", "teacher_member_id": teacher_member_id},
    )
    student_id = student_resp.json()["id"]
    invoice_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_id,
            "period_year": 2026,
            "period_month": period_month,
            "base_amount": base_amount,
        },
    )
    invoice_id = invoice_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_id]},
    )
    return invoice_id


async def _create_tx(client: AsyncClient, academy_id: str, *, depositor: str, amount: int) -> str:
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": depositor, "amount": amount, "tx_at": datetime.now(UTC).isoformat()},
    )
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# 정상 분할
# ---------------------------------------------------------------------------


async def test_split_match_two_siblings_each_paid_in_full(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """형제 2명 invoice 에 전액 분할 매칭 → 각 invoice paid, 2 payment 같은 bank_tx_ref."""
    academy_id, teacher_id = await _create_academy(client, db_session, create_test_user)
    invoice_a = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지민", base_amount=200000
    )
    invoice_b = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지호", base_amount=180000
    )
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=380000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={
            "splits": [
                {"invoice_id": invoice_a, "paid_amount": 200000},
                {"invoice_id": invoice_b, "paid_amount": 180000},
            ]
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["bank_transaction"]["state"] == "matched"
    # 분할 매칭은 matched_invoice_id NULL (단일 FK 의미 없음).
    assert body["bank_transaction"]["matched_invoice_id"] is None
    assert body["bank_transaction"]["matched_by_user_id"] == OWNER_USER_ID
    assert len(body["payments"]) == 2

    payment_invoice_ids = {p["invoice_id"] for p in body["payments"]}
    assert payment_invoice_ids == {invoice_a, invoice_b}

    # 각 invoice paid.
    for invoice_id in (invoice_a, invoice_b):
        invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
        assert invoice.status == InvoiceStatus.paid

    # AcademyPayment 2건 — bank_tx_ref 동일 + depositor_raw 보존.
    payments = (await db_session.scalars(select(AcademyPayment).where(AcademyPayment.bank_tx_ref == tx_id))).all()
    assert len(payments) == 2
    assert {p.depositor_raw for p in payments} == {"김 어머니"}


async def test_split_match_partial_amounts_keep_invoice_sent(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """부분 분할 매칭 (각 invoice 미달) → invoice sent 유지."""
    academy_id, teacher_id = await _create_academy(client, db_session, create_test_user)
    invoice_a = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지민", base_amount=200000
    )
    invoice_b = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지호", base_amount=200000
    )
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=200000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={
            "splits": [
                {"invoice_id": invoice_a, "paid_amount": 100000},
                {"invoice_id": invoice_b, "paid_amount": 100000},
            ]
        },
    )
    assert resp.status_code == 200
    for invoice_id in (invoice_a, invoice_b):
        invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
        assert invoice.status == InvoiceStatus.sent  # 미달.


# ---------------------------------------------------------------------------
# 검증 에러
# ---------------------------------------------------------------------------


async def test_split_match_duplicate_invoice_returns_400(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """같은 invoice_id 가 splits 에 2번 → 400."""
    academy_id, teacher_id = await _create_academy(client, db_session, create_test_user)
    invoice_id = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지민"
    )
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=200000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={
            "splits": [
                {"invoice_id": invoice_id, "paid_amount": 100000},
                {"invoice_id": invoice_id, "paid_amount": 100000},
            ]
        },
    )
    assert resp.status_code == 400


async def test_split_match_empty_splits_returns_422(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """splits 빈 배열 → 422 (pydantic min_length)."""
    academy_id, _ = await _create_academy(client, db_session, create_test_user)
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=100000)

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={"splits": []},
    )
    assert resp.status_code == 422


async def test_split_match_cross_academy_invoice_returns_400(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """다른 학원 invoice 가 splits 에 포함 → 400."""
    academy_a, teacher_a = await _create_academy(client, db_session, create_test_user)
    invoice_a = await _add_student_with_invoice(
        client, academy_id=academy_a, teacher_member_id=teacher_a, name="김지민"
    )

    # 두 번째 학원.
    academy_b_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"pm-b-{uuid4().hex[:8]}", "name": "다른 학원", "also_register_as_teacher": True},
    )
    academy_b = academy_b_resp.json()["id"]
    teacher_b = await db_session.scalar(
        select(AcademyMember)
        .where(AcademyMember.academy_id == academy_b)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    invoice_b = await _add_student_with_invoice(
        client, academy_id=academy_b, teacher_member_id=teacher_b.id, name="박학생"
    )
    tx_id = await _create_tx(client, academy_a, depositor="섞여있음", amount=200000)

    resp = await client.post(
        f"/api/v1/academies/{academy_a}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={
            "splits": [
                {"invoice_id": invoice_a, "paid_amount": 100000},
                {"invoice_id": invoice_b, "paid_amount": 100000},
            ]
        },
    )
    assert resp.status_code == 400


async def test_split_match_already_matched_tx_returns_409(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """이미 matched tx → 409."""
    academy_id, teacher_id = await _create_academy(client, db_session, create_test_user)
    invoice_a = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지민"
    )
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=200000)
    # 단일 match 먼저 확정.
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_a, "paid_amount": 200000},
    )

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={"splits": [{"invoice_id": invoice_a, "paid_amount": 200000}]},
    )
    assert resp.status_code == 409


# ---------------------------------------------------------------------------
# Revert 분할 매칭
# ---------------------------------------------------------------------------


async def test_revert_split_match_resets_all_invoices(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """분할 매칭 revert → 2 payment 삭제 + 두 invoice 모두 paid→sent 회귀 + tx unmatched."""
    academy_id, teacher_id = await _create_academy(client, db_session, create_test_user)
    invoice_a = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지민", base_amount=200000
    )
    invoice_b = await _add_student_with_invoice(
        client, academy_id=academy_id, teacher_member_id=teacher_id, name="김지호", base_amount=180000
    )
    tx_id = await _create_tx(client, academy_id, depositor="김 어머니", amount=380000)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/split-match",
        headers=_owner_headers(),
        json={
            "splits": [
                {"invoice_id": invoice_a, "paid_amount": 200000},
                {"invoice_id": invoice_b, "paid_amount": 180000},
            ]
        },
    )

    # revert.
    revert_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/revert",
        headers=_owner_headers(),
    )
    assert revert_resp.status_code == 200
    assert revert_resp.json()["state"] == "unmatched"

    # 2 payment 모두 삭제.
    payments = (await db_session.scalars(select(AcademyPayment).where(AcademyPayment.bank_tx_ref == tx_id))).all()
    assert len(payments) == 0

    # 두 invoice 모두 paid→sent.
    for invoice_id in (invoice_a, invoice_b):
        invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
        assert invoice.status == InvoiceStatus.sent

    # tx 회귀.
    tx = await db_session.scalar(select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id))
    assert tx.state == AcademyBankTransactionState.unmatched
    assert tx.matched_invoice_id is None
    assert tx.matched_by_user_id is None
