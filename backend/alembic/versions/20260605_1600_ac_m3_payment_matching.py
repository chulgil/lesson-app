"""ac_m3_payment_matching

AC-M3 — 무통장입금 fuzzy 매칭 BE 데이터 모델.

Spec: docs/specs/web/academy/payment_matching_spec.md §2.

테이블:
- academy_bank_transactions: 학원장이 입력한 입금 원문 (1 통장 거래 = 1 행)
- academy_payment_match_suggestions: 알고리즘 제안 후보 (1 tx × N 후보)

Enums:
- academybanktransactionsource: csv / manual / ocr
- academybanktransactionstate: unmatched / suggested / matched / ignored
- academypaymentmatchsuggestiondecision: pending / accepted / rejected

Policy:
- 앱은 송금/결제를 수행하지 않는다 (PG/오픈뱅킹 자동 결제 금지)
- 자동 매칭 금지 — 알고리즘은 제안만, 확정은 학원장 1탭
- depositor_raw / memo_raw 원문 영구 보존 (분쟁 증거)
- UNIQUE (bank_transaction_id, invoice_id) — 같은 후보 중복 제안 방지

Revision ID: ac_m3_payment_matching
Revises: phone_verification_codes
Create Date: 2026-06-05 16:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql  # noqa: F401  (used in upgrade() enum defs)

from alembic import op

revision: str = "ac_m3_payment_matching"
down_revision: str | None = "phone_verification_codes"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enums.
    # create_type=False: 명시적 .create() 한 번만 생성, create_table 재발행 방지.
    source_enum = postgresql.ENUM("csv", "manual", "ocr", name="academybanktransactionsource", create_type=False)
    state_enum = postgresql.ENUM(
        "unmatched",
        "suggested",
        "matched",
        "ignored",
        name="academybanktransactionstate",
        create_type=False,
    )
    decision_enum = postgresql.ENUM(
        "pending",
        "accepted",
        "rejected",
        name="academypaymentmatchsuggestiondecision",
        create_type=False,
    )
    bind = op.get_bind()
    source_enum.create(bind, checkfirst=True)
    state_enum.create(bind, checkfirst=True)
    decision_enum.create(bind, checkfirst=True)

    # academy_bank_transactions
    op.create_table(
        "academy_bank_transactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source", source_enum, nullable=False),
        sa.Column("source_ref", sa.String(255), nullable=True),
        sa.Column("bank_name", sa.String(50), nullable=True),
        sa.Column("tx_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("depositor_raw", sa.String(200), nullable=False),
        sa.Column("memo_raw", sa.String(200), nullable=True),
        sa.Column(
            "matched_invoice_id",
            sa.String(36),
            sa.ForeignKey("academy_invoices.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("matched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "matched_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("match_score", sa.Float(), nullable=True),
        sa.Column("match_features", sa.JSON(), nullable=True),
        sa.Column("state", state_enum, nullable=False, server_default="unmatched"),
    )
    op.create_index(
        "idx_acad_bank_tx_academy_state",
        "academy_bank_transactions",
        ["academy_id", "state"],
    )
    op.create_index(
        "idx_acad_bank_tx_unmatched_at",
        "academy_bank_transactions",
        ["academy_id", "state", "tx_at"],
    )
    op.create_index(
        "idx_acad_bank_tx_matched_invoice",
        "academy_bank_transactions",
        ["matched_invoice_id"],
    )

    # academy_payment_match_suggestions
    op.create_table(
        "academy_payment_match_suggestions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "bank_transaction_id",
            sa.String(36),
            sa.ForeignKey("academy_bank_transactions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "invoice_id",
            sa.String(36),
            sa.ForeignKey("academy_invoices.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("features", sa.JSON(), nullable=True),
        sa.Column("suggested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "user_decision",
            decision_enum,
            nullable=False,
            server_default="pending",
        ),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "idx_acad_match_sugg_tx_score",
        "academy_payment_match_suggestions",
        ["bank_transaction_id", "score"],
    )
    op.create_index(
        "idx_acad_match_sugg_invoice",
        "academy_payment_match_suggestions",
        ["invoice_id"],
    )
    op.create_index(
        "uq_acad_match_sugg_per_pair",
        "academy_payment_match_suggestions",
        ["bank_transaction_id", "invoice_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uq_acad_match_sugg_per_pair", table_name="academy_payment_match_suggestions")
    op.drop_index("idx_acad_match_sugg_invoice", table_name="academy_payment_match_suggestions")
    op.drop_index("idx_acad_match_sugg_tx_score", table_name="academy_payment_match_suggestions")
    op.drop_table("academy_payment_match_suggestions")

    op.drop_index("idx_acad_bank_tx_matched_invoice", table_name="academy_bank_transactions")
    op.drop_index("idx_acad_bank_tx_unmatched_at", table_name="academy_bank_transactions")
    op.drop_index("idx_acad_bank_tx_academy_state", table_name="academy_bank_transactions")
    op.drop_table("academy_bank_transactions")

    sa.Enum(name="academypaymentmatchsuggestiondecision").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="academybanktransactionstate").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="academybanktransactionsource").drop(op.get_bind(), checkfirst=True)
