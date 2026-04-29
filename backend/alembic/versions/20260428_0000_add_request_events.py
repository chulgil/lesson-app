"""Add request_events table — RequestEvent SSOT (Plan A Phase 1)

Revision ID: add_request_events
Revises: add_reschedule_deadline_hours
Create Date: 2026-04-28 00:00:00.000000

Plan A Phase 1 (Issue #235, audit P0-2/P0-4).
Mirrors frontend Hive RequestEvent (typeId 131) — 27 event_type + 2 schedule_change_type.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_request_events"
down_revision: str | None = "add_reschedule_deadline_hours"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


REQUEST_EVENT_TYPE_VALUES = (
    "initialRequest",
    "approve",
    "reject",
    "proposeAlternative",
    "counterPropose",
    "acceptAlternative",
    "cancel",
    "expire",
    "proposalSent",
    "proposalAccepted",
    "paymentNotified",
    "completed",
    "withdrawApproval",
    "paymentRequested",
    "paymentConfirmed",
    "subscriptionIssued",
    "lessonCompleted",
    "lessonCancelled",
    "scheduleChanged",
    "lessonNoteAdded",
    "subscriptionRenewed",
    "subscriptionCompleted",
    "scheduleChangeProposed",
    "scheduleChangeAccepted",
    "scheduleChangeRejected",
    "scheduleChangeCountered",
    "message",
)

SCHEDULE_CHANGE_TYPE_VALUES = ("singleLesson", "bulkChange")


def upgrade() -> None:
    op.create_table(
        "request_events",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("request_id", sa.String(length=36), nullable=False),
        sa.Column("actor_type", sa.String(length=20), nullable=False),
        sa.Column("actor_id", sa.String(length=36), nullable=False),
        sa.Column(
            "event_type",
            sa.Enum(*REQUEST_EVENT_TYPE_VALUES, name="requesteventtype"),
            nullable=False,
        ),
        sa.Column("suggested_slots", sa.JSON(), nullable=True),
        sa.Column("selected_slot_index", sa.Integer(), nullable=True),
        sa.Column("message", sa.Text(), nullable=True),
        sa.Column(
            "schedule_change_type",
            sa.Enum(*SCHEDULE_CHANGE_TYPE_VALUES, name="schedulechangetype"),
            nullable=True,
        ),
        sa.Column("proposed_day_of_week", sa.Integer(), nullable=True),
        sa.Column("proposed_time", sa.String(length=5), nullable=True),
        sa.Column("subscription_id", sa.String(length=36), nullable=True),
        sa.Column("session_number", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("idx_request_events_request_id", "request_events", ["request_id"])
    op.create_index("idx_request_events_event_type", "request_events", ["event_type"])
    op.create_index(
        "idx_request_events_request_created",
        "request_events",
        ["request_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_request_events_request_created", table_name="request_events")
    op.drop_index("idx_request_events_event_type", table_name="request_events")
    op.drop_index("idx_request_events_request_id", table_name="request_events")
    op.drop_table("request_events")

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        sa.Enum(name="requesteventtype").drop(bind, checkfirst=True)
        sa.Enum(name="schedulechangetype").drop(bind, checkfirst=True)
