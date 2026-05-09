"""Add app_billing_plans and app_billing_receipts tables for IAP (R4).

Revision ID: add_app_billing_tables
Revises: add_app_version_tables
Create Date: 2026-05-10 18:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_app_billing_tables"
down_revision: str | None = "add_app_version_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "app_billing_plans",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("plan", sa.String(length=20), nullable=False, server_default="free"),
        sa.Column("store_platform", sa.String(length=20), nullable=True),
        sa.Column("original_transaction_id", sa.String(length=100), nullable=True),
        sa.Column("trial_ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("cancelled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"]),
    )
    op.create_index("idx_billing_plans_teacher", "app_billing_plans", ["teacher_id"])

    op.create_table(
        "app_billing_receipts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("billing_plan_id", sa.String(length=36), nullable=False),
        sa.Column("store_platform", sa.String(length=20), nullable=False),
        sa.Column("transaction_id", sa.String(length=100), nullable=False),
        sa.Column("product_id", sa.String(length=50), nullable=False),
        sa.Column("receipt_data", sa.Text(), nullable=False),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "verification_status",
            sa.String(length=20),
            nullable=False,
            server_default="pending",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["billing_plan_id"], ["app_billing_plans.id"]),
    )
    op.create_index(
        "idx_billing_receipts_plan", "app_billing_receipts", ["billing_plan_id"]
    )


def downgrade() -> None:
    op.drop_index("idx_billing_receipts_plan", table_name="app_billing_receipts")
    op.drop_table("app_billing_receipts")
    op.drop_index("idx_billing_plans_teacher", table_name="app_billing_plans")
    op.drop_table("app_billing_plans")
