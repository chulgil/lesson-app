"""Tests for CSV import endpoint — AC-M3 §5.1.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.1.

학원장이 매월 통장 CSV 한 번에 업로드 → AcademyBankTransaction 일괄 생성 +
fuzzy 자동 실행 → suggested/unmatched 분류. 잘못된 행은 error_rows 로 보고하되
정상 행은 처리한다 (graceful).
"""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_payment_matching import (
    AcademyBankTransaction,
    AcademyBankTransactionSource,
    AcademyBankTransactionState,
)

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"


def _owner_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': OWNER_USER_ID, 'role': 'teacher'})}"}


async def _setup_academy(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    *,
    with_invoice_for_student: str | None = None,
    invoice_amount: int = 200_000,
) -> str:
    """학원 생성. with_invoice_for_student 지정 시 해당 학생 + sent invoice 추가."""
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    academy_resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={"slug": f"csv-{uuid4().hex[:8]}", "name": "CSV 테스트", "also_register_as_teacher": True},
    )
    academy_id = academy_resp.json()["id"]
    if with_invoice_for_student:
        teacher_member = await db_session.scalar(
            select(AcademyMember)
            .where(AcademyMember.academy_id == academy_id)
            .where(AcademyMember.role == AcademyMemberRole.teacher)
        )
        student_resp = await client.post(
            f"/api/v1/academies/{academy_id}/students",
            headers=_owner_headers(),
            json={
                "name": with_invoice_for_student,
                "instrument": "피아노",
                "teacher_member_id": teacher_member.id,
            },
        )
        invoice_resp = await client.post(
            f"/api/v1/academies/{academy_id}/billing/invoices",
            headers=_owner_headers(),
            json={
                "academy_student_id": student_resp.json()["id"],
                "period_year": 2026,
                "period_month": 5,
                "base_amount": invoice_amount,
            },
        )
        await client.post(
            f"/api/v1/academies/{academy_id}/billing/invoices/bulk-send",
            headers=_owner_headers(),
            json={"invoice_ids": [invoice_resp.json()["id"]]},
        )
    return academy_id


# ---------------------------------------------------------------------------
# 기본 — 정상 CSV 3행 → 3 tx 생성
# ---------------------------------------------------------------------------


async def test_csv_import_creates_unmatched_transactions(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원에 invoice 없으면 fuzzy 매칭 후보 0 → 모두 unmatched."""
    academy_id = await _setup_academy(client, db_session, create_test_user)
    csv_body = (
        "거래일시,입금자명,금액,메모,은행\n"
        "2026-05-03 14:30,김지민 어머니,200000,0418지민,KB\n"
        "2026-05-04 09:15,이지수 아빠,150000,,신한\n"
        "2026-05-05 11:00,박철수,300000,수업료,카뱅\n"
    )

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=_owner_headers(),
        files={"file": ("import.csv", csv_body.encode("utf-8"), "text/csv")},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["created_count"] == 3
    assert body["unmatched_count"] == 3
    assert body["suggested_count"] == 0
    assert body["error_rows"] == []

    # 모두 source=csv, source_ref="row:{n}".
    count = await db_session.scalar(
        select(func.count())
        .select_from(AcademyBankTransaction)
        .where(AcademyBankTransaction.academy_id == academy_id)
        .where(AcademyBankTransaction.source == AcademyBankTransactionSource.csv)
    )
    assert count == 3


# ---------------------------------------------------------------------------
# fuzzy 자동 실행 — invoice 와 매칭되면 suggested
# ---------------------------------------------------------------------------


async def test_csv_import_runs_fuzzy_and_counts_suggested(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원에 김지민 invoice 200,000 sent 상태 → CSV 행 매칭 → suggested 1, unmatched 2."""
    academy_id = await _setup_academy(
        client, db_session, create_test_user, with_invoice_for_student="김지민", invoice_amount=200_000
    )
    csv_body = (
        "거래일시,입금자명,금액\n"
        "2026-05-03,김지민 어머니,200000\n"  # 매칭 가능
        "2026-05-04,익명,99999\n"  # 미매칭
        "2026-05-05,무통장입금,12345\n"  # 미매칭
    )

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=_owner_headers(),
        files={"file": ("import.csv", csv_body.encode("utf-8"), "text/csv")},
    )
    body = resp.json()
    assert body["created_count"] == 3
    assert body["suggested_count"] == 1
    assert body["unmatched_count"] == 2

    # state 분포 확인.
    suggested = await db_session.scalar(
        select(func.count())
        .select_from(AcademyBankTransaction)
        .where(AcademyBankTransaction.academy_id == academy_id)
        .where(AcademyBankTransaction.state == AcademyBankTransactionState.suggested)
    )
    assert suggested == 1


# ---------------------------------------------------------------------------
# 부분 실패 — error_rows 분리, 정상 행 계속 처리
# ---------------------------------------------------------------------------


async def test_csv_import_reports_error_rows_but_imports_valid(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _setup_academy(client, db_session, create_test_user)
    csv_body = (
        "거래일시,입금자명,금액\n"
        "2026-05-03,김지민,200000\n"  # OK row:2
        "잘못된날짜,이지수,100000\n"  # FAIL row:3
        "2026-05-05,홍길동,180000\n"  # OK row:4
    )

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=_owner_headers(),
        files={"file": ("import.csv", csv_body.encode("utf-8"), "text/csv")},
    )
    body = resp.json()
    assert body["created_count"] == 2
    assert len(body["error_rows"]) == 1
    assert body["error_rows"][0]["row_number"] == 3
    assert "거래일시" in body["error_rows"][0]["reason"]


# ---------------------------------------------------------------------------
# 필수 헤더 누락 → 422
# ---------------------------------------------------------------------------


async def test_csv_import_missing_header_returns_422(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """필수 헤더(거래일시/입금자명/금액) 누락 → 422 (사용자 입력 검증)."""
    academy_id = await _setup_academy(client, db_session, create_test_user)
    csv_body = "거래일시,입금자명\n2026-05-03,김지민\n"  # 금액 헤더 없음

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=_owner_headers(),
        files={"file": ("bad.csv", csv_body.encode("utf-8"), "text/csv")},
    )
    assert resp.status_code == 422
    assert "필수 헤더" in resp.json()["detail"]


# ---------------------------------------------------------------------------
# BOM 처리
# ---------------------------------------------------------------------------


async def test_csv_import_handles_utf8_bom(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """Excel 으로 저장한 CSV 는 UTF-8 BOM 포함 — endpoint 가 처리해야 함."""
    academy_id = await _setup_academy(client, db_session, create_test_user)
    csv_body = "﻿거래일시,입금자명,금액\n2026-05-03,김지민,200000\n"

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=_owner_headers(),
        files={"file": ("excel.csv", csv_body.encode("utf-8-sig"), "text/csv")},
    )
    assert resp.status_code == 200
    assert resp.json()["created_count"] == 1


# ---------------------------------------------------------------------------
# 권한 — owner 만
# ---------------------------------------------------------------------------


async def test_csv_import_forbidden_for_non_owner(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _setup_academy(client, db_session, create_test_user)
    other_id = "other-user-id"
    await create_test_user(user_id=other_id, role="teacher", name="외부", email="other@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': other_id, 'role': 'teacher'})}"}
    csv_body = "거래일시,입금자명,금액\n2026-05-03,김지민,200000\n"

    resp = await client.post(
        f"/api/v1/academies/{academy_id}/billing/payments/matching/csv-import",
        headers=other_headers,
        files={"file": ("a.csv", csv_body.encode("utf-8"), "text/csv")},
    )
    assert resp.status_code == 403
