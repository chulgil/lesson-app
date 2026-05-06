"""Drop PG (Payment Gateway) fields from payments + remap status enum

Revision ID: drop_pg_fields
Revises: add_sub_expiry_dispatch_log
Create Date: 2026-05-01 00:00:00.000000

흐름 A/A' (사용자↔사용자) 영구 PG 미채택 정책 확정 (2026-05-01).
- payment_architecture.md §1.2 + subscription_master.md §4.1.1
- 기존 Toss PG 코드(commit 6623f332) 전체 삭제 → 잔존 컬럼/enum 제거

변경:
- payments 테이블 6개 PG 컬럼 DROP (pg_provider/pg_transaction_id/pg_order_id/pg_payment_key/pg_response/pg_failure_reason)
- PaymentStatus enum: 'paid' → 'studentConfirmed' 로 재매핑 (spec subscription_master.md §4.2.1 정렬)
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "drop_pg_fields"
down_revision: str | None = "add_sub_expiry_dispatch_log"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()

    # 1) Drop 6 PG columns from payments
    existing_columns = {column["name"] for column in sa.inspect(bind).get_columns("payments")}
    for column_name in [
        "pg_failure_reason",
        "pg_response",
        "pg_payment_key",
        "pg_order_id",
        "pg_transaction_id",
        "pg_provider",
    ]:
        if column_name in existing_columns:
            op.drop_column("payments", column_name)

    # 2) Remap PaymentStatus enum: 'paid' → 'studentConfirmed'
    # PostgreSQL enum 변경은 ALTER TYPE 으로만 가능. 안전한 패턴:
    #   a. 새 enum 타입 생성
    #   b. 컬럼 → 새 타입으로 캐스팅 (paid → studentConfirmed)
    #   c. 옛 enum 타입 DROP, 새 타입 RENAME
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE paymentstatus RENAME TO paymentstatus_old")
        op.execute(
            "CREATE TYPE paymentstatus AS ENUM "
            "('pending', 'studentConfirmed', 'confirmed', 'overdue', 'cancelled', 'refunded')"
        )
        op.execute(
            "ALTER TABLE payments ALTER COLUMN status TYPE paymentstatus USING ("
            "CASE status::text "
            "WHEN 'paid' THEN 'studentConfirmed' "
            "ELSE status::text "
            "END)::paymentstatus"
        )
        op.execute("DROP TYPE paymentstatus_old")


def downgrade() -> None:
    bind = op.get_bind()

    # 1) Restore 'paid' enum (reverse studentConfirmed)
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE paymentstatus RENAME TO paymentstatus_new")
        op.execute("CREATE TYPE paymentstatus AS ENUM ('pending', 'paid', 'confirmed', 'overdue', 'cancelled', 'refunded')")
        op.execute(
            "ALTER TABLE payments ALTER COLUMN status TYPE paymentstatus USING ("
            "CASE status::text "
            "WHEN 'studentConfirmed' THEN 'paid' "
            "ELSE status::text "
            "END)::paymentstatus"
        )
        op.execute("DROP TYPE paymentstatus_new")

    # 2) Restore 6 PG columns
    op.add_column("payments", sa.Column("pg_provider", sa.String(length=50), nullable=True))
    op.add_column("payments", sa.Column("pg_transaction_id", sa.String(length=200), nullable=True))
    op.add_column("payments", sa.Column("pg_order_id", sa.String(length=200), nullable=True))
    op.add_column("payments", sa.Column("pg_payment_key", sa.String(length=200), nullable=True))
    op.add_column("payments", sa.Column("pg_response", sa.JSON(), nullable=True))
    op.add_column("payments", sa.Column("pg_failure_reason", sa.Text(), nullable=True))
