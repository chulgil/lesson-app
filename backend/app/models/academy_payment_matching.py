"""Academy payment matching persistence models — AC-M3.

Spec: docs/specs/web/academy/payment_matching_spec.md §2.

학원장이 입력한 무통장입금 원문(통장 거래) + 알고리즘 매칭 후보를 영속화.
원칙:
- 앱은 송금/결제를 수행하지 않는다 (PG/오픈뱅킹 자동 결제 금지).
- 자동 매칭 금지 — 알고리즘은 제안만, 확정은 학원장 1탭.
- 원문(depositor_raw / memo_raw) + 매칭 점수 + features 영구 보존 (분쟁 증거).
"""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import (
    JSON,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class AcademyBankTransactionSource(str, enum.Enum):
    """입금 데이터 입력 경로."""

    csv = "csv"
    manual = "manual"
    ocr = "ocr"


class AcademyBankTransactionState(str, enum.Enum):
    """매칭 상태 — 알고리즘이 제안하고 학원장이 확정."""

    unmatched = "unmatched"
    suggested = "suggested"
    matched = "matched"
    ignored = "ignored"


class AcademyPaymentMatchSuggestionDecision(str, enum.Enum):
    """학원장의 후보별 결정."""

    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class AcademyBankTransaction(UUIDMixin, TimestampMixin, Base):
    """학원장이 입력한 입금 원문 (1 통장 거래 = 1 행). 매칭 전후 보존.

    - depositor_raw / memo_raw: 통장 원문 (예: ``"김지민 어머니"``, ``"0418지민"``).
      정규화는 매칭 비교 시점에만 적용 — 원문은 영구 보존 (분쟁 증거).
    - match_score: 알고리즘 가중 합 (0.0-1.0). 임계치 0.85+ 강한 제안, 0.60+ 약한 제안.
    - match_features: 각 신호(금액/이름/가족호칭/메모코드/시각) 점수 JSON.
    """

    __tablename__ = "academy_bank_transactions"

    academy_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    source: Mapped[AcademyBankTransactionSource] = mapped_column(
        Enum(AcademyBankTransactionSource, native_enum=True),
        nullable=False,
    )
    source_ref: Mapped[str | None] = mapped_column(String(255), nullable=True)
    bank_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    tx_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    depositor_raw: Mapped[str] = mapped_column(String(200), nullable=False)
    memo_raw: Mapped[str | None] = mapped_column(String(200), nullable=True)
    matched_invoice_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("academy_invoices.id", ondelete="SET NULL"),
        nullable=True,
    )
    matched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    matched_by_user_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    match_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    match_features: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    state: Mapped[AcademyBankTransactionState] = mapped_column(
        Enum(AcademyBankTransactionState, native_enum=True),
        nullable=False,
        default=AcademyBankTransactionState.unmatched,
    )

    __table_args__ = (
        Index("idx_acad_bank_tx_academy_state", "academy_id", "state"),
        Index(
            "idx_acad_bank_tx_unmatched_at",
            "academy_id",
            "state",
            "tx_at",
        ),
        Index("idx_acad_bank_tx_matched_invoice", "matched_invoice_id"),
    )


class AcademyPaymentMatchSuggestion(UUIDMixin, Base):
    """알고리즘이 학원장에게 제안하는 매칭 후보 (1 tx × N 후보).

    학원장 결정 (accepted/rejected) 이력 영구 보존 — 분쟁 시 "왜 그 인보이스로
    매칭했는지" 추적용. accepted 결정 시 ``AcademyBankTransaction.matched_*``
    필드 갱신은 별도 서비스 책임.
    """

    __tablename__ = "academy_payment_match_suggestions"

    bank_transaction_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_bank_transactions.id", ondelete="CASCADE"),
        nullable=False,
    )
    invoice_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("academy_invoices.id", ondelete="CASCADE"),
        nullable=False,
    )
    score: Mapped[float] = mapped_column(Float, nullable=False)
    features: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    suggested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    user_decision: Mapped[AcademyPaymentMatchSuggestionDecision] = mapped_column(
        Enum(AcademyPaymentMatchSuggestionDecision, native_enum=True),
        nullable=False,
        default=AcademyPaymentMatchSuggestionDecision.pending,
    )
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("idx_acad_match_sugg_tx_score", "bank_transaction_id", "score"),
        Index("idx_acad_match_sugg_invoice", "invoice_id"),
        Index(
            "uq_acad_match_sugg_per_pair",
            "bank_transaction_id",
            "invoice_id",
            unique=True,
        ),
    )


__all__ = [
    "AcademyBankTransaction",
    "AcademyBankTransactionSource",
    "AcademyBankTransactionState",
    "AcademyPaymentMatchSuggestion",
    "AcademyPaymentMatchSuggestionDecision",
]
