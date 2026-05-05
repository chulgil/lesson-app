"""Add subscription foreign key constraints.

Revision ID: add_subscription_fk_constraints
Revises: add_request_event_schedule_change_snapshots
Create Date: 2026-05-05 10:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_subscription_fk_constraints"
down_revision: str | None = "add_request_event_schedule_change_snapshots"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.create_foreign_key(
            "fk_subscriptions_student_id_students",
            "students",
            ["student_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscriptions_membership_id_class_memberships",
            "class_memberships",
            ["membership_id"],
            ["id"],
        )

    with op.batch_alter_table("subscription_usages") as batch_op:
        batch_op.create_foreign_key(
            "fk_subscription_usages_subscription_id_subscriptions",
            "subscriptions",
            ["subscription_id"],
            ["id"],
        )

    with op.batch_alter_table("subscription_templates") as batch_op:
        batch_op.create_foreign_key(
            "fk_subscription_templates_teacher_id_teachers",
            "teachers",
            ["teacher_id"],
            ["id"],
        )

    with op.batch_alter_table("subscription_proposals") as batch_op:
        batch_op.create_foreign_key(
            "fk_subscription_proposals_teacher_id_teachers",
            "teachers",
            ["teacher_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_student_id_students",
            "students",
            ["student_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_template_id_subscription_templates",
            "subscription_templates",
            ["template_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_recommended_template_id_subscription_templates",
            "subscription_templates",
            ["recommended_template_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_selected_template_id_subscription_templates",
            "subscription_templates",
            ["selected_template_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_subscription_id_subscriptions",
            "subscriptions",
            ["subscription_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "fk_subscription_proposals_previous_subscription_id_subscriptions",
            "subscriptions",
            ["previous_subscription_id"],
            ["id"],
        )

    with op.batch_alter_table("request_events") as batch_op:
        batch_op.create_foreign_key(
            "fk_request_events_subscription_id_subscriptions",
            "subscriptions",
            ["subscription_id"],
            ["id"],
        )


def downgrade() -> None:
    with op.batch_alter_table("request_events") as batch_op:
        batch_op.drop_constraint("fk_request_events_subscription_id_subscriptions", type_="foreignkey")

    with op.batch_alter_table("subscription_proposals") as batch_op:
        batch_op.drop_constraint("fk_subscription_proposals_previous_subscription_id_subscriptions", type_="foreignkey")
        batch_op.drop_constraint("fk_subscription_proposals_subscription_id_subscriptions", type_="foreignkey")
        batch_op.drop_constraint(
            "fk_subscription_proposals_selected_template_id_subscription_templates",
            type_="foreignkey",
        )
        batch_op.drop_constraint(
            "fk_subscription_proposals_recommended_template_id_subscription_templates",
            type_="foreignkey",
        )
        batch_op.drop_constraint("fk_subscription_proposals_template_id_subscription_templates", type_="foreignkey")
        batch_op.drop_constraint("fk_subscription_proposals_student_id_students", type_="foreignkey")
        batch_op.drop_constraint("fk_subscription_proposals_teacher_id_teachers", type_="foreignkey")

    with op.batch_alter_table("subscription_templates") as batch_op:
        batch_op.drop_constraint("fk_subscription_templates_teacher_id_teachers", type_="foreignkey")

    with op.batch_alter_table("subscription_usages") as batch_op:
        batch_op.drop_constraint("fk_subscription_usages_subscription_id_subscriptions", type_="foreignkey")

    with op.batch_alter_table("subscriptions") as batch_op:
        batch_op.drop_constraint("fk_subscriptions_membership_id_class_memberships", type_="foreignkey")
        batch_op.drop_constraint("fk_subscriptions_student_id_students", type_="foreignkey")
