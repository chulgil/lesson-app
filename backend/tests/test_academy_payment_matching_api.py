"""Tests for academy payment matching endpoints — AC-M3 §4 수기 입력 + 1탭 확정.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.2, §6.3, §7.6.

원칙:
- 앱은 송금을 수행하지 않는다. 학원장이 통장에서 본 입금을 앱에 기록.
- 자동 매칭 금지 — 학원장 1탭 확정만 허용.
- depositor_raw / memo_raw 원문 영구 보존 (분쟁 증거).
- 매칭 확정 시 AcademyPayment 생성 + invoice status 갱신 + tx state='matched'.
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
from app.models.notification import Notification

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


async def _create_academy_with_invoice(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    *,
    base_amount: int = 200000,
    parent_user_id: str | None = None,
) -> tuple[str, str, str]:
    """학원 + 학생 + sent 상태 invoice 생성. Returns (academy_id, student_id, invoice_id)."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"pm-{uuid4().hex[:8]}", "name": "매칭 테스트", "also_register_as_teacher": True},
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
        json={
            "name": "김지민",
            "instrument": "피아노",
            "teacher_member_id": teacher_member.id,
            **({"parent_user_id": parent_user_id} if parent_user_id else {}),
        },
    )
    student_id = student_resp.json()["id"]
    invoice_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_id,
            "period_year": 2026,
            "period_month": 6,
            "base_amount": base_amount,
        },
    )
    return academy_id, student_id, invoice_resp.json()["id"]


# ---------------------------------------------------------------------------
# 수기 입력 (§5.2)
# ---------------------------------------------------------------------------


async def test_bank_transaction_manual_entry_creates_unmatched(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원장 수기 입력 1건 → state='unmatched', depositor_raw 원문 보존."""
    academy_id, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)

    response = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={
            "depositor_raw": "김지민 어머니",
            "amount": 200000,
            "tx_at": datetime.now(UTC).isoformat(),
            "memo_raw": "0418지민",
            "bank_name": "KB",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["depositor_raw"] == "김지민 어머니"
    assert body["amount"] == 200000
    assert body["memo_raw"] == "0418지민"
    assert body["bank_name"] == "KB"
    assert body["source"] == "manual"
    assert body["state"] == "unmatched"
    assert body["matched_invoice_id"] is None


async def test_bank_transaction_list_filters_by_state(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """state 쿼리로 unmatched/matched/ignored 필터."""
    academy_id, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)
    # 입력 3건.
    for name in ("김지민 어머니", "이지수 엄마", "박민준"):
        await client.post(
            f"/api/v1/academies/{academy_id}/billing/bank-transactions",
            headers=_owner_headers(),
            json={
                "depositor_raw": name,
                "amount": 200000,
                "tx_at": datetime.now(UTC).isoformat(),
            },
        )

    # 기본 — 전체 3건.
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 3

    # state=unmatched — 3건 동일.
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions?state=unmatched",
        headers=_owner_headers(),
    )
    assert response.json()["total_count"] == 3

    # state=matched — 0건.
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions?state=matched",
        headers=_owner_headers(),
    )
    assert response.json()["total_count"] == 0


# ---------------------------------------------------------------------------
# 1탭 매칭 확정 (§6.3)
# ---------------------------------------------------------------------------


async def test_match_full_amount_marks_invoice_paid(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """1탭 확정: 전액 매칭 → AcademyPayment 생성 + invoice paid + tx state='matched'."""
    academy_id, _, invoice_id = await _create_academy_with_invoice(client, db_session, create_test_user)
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={
            "depositor_raw": "김지민 어머니",
            "amount": 200000,
            "tx_at": datetime.now(UTC).isoformat(),
        },
    )
    tx_id = tx_resp.json()["id"]

    match_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )
    assert match_resp.status_code == 200
    body = match_resp.json()
    assert body["bank_transaction"]["state"] == "matched"
    assert body["bank_transaction"]["matched_invoice_id"] == invoice_id
    assert body["payment"]["paid_amount"] == 200000
    assert body["payment"]["invoice_id"] == invoice_id

    # invoice paid 갱신 확인.
    invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
    assert invoice.status == InvoiceStatus.paid

    # AcademyPayment row 생성 + audit 필드 (depositor_raw 원문 보존).
    payment = await db_session.scalar(select(AcademyPayment).where(AcademyPayment.invoice_id == invoice_id))
    assert payment is not None
    assert payment.depositor_raw == "김지민 어머니"
    assert payment.bank_tx_ref == tx_id

    # tx 갱신 확인 — matched_by_user_id, matched_at, matched_invoice_id.
    tx = await db_session.scalar(select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id))
    assert tx.state == AcademyBankTransactionState.matched
    assert tx.matched_invoice_id == invoice_id
    assert tx.matched_by_user_id == OWNER_USER_ID
    assert tx.matched_at is not None


async def test_match_partial_amount_keeps_invoice_sent(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """부분 매칭 (§7.2): paid_amount < invoice.total → invoice sent 유지 + tx matched."""
    academy_id, _, invoice_id = await _create_academy_with_invoice(client, db_session, create_test_user)
    # invoice 발송 (sent 상태로 만들기).
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_id]},
    )
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={
            "depositor_raw": "김지민 어머니",
            "amount": 100000,
            "tx_at": datetime.now(UTC).isoformat(),
        },
    )
    tx_id = tx_resp.json()["id"]

    match_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 100000},
    )
    assert match_resp.status_code == 200

    invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
    assert invoice.status == InvoiceStatus.sent  # 부분 입금 — paid 미달


async def test_match_cross_academy_tx_returns_400(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """tx 가 다른 학원 소속 → 400."""
    academy_a, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)
    # 두 번째 학원 + invoice.
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
    student_b_resp = await client.post(
        f"/api/v1/academies/{academy_b}/students",
        headers=_owner_headers(),
        json={"name": "박학생", "instrument": "피아노", "teacher_member_id": teacher_b.id},
    )
    invoice_b_resp = await client.post(
        f"/api/v1/academies/{academy_b}/billing/invoices",
        headers=_owner_headers(),
        json={
            "academy_student_id": student_b_resp.json()["id"],
            "period_year": 2026,
            "period_month": 6,
            "base_amount": 200000,
        },
    )
    invoice_b = invoice_b_resp.json()["id"]
    # tx 는 학원 A 소속.
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_a}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "임의", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]

    # 학원 A 경로로 학원 B invoice 매칭 시도 → 400.
    response = await client.post(
        f"/api/v1/academies/{academy_a}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_b, "paid_amount": 200000},
    )
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# Ignore / Revert (§6.2 무시, §7.6 매칭 취소)
# ---------------------------------------------------------------------------


async def test_ignore_transaction_changes_state(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """무시: state='ignored', 다음 list 에서 unmatched 필터로 안 잡힘."""
    academy_id, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "무통장입금", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]

    response = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/ignore",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    assert response.json()["state"] == "ignored"

    # unmatched 필터에서 제외.
    list_resp = await client.get(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions?state=unmatched",
        headers=_owner_headers(),
    )
    assert list_resp.json()["total_count"] == 0


async def test_revert_match_deletes_payment_and_resets_tx(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """매칭 취소 (§7.6): AcademyPayment 삭제 + tx state='unmatched' + invoice paid → sent."""
    academy_id, _, invoice_id = await _create_academy_with_invoice(client, db_session, create_test_user)
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
        headers=_owner_headers(),
        json={"invoice_ids": [invoice_id]},
    )
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "김지민 어머니", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )

    # 매칭 취소.
    revert_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/revert",
        headers=_owner_headers(),
    )
    assert revert_resp.status_code == 200
    assert revert_resp.json()["state"] == "unmatched"
    assert revert_resp.json()["matched_invoice_id"] is None

    # AcademyPayment 삭제 확인.
    payment = await db_session.scalar(select(AcademyPayment).where(AcademyPayment.invoice_id == invoice_id))
    assert payment is None

    # invoice paid → sent 회귀.
    invoice = await db_session.scalar(select(AcademyInvoice).where(AcademyInvoice.id == invoice_id))
    assert invoice.status == InvoiceStatus.sent


async def test_revert_only_allowed_on_matched_tx(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """unmatched tx 에 revert → 409."""
    academy_id, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "임의", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]

    response = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/revert",
        headers=_owner_headers(),
    )
    assert response.status_code == 409


# ---------------------------------------------------------------------------
# 권한 (§9)
# ---------------------------------------------------------------------------


async def test_non_owner_cannot_create_bank_transaction(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원 owner 가 아닌 사용자 → 403 (require_owner_context)."""
    academy_id, _, _ = await _create_academy_with_invoice(client, db_session, create_test_user)

    # 다른 사용자 (학원 소속 아님).
    other_user_id = "other-user-id"
    await create_test_user(user_id=other_user_id, role="teacher", name="다른교사", email="other@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': other_user_id, 'role': 'teacher'})}"}

    response = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=other_headers,
        json={"depositor_raw": "임의", "amount": 100000, "tx_at": datetime.now(UTC).isoformat()},
    )
    assert response.status_code == 403


# ---------------------------------------------------------------------------
# M2 — 입금액 초과 매칭 방지
# ---------------------------------------------------------------------------


async def test_match_paid_amount_exceeds_tx_returns_400(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """M2: paid_amount 가 통장 입금액(tx.amount)을 초과하면 400 — 정산 왜곡 방지."""
    academy_id, _, invoice_id = await _create_academy_with_invoice(client, db_session, create_test_user)
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "김지민 어머니", "amount": 100000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )
    assert resp.status_code == 400

    # 매칭 미적용 — tx unmatched 유지, payment 미생성.
    tx = await db_session.scalar(select(AcademyBankTransaction).where(AcademyBankTransaction.id == tx_id))
    assert tx.state == AcademyBankTransactionState.unmatched
    payment = await db_session.scalar(select(AcademyPayment).where(AcademyPayment.bank_tx_ref == tx_id))
    assert payment is None


# ---------------------------------------------------------------------------
# M1 — 매칭 확정/취소 시 학부모 알림 (§6.3 step4, §7.6)
# ---------------------------------------------------------------------------


async def test_confirm_match_notifies_parent(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """매칭 확정 시 연결된 학부모에게 납부 확인 알림 (§6.3 step4)."""
    parent_user_id = "parent-user-id"
    await create_test_user(user_id=parent_user_id, role="parent", name="박영희", email="parent@test.com")
    academy_id, _, invoice_id = await _create_academy_with_invoice(
        client, db_session, create_test_user, parent_user_id=parent_user_id
    )
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "박영희", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]

    match_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )
    assert match_resp.status_code == 200

    notif = await db_session.scalar(select(Notification).where(Notification.user_id == parent_user_id))
    assert notif is not None
    assert notif.type == "academyPaymentMatched"


async def test_confirm_match_no_notification_when_parent_unlinked(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원만 등록한 학생(parent_user_id NULL)은 알림 대상이 없으므로 알림 미생성."""
    academy_id, _, invoice_id = await _create_academy_with_invoice(client, db_session, create_test_user)
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "김지민 어머니", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )
    notifs = (await db_session.scalars(select(Notification))).all()
    assert all(n.type != "academyPaymentMatched" for n in notifs)


async def test_revert_match_notifies_parent(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """매칭 취소 시 연결된 학부모에게 정정 알림 (§7.6)."""
    parent_user_id = "parent-user-id"
    await create_test_user(user_id=parent_user_id, role="parent", name="박영희", email="parent@test.com")
    academy_id, _, invoice_id = await _create_academy_with_invoice(
        client, db_session, create_test_user, parent_user_id=parent_user_id
    )
    tx_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions",
        headers=_owner_headers(),
        json={"depositor_raw": "박영희", "amount": 200000, "tx_at": datetime.now(UTC).isoformat()},
    )
    tx_id = tx_resp.json()["id"]
    await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/match",
        headers=_owner_headers(),
        json={"invoice_id": invoice_id, "paid_amount": 200000},
    )
    revert_resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/bank-transactions/{tx_id}/revert",
        headers=_owner_headers(),
    )
    assert revert_resp.status_code == 200

    notifs = (await db_session.scalars(select(Notification).where(Notification.user_id == parent_user_id))).all()
    assert any(n.type == "academyPaymentReverted" for n in notifs)
