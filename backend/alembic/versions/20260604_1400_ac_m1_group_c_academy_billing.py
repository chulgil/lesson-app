"""ac_m1_group_c_academy_billing

AC-M1 그룹 C — 수강권/청구/수금/정산 5 테이블 + 6 enum + subscriptions.academy_id.

Spec: docs/specs/web/academy/billing_settlement_spec.md (전체)

테이블:
- academy_billing_rules (학원 단위 청구·배분 규칙)
- academy_teacher_payout_overrides (강사별 모드 override)
- academy_invoices (월간 학생 청구서)
- academy_payments (수금 1건, 부분 수금 지원)
- academy_settlements (월간 강사 배분 명세)
- subscriptions.academy_id 컬럼 추가 (academy_subscriptions 신규 테이블 만들지 않음)

Enums:
- teacherdistributiontype: hourly / revenue_share / per_student
- settlementbase: attendance / invoiced / completed_invoice
- invoicestatus: draft / sent / paid / overdue / cancelled
- academypaymentmethod: transfer / cash / card (구독 도메인 paymentmethod 와 충돌 방지)
- paymentsource: manual / csv_import / fuzzy_match
- settlementstatus: draft / confirmed / transferred

Policy:
- 자동 결제/송금 X — 모든 수금/송금은 학원장 수기 마킹
- /payments/* 라우터 신규 금지 (backend_spec §결제 경계 정책)
- audit trail 영구 보존 (강사 서명·이의 + 학원장 수정 이력)

Revision ID: ac_m1_group_c_billing
Revises: ac_m1_group_b_governance
Create Date: 2026-06-04 14:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql  # noqa: F401  (used in upgrade() enum defs)

from alembic import op

revision: str = "ac_m1_group_c_billing"
down_revision: str | None = "ac_m1_group_b_governance"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Enums.
    # create_type=False: 명시적 .create() 한 번만 생성하고 create_table 재발행 방지.
    # paymentmethod 는 구독 도메인 enum 과 충돌하므로 academypaymentmethod 로 격리.
    teacher_distribution_type = postgresql.ENUM(
        "hourly", "revenue_share", "per_student", name="teacherdistributiontype", create_type=False
    )
    settlement_base = postgresql.ENUM(
        "attendance", "invoiced", "completed_invoice", name="settlementbase", create_type=False
    )
    invoice_status = postgresql.ENUM(
        "draft", "sent", "paid", "overdue", "cancelled", name="invoicestatus", create_type=False
    )
    payment_method = postgresql.ENUM("transfer", "cash", "card", name="academypaymentmethod", create_type=False)
    payment_source = postgresql.ENUM("manual", "csv_import", "fuzzy_match", name="paymentsource", create_type=False)
    settlement_status = postgresql.ENUM("draft", "confirmed", "transferred", name="settlementstatus", create_type=False)
    subscription_ownership = postgresql.ENUM("academy", "teacher", name="subscriptionownership", create_type=False)
    lesson_visibility = postgresql.ENUM("academyFull", "academyBusyOnly", name="lessonvisibility", create_type=False)
    bind = op.get_bind()
    for e in (
        teacher_distribution_type,
        settlement_base,
        invoice_status,
        payment_method,
        payment_source,
        settlement_status,
        subscription_ownership,
        lesson_visibility,
    ):
        e.create(bind, checkfirst=True)

    # academy_billing_rules
    op.create_table(
        "academy_billing_rules",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("invoice_issue_day", sa.Integer(), nullable=False, server_default="25"),
        sa.Column("payment_due_days", sa.Integer(), nullable=False, server_default="7"),
        sa.Column("payment_methods", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("bank_account_name", sa.String(100), nullable=True),
        sa.Column("bank_account_number", sa.String(50), nullable=True),
        sa.Column(
            "teacher_distribution_type",
            teacher_distribution_type,
            nullable=False,
            server_default="revenue_share",
        ),
        sa.Column(
            "teacher_distribution_config",
            sa.JSON(),
            nullable=False,
            server_default=sa.text("'{}'"),
        ),
        sa.Column("settlement_base", settlement_base, nullable=False, server_default="attendance"),
        sa.Column("tax_invoice_enabled", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("cash_receipt_enabled", sa.Integer(), nullable=False, server_default="1"),
        sa.Column(
            "absent_teacher_pay_pct",
            sa.Float(),
            nullable=False,
            server_default="0.4",
        ),
        sa.Column("substitute_pay_pct", sa.Float(), nullable=False, server_default="0.6"),
        sa.Column("no_show_penalty_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("no_show_penalty_strikes", sa.Integer(), nullable=False, server_default="3"),
        sa.CheckConstraint("invoice_issue_day BETWEEN 1 AND 28", name="ck_billing_rule_issue_day"),
        sa.CheckConstraint("payment_due_days BETWEEN 0 AND 60", name="ck_billing_rule_due_days"),
        sa.CheckConstraint(
            "absent_teacher_pay_pct >= 0 AND absent_teacher_pay_pct <= 1",
            name="ck_billing_rule_absent_pct",
        ),
        sa.CheckConstraint(
            "substitute_pay_pct >= 0 AND substitute_pay_pct <= 1",
            name="ck_billing_rule_sub_pct",
        ),
    )

    # academy_teacher_payout_overrides
    op.create_table(
        "academy_teacher_payout_overrides",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "teacher_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("distribution_type", teacher_distribution_type, nullable=False),
        sa.Column(
            "distribution_config",
            sa.JSON(),
            nullable=False,
            server_default=sa.text("'{}'"),
        ),
        sa.Column("effective_from", sa.Date(), nullable=False),
        sa.Column("effective_until", sa.Date(), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
    )
    op.create_index(
        "idx_payout_override_teacher_effective",
        "academy_teacher_payout_overrides",
        ["teacher_member_id", "effective_from"],
    )
    op.create_index("idx_payout_override_academy", "academy_teacher_payout_overrides", ["academy_id"])

    # academy_invoices
    op.create_table(
        "academy_invoices",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "academy_student_id",
            sa.String(36),
            sa.ForeignKey("academy_students.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("period_year", sa.Integer(), nullable=False),
        sa.Column("period_month", sa.Integer(), nullable=False),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("base_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("extra_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("discount_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("status", invoice_status, nullable=False, server_default="draft"),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("pdf_url", sa.String(500), nullable=True),
        sa.Column("line_items", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("tax_invoice_issued", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("cash_receipt_issued", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("cash_receipt_issued_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("cash_receipt_ref", sa.String(100), nullable=True),
        sa.Column("cash_receipt_target_no", sa.String(50), nullable=True),
        sa.CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_invoice_period_month"),
        sa.CheckConstraint("total_amount >= 0", name="ck_invoice_total_amount"),
    )
    op.create_index(
        "idx_academy_invoice_unique_period",
        "academy_invoices",
        ["academy_id", "academy_student_id", "period_year", "period_month"],
        unique=True,
    )
    op.create_index("idx_academy_invoice_academy_status", "academy_invoices", ["academy_id", "status"])
    op.create_index("idx_academy_invoice_due_date", "academy_invoices", ["due_date"])

    # academy_payments
    op.create_table(
        "academy_payments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "invoice_id",
            sa.String(36),
            sa.ForeignKey("academy_invoices.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("paid_amount", sa.Integer(), nullable=False),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("method", payment_method, nullable=False, server_default="transfer"),
        sa.Column(
            "confirmed_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("source", payment_source, nullable=False, server_default="manual"),
        sa.Column("bank_tx_ref", sa.String(100), nullable=True),
        sa.Column("depositor_raw", sa.String(200), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.CheckConstraint("paid_amount > 0", name="ck_payment_paid_amount"),
    )
    op.create_index("idx_academy_payment_invoice", "academy_payments", ["invoice_id"])
    op.create_index("idx_academy_payment_academy_paid_at", "academy_payments", ["academy_id", "paid_at"])

    # academy_settlements
    op.create_table(
        "academy_settlements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "teacher_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("period_year", sa.Integer(), nullable=False),
        sa.Column("period_month", sa.Integer(), nullable=False),
        sa.Column("calculated_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("adjusted_amount", sa.Integer(), nullable=True),
        sa.Column("final_amount", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("status", settlement_status, nullable=False, server_default="draft"),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("transferred_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("pdf_url", sa.String(500), nullable=True),
        sa.Column("breakdown", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("teacher_acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("teacher_dispute_note", sa.Text(), nullable=True),
        sa.Column("adjustment_log", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
        sa.Column("note", sa.Text(), nullable=True),
        sa.CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_settlement_period_month"),
        sa.CheckConstraint("calculated_amount >= 0", name="ck_settlement_calculated_amount"),
        sa.CheckConstraint("final_amount >= 0", name="ck_settlement_final_amount"),
    )
    op.create_index(
        "idx_academy_settlement_unique_period",
        "academy_settlements",
        ["academy_id", "teacher_member_id", "period_year", "period_month"],
        unique=True,
    )
    op.create_index(
        "idx_academy_settlement_academy_period",
        "academy_settlements",
        ["academy_id", "period_year", "period_month"],
    )

    # academy_subscriptions — 학원 귀속 수강권 정책 (spec §2.2).
    op.create_table(
        "academy_subscriptions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "academy_id",
            sa.String(36),
            sa.ForeignKey("academies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "subscription_id",
            sa.String(36),
            sa.ForeignKey("subscriptions.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column(
            "academy_student_id",
            sa.String(36),
            sa.ForeignKey("academy_students.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "teacher_member_id",
            sa.String(36),
            sa.ForeignKey("academy_members.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("ownership", subscription_ownership, nullable=False, server_default="academy"),
        sa.Column("cancellation_deadline_hours", sa.Integer(), nullable=False, server_default="12"),
        sa.Column(
            "student_compensation_extra_minutes_enabled",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),
        sa.Column(
            "include_extra_minutes_text_on_late_cancel",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),
        sa.Column("student_compensation_extra_minutes_message", sa.String(500), nullable=True),
        sa.Column("notify_owner_on_late_cancel", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_by_user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.CheckConstraint(
            "cancellation_deadline_hours >= 0 AND cancellation_deadline_hours <= 168",
            name="ck_academy_subscription_deadline_hours",
        ),
    )
    op.create_index("idx_academy_subscription_academy", "academy_subscriptions", ["academy_id"])
    op.create_index("idx_academy_subscription_student", "academy_subscriptions", ["academy_student_id"])
    op.create_index("idx_academy_subscription_teacher", "academy_subscriptions", ["teacher_member_id"])

    # subscriptions.academy_id 컬럼 추가 (빠른 조회 denormalization).
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.add_column(
            sa.Column(
                "academy_id",
                sa.String(36),
                sa.ForeignKey("academies.id", ondelete="SET NULL"),
                nullable=True,
            )
        )
    op.create_index("idx_subscriptions_academy", "subscriptions", ["academy_id"])

    # lessons.academy_id + visibility 컬럼 추가 (academy_schedule_authority §2.3).
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.add_column(
            sa.Column(
                "academy_id",
                sa.String(36),
                sa.ForeignKey("academies.id", ondelete="SET NULL"),
                nullable=True,
            )
        )
        batch_op.add_column(
            sa.Column(
                "visibility",
                lesson_visibility,
                nullable=False,
                server_default="academyFull",
            )
        )
    op.create_index("idx_lesson_academy", "lessons", ["academy_id"])


def downgrade() -> None:
    op.drop_index("idx_lesson_academy", table_name="lessons")
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.drop_column("visibility")
        batch_op.drop_column("academy_id")

    op.drop_index("idx_subscriptions_academy", table_name="subscriptions")
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.drop_column("academy_id")

    op.drop_index("idx_academy_subscription_teacher", table_name="academy_subscriptions")
    op.drop_index("idx_academy_subscription_student", table_name="academy_subscriptions")
    op.drop_index("idx_academy_subscription_academy", table_name="academy_subscriptions")
    op.drop_table("academy_subscriptions")

    op.drop_index("idx_academy_settlement_academy_period", table_name="academy_settlements")
    op.drop_index("idx_academy_settlement_unique_period", table_name="academy_settlements")
    op.drop_table("academy_settlements")

    op.drop_index("idx_academy_payment_academy_paid_at", table_name="academy_payments")
    op.drop_index("idx_academy_payment_invoice", table_name="academy_payments")
    op.drop_table("academy_payments")

    op.drop_index("idx_academy_invoice_due_date", table_name="academy_invoices")
    op.drop_index("idx_academy_invoice_academy_status", table_name="academy_invoices")
    op.drop_index("idx_academy_invoice_unique_period", table_name="academy_invoices")
    op.drop_table("academy_invoices")

    op.drop_index("idx_payout_override_academy", table_name="academy_teacher_payout_overrides")
    op.drop_index("idx_payout_override_teacher_effective", table_name="academy_teacher_payout_overrides")
    op.drop_table("academy_teacher_payout_overrides")

    op.drop_table("academy_billing_rules")

    bind = op.get_bind()
    for name in (
        "lessonvisibility",
        "subscriptionownership",
        "settlementstatus",
        "paymentsource",
        "academypaymentmethod",
        "invoicestatus",
        "settlementbase",
        "teacherdistributiontype",
    ):
        sa.Enum(name=name).drop(bind, checkfirst=True)
