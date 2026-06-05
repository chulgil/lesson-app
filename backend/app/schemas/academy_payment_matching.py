"""Academy payment matching API schemas — AC-M3 §4 수기 입력 + 1탭 확정.

Spec: docs/specs/web/academy/payment_matching_spec.md §5.2, §6.3, §7.6.
"""

from __future__ import annotations

import datetime as _dt
import enum

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.academy_billing import AcademyPaymentResponse


class BankTransactionSource(str, enum.Enum):
    csv = "csv"
    manual = "manual"
    ocr = "ocr"


class BankTransactionState(str, enum.Enum):
    unmatched = "unmatched"
    suggested = "suggested"
    matched = "matched"
    ignored = "ignored"


class AcademyBankTransactionCreate(BaseModel):
    """수기 입력 (§5.2). 통장에서 본 입금 1건을 학원장이 직접 입력."""

    depositor_raw: str = Field(..., max_length=200, description="통장 원문 입금자명 (예: '김지민 어머니')")
    amount: int = Field(..., gt=0, description="입금 금액 (원)")
    tx_at: _dt.datetime = Field(..., description="통장 기록 시각")
    memo_raw: str | None = Field(None, max_length=200, description="통장 메모 (예: '0418지민')")
    bank_name: str | None = Field(None, max_length=50, description="은행명 (KB / 신한 / 카뱅 등)")
    source_ref: str | None = Field(None, max_length=255, description="CSV 행번호 / OCR 캡처 ID (선택)")


class AcademyBankTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    academy_id: str
    source: BankTransactionSource
    source_ref: str | None
    bank_name: str | None
    tx_at: _dt.datetime
    amount: int
    depositor_raw: str
    memo_raw: str | None
    matched_invoice_id: str | None
    matched_at: _dt.datetime | None
    matched_by_user_id: str | None
    match_score: float | None
    state: BankTransactionState


class AcademyBankTransactionListResponse(BaseModel):
    transactions: list[AcademyBankTransactionResponse]
    total_count: int


class AcademyMatchConfirmRequest(BaseModel):
    """1탭 매칭 확정 (§6.3). 학원장이 후보 중 1개를 선택."""

    invoice_id: str = Field(..., description="매칭할 invoice id")
    paid_amount: int = Field(..., gt=0, description="실제 입금 금액 (부분 매칭 시 < total_amount 허용)")


class AcademyMatchConfirmResponse(BaseModel):
    """매칭 확정 결과 — 갱신된 tx + 생성된 payment."""

    bank_transaction: AcademyBankTransactionResponse
    payment: AcademyPaymentResponse


class SuggestionDecision(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class AcademyPaymentMatchSuggestionResponse(BaseModel):
    """§3 알고리즘이 제안한 1탭 매칭 후보."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    bank_transaction_id: str
    invoice_id: str
    score: float
    features: dict | None
    suggested_at: _dt.datetime
    user_decision: SuggestionDecision
    decided_at: _dt.datetime | None


class AcademyPaymentMatchSuggestionListResponse(BaseModel):
    suggestions: list[AcademyPaymentMatchSuggestionResponse]
    total_count: int


__all__ = [
    "AcademyBankTransactionCreate",
    "AcademyBankTransactionListResponse",
    "AcademyBankTransactionResponse",
    "AcademyMatchConfirmRequest",
    "AcademyMatchConfirmResponse",
    "AcademyPaymentMatchSuggestionListResponse",
    "AcademyPaymentMatchSuggestionResponse",
    "BankTransactionSource",
    "BankTransactionState",
    "SuggestionDecision",
]
