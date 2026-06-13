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


class MatchingInboxRowResponse(BaseModel):
    """§6.2 일괄 매칭 화면 1행 — tx + top-1 suggestion + invoice/학생 미리보기."""

    bank_transaction: AcademyBankTransactionResponse
    top_suggestion: AcademyPaymentMatchSuggestionResponse | None
    top_invoice_id: str | None
    top_invoice_total: int | None
    top_invoice_period: str | None  # "YYYY-MM"
    top_student_name: str | None


class MatchingInboxResponse(BaseModel):
    """§6.2 처리 대기 행 묶음 — state=unmatched/suggested 만."""

    rows: list[MatchingInboxRowResponse]
    total_count: int
    suggested_count: int
    unmatched_count: int


class AcademyMatchSplitItem(BaseModel):
    """§7.1 분할 매칭 1건 — 형제 invoice 별 분할 금액."""

    invoice_id: str = Field(..., description="매칭할 invoice id")
    paid_amount: int = Field(..., gt=0, description="이 invoice 에 분할 매칭할 금액")


class AcademyMatchSplitRequest(BaseModel):
    """§7.1 형제 합산 분할 매칭 (한 통장 입금 → 여러 invoice).

    학원장이 한 학부모의 형제 2~N명 동시 입금을 각 invoice 별로 분할.
    모든 결과 payment 는 같은 bank_tx_ref 공유 (분쟁 시 원천 추적).
    """

    splits: list[AcademyMatchSplitItem] = Field(..., min_length=1, description="분할 매칭 (invoice + 금액 1+ 건)")


class AcademyMatchSplitResponse(BaseModel):
    """§7.1 분할 매칭 결과 — 갱신된 tx + 생성된 payment 들."""

    bank_transaction: AcademyBankTransactionResponse
    payments: list[AcademyPaymentResponse]


class CsvImportErrorRow(BaseModel):
    """§5.1 CSV 임포트 시 파싱 실패한 1행."""

    row_number: int = Field(..., description="원본 CSV 행 번호 (헤더=1, 첫 데이터=2)")
    reason: str


class CsvImportResponse(BaseModel):
    """§5.1 CSV 일괄 임포트 결과 — 생성/매칭 카운트 + 실패 행 보고."""

    created_count: int = Field(..., description="새로 만들어진 AcademyBankTransaction 수")
    suggested_count: int = Field(..., description="fuzzy 알고리즘이 후보를 찾은 행 수 (state=suggested)")
    unmatched_count: int = Field(..., description="후보 0건으로 학원장 수동 매칭 대기 행 수 (state=unmatched)")
    error_rows: list[CsvImportErrorRow] = Field(
        default_factory=list,
        description="파싱 실패 행 — graceful: 정상 행은 계속 처리됨",
    )


__all__ = [
    "AcademyBankTransactionCreate",
    "AcademyBankTransactionListResponse",
    "AcademyBankTransactionResponse",
    "AcademyMatchConfirmRequest",
    "AcademyMatchConfirmResponse",
    "AcademyMatchSplitItem",
    "AcademyMatchSplitRequest",
    "AcademyMatchSplitResponse",
    "AcademyPaymentMatchSuggestionListResponse",
    "AcademyPaymentMatchSuggestionResponse",
    "BankTransactionSource",
    "BankTransactionState",
    "CsvImportErrorRow",
    "CsvImportResponse",
    "MatchingInboxResponse",
    "MatchingInboxRowResponse",
    "SuggestionDecision",
]
