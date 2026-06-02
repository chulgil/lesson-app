"""drop_students_connection_status

G3 D-G3 Phase B-2b — `students.connection_status` 컬럼 + `idx_students_connection`
인덱스 + ConnectionStatus PG enum 타입 제거.

Phase B-1 (#456): dead resolver 제거 + FE @Deprecated 마킹
Phase B-2a (#457): BE writer 제거 + FE isAppConnected → connectedAt SSOT 전환
Phase B-2b (본 마이그레이션): 컬럼 + 인덱스 + enum 타입 drop

`connected_at` 와 `TeacherStudentRelation.status` 가 canonical 신호로 자리잡았으므로
컬럼 데이터는 더 이상 read 되지 않는다 (Phase B-2a 의 invite_service 변경 이후).

Revision ID: drop_students_connection_status
Revises: user_consent_fields
Create Date: 2026-06-02 13:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "drop_students_connection_status"
down_revision: str | None = "user_consent_fields"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _indexes(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {index["name"] for index in inspector.get_indexes(table_name)}


def _drop_enum_type(bind: sa.engine.Connection, name: str) -> None:
    """Drop a PG enum type if it exists. No-op on SQLite (which inlines enums)."""
    if bind.dialect.name != "postgresql":
        return
    bind.execute(sa.text(f'DROP TYPE IF EXISTS "{name}"'))


def upgrade() -> None:
    bind = op.get_bind()
    existing_indexes = _indexes("students")
    if "idx_students_connection" in existing_indexes:
        op.drop_index("idx_students_connection", table_name="students")

    existing_columns = _columns("students")
    if "connection_status" in existing_columns:
        op.drop_column("students", "connection_status")

    _drop_enum_type(bind, "connectionstatus")


def downgrade() -> None:
    bind = op.get_bind()
    existing_columns = _columns("students")
    if "connection_status" not in existing_columns:
        if bind.dialect.name == "postgresql":
            # Recreate the enum type with the original 5 values.
            bind.execute(
                sa.text(
                    "CREATE TYPE connectionstatus AS ENUM "
                    "('offline','inviteSent','inviteReceived','connected','disconnected')"
                )
            )
            op.add_column(
                "students",
                sa.Column(
                    "connection_status",
                    sa.Enum(
                        "offline",
                        "inviteSent",
                        "inviteReceived",
                        "connected",
                        "disconnected",
                        name="connectionstatus",
                    ),
                    nullable=False,
                    server_default="offline",
                ),
            )
        else:
            op.add_column(
                "students",
                sa.Column(
                    "connection_status",
                    sa.String(length=20),
                    nullable=False,
                    server_default="offline",
                ),
            )

    existing_indexes = _indexes("students")
    if "idx_students_connection" not in existing_indexes:
        op.create_index(
            "idx_students_connection",
            "students",
            ["connection_status"],
        )
