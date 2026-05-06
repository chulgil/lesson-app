"""Normalize teaching resource tags.

Revision ID: normalize_teaching_resource_tags
Revises: add_feedback_template_tables
Create Date: 2026-05-07 01:00:00.000000
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "normalize_teaching_resource_tags"
down_revision: str | None = "add_feedback_template_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_column(table_name: str, column_name: str) -> bool:
    bind = op.get_bind()
    columns = sa.inspect(bind).get_columns(table_name)
    return any(column["name"] == column_name for column in columns)


def upgrade() -> None:
    op.create_table(
        "teaching_resource_tags",
        sa.Column("resource_id", sa.String(length=36), nullable=False),
        sa.Column("tag", sa.String(length=80), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.ForeignKeyConstraint(
            ["resource_id"],
            ["teaching_resources.id"],
            name="fk_teaching_resource_tags_resource_id_teaching_resources",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "uk_teaching_resource_tag",
        "teaching_resource_tags",
        ["resource_id", "tag"],
        unique=True,
    )
    op.create_index(
        "idx_teaching_resource_tag_tag",
        "teaching_resource_tags",
        ["tag"],
        unique=False,
    )

    bind = op.get_bind()
    if bind.dialect.name == "postgresql" and _has_column("teaching_resources", "tags"):
        op.execute(
            sa.text(
                """
                INSERT INTO teaching_resource_tags (id, resource_id, tag)
                SELECT
                    md5(resource_id || ':' || tag),
                    resource_id,
                    tag
                FROM (
                    SELECT DISTINCT
                        tr.id AS resource_id,
                        NULLIF(BTRIM(value), '') AS tag
                    FROM teaching_resources tr
                    CROSS JOIN LATERAL jsonb_array_elements_text(
                        CASE
                            WHEN tr.tags IS NULL THEN '[]'::jsonb
                            ELSE tr.tags::jsonb
                        END
                    ) AS value
                ) normalized
                WHERE tag IS NOT NULL
                ON CONFLICT DO NOTHING
                """
            )
        )

    if _has_column("teaching_resources", "tags"):
        op.drop_column("teaching_resources", "tags")


def downgrade() -> None:
    bind = op.get_bind()
    if not _has_column("teaching_resources", "tags"):
        op.add_column("teaching_resources", sa.Column("tags", sa.JSON(), nullable=True))

    if bind.dialect.name == "postgresql":
        op.execute(
            sa.text(
                """
                UPDATE teaching_resources tr
                SET tags = COALESCE(tag_rows.tags, '[]'::jsonb)::json
                FROM (
                    SELECT
                        resource_id,
                        jsonb_agg(tag ORDER BY tag) AS tags
                    FROM teaching_resource_tags
                    GROUP BY resource_id
                ) tag_rows
                WHERE tag_rows.resource_id = tr.id
                """
            )
        )

    op.drop_index("idx_teaching_resource_tag_tag", table_name="teaching_resource_tags")
    op.drop_index("uk_teaching_resource_tag", table_name="teaching_resource_tags")
    op.drop_table("teaching_resource_tags")
