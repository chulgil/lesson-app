"""Add app billing and IAP receipt tables

Revision ID: f2e8c3d9b1a2
Revises: add_share_token
Create Date: 2026-05-28 11:00:00.000000+00:00

Spec: #405 (default-deny IAP guard) + #406 (FK + unique constraint hygiene)

Tables:
- app_billing_plans — one-plan-per-user (UNIQUE on user_id)
- iap_receipts — audit trail; (platform, transaction_id) UNIQUE to block replays

Both user_id columns are FKs to users.id ON DELETE CASCADE so billing rows
are cleaned up when an account is deleted.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f2e8c3d9b1a2"
down_revision: str | None = "add_share_token"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "app_billing_plans",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("tier", sa.Enum("free", "pro", "studio", name="billingtier", native_enum=True), nullable=False),
        sa.Column(
            "status",
            sa.Enum("active", "trial", "expired", "cancelled", name="billingplanstatus", native_enum=True),
            nullable=False,
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source", sa.String(length=50), nullable=False, server_default="admin_grant"),
        sa.Column("original_transaction_id", sa.String(length=255), nullable=True),
        sa.Column("trial_used", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_app_billing_plans_user_id_users",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint("user_id", name="uq_app_billing_plans_user_id"),
    )
    op.create_index("idx_app_billing_expires", "app_billing_plans", ["expires_at"])
    op.create_index("idx_app_billing_status", "app_billing_plans", ["status"])

    op.create_table(
        "iap_receipts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("platform", sa.Enum("apple", "google", name="iapplatform", native_enum=True), nullable=False),
        sa.Column("raw_receipt", sa.Text(), nullable=False),
        sa.Column("transaction_id", sa.String(length=255), nullable=False),
        sa.Column("product_id", sa.String(length=255), nullable=False),
        sa.Column(
            "status",
            sa.Enum(
                "pending_verification",
                "verified",
                "invalid",
                "expired",
                name="iapreceiptstatus",
                native_enum=True,
            ),
            nullable=False,
            server_default="pending_verification",
        ),
        sa.Column("validated_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_iap_receipts_user_id_users",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint(
            "platform",
            "transaction_id",
            name="uq_iap_receipts_platform_transaction",
        ),
    )
    op.create_index("idx_iap_receipt_user", "iap_receipts", ["user_id"])
    op.create_index("idx_iap_receipt_platform", "iap_receipts", ["platform"])
    op.create_index("idx_iap_receipt_transaction", "iap_receipts", ["transaction_id"])
    op.create_index("idx_iap_receipt_status", "iap_receipts", ["status"])


def downgrade() -> None:
    op.drop_index("idx_iap_receipt_status", table_name="iap_receipts")
    op.drop_index("idx_iap_receipt_transaction", table_name="iap_receipts")
    op.drop_index("idx_iap_receipt_platform", table_name="iap_receipts")
    op.drop_index("idx_iap_receipt_user", table_name="iap_receipts")
    op.drop_table("iap_receipts")

    op.drop_index("idx_app_billing_status", table_name="app_billing_plans")
    op.drop_index("idx_app_billing_expires", table_name="app_billing_plans")
    op.drop_table("app_billing_plans")

    # PostgreSQL native enum types persist after drop_table; explicit drop required.
    # NO-OP on SQLite (test DB) and MySQL — types are inline there.
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("DROP TYPE IF EXISTS iapreceiptstatus")
        op.execute("DROP TYPE IF EXISTS iapplatform")
        op.execute("DROP TYPE IF EXISTS billingplanstatus")
        op.execute("DROP TYPE IF EXISTS billingtier")
