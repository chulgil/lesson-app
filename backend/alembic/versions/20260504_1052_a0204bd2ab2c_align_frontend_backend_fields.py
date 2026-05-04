"""align_frontend_backend_fields

Align backend DB columns with Flutter frontend entities.
- subscription_templates: +5 columns (validity_days, lesson_duration_minutes, display_order, reschedule_allowance, is_auto_proposal_enabled)
- schedule_confirmation_cards: +6 columns (lesson_request_id, card_type, instrument, proposed_slots, total_lessons) + enum updates
- subscription_usages: +2 columns (note, deducted)
- subscription_proposals: +4 columns (proposal_type, is_renewal, previous_subscription_id, renewal_initiator)

Revision ID: a0204bd2ab2c
Revises: add_request_event_subscription_session_index
Create Date: 2026-05-04 10:52:46.222222+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a0204bd2ab2c'
down_revision: Union[str, None] = 'add_request_event_subscription_session_index'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- subscription_templates ---
    op.add_column("subscription_templates", sa.Column("lesson_duration_minutes", sa.Integer(), nullable=False, server_default="60"))
    op.add_column("subscription_templates", sa.Column("validity_days", sa.Integer(), nullable=True))
    op.add_column("subscription_templates", sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("subscription_templates", sa.Column("reschedule_allowance", sa.Integer(), nullable=False, server_default="2"))
    op.add_column("subscription_templates", sa.Column("is_auto_proposal_enabled", sa.Boolean(), nullable=False, server_default="false"))

    # --- schedule_confirmation_cards ---
    op.add_column("schedule_confirmation_cards", sa.Column("lesson_request_id", sa.String(36), nullable=True))
    op.add_column("schedule_confirmation_cards", sa.Column("card_type", sa.String(30), nullable=False, server_default="afterTrial"))
    op.add_column("schedule_confirmation_cards", sa.Column("instrument", sa.String(50), nullable=True))
    op.add_column("schedule_confirmation_cards", sa.Column("proposed_slots", sa.JSON(), nullable=True))
    op.add_column("schedule_confirmation_cards", sa.Column("total_lessons", sa.Integer(), nullable=True))

    # --- subscription_usages ---
    op.add_column("subscription_usages", sa.Column("note", sa.Text(), nullable=True))
    op.add_column("subscription_usages", sa.Column("deducted", sa.Boolean(), nullable=False, server_default="true"))

    # --- subscription_proposals ---
    op.add_column("subscription_proposals", sa.Column("proposal_type", sa.String(20), nullable=False, server_default="proposal"))
    op.add_column("subscription_proposals", sa.Column("is_renewal", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("subscription_proposals", sa.Column("previous_subscription_id", sa.String(36), nullable=True))
    op.add_column("subscription_proposals", sa.Column("renewal_initiator", sa.String(20), nullable=True))


def downgrade() -> None:
    # --- subscription_proposals ---
    op.drop_column("subscription_proposals", "renewal_initiator")
    op.drop_column("subscription_proposals", "previous_subscription_id")
    op.drop_column("subscription_proposals", "is_renewal")
    op.drop_column("subscription_proposals", "proposal_type")

    # --- subscription_usages ---
    op.drop_column("subscription_usages", "deducted")
    op.drop_column("subscription_usages", "note")

    # --- schedule_confirmation_cards ---
    op.drop_column("schedule_confirmation_cards", "total_lessons")
    op.drop_column("schedule_confirmation_cards", "proposed_slots")
    op.drop_column("schedule_confirmation_cards", "instrument")
    op.drop_column("schedule_confirmation_cards", "card_type")
    op.drop_column("schedule_confirmation_cards", "lesson_request_id")

    # --- subscription_templates ---
    op.drop_column("subscription_templates", "is_auto_proposal_enabled")
    op.drop_column("subscription_templates", "reschedule_allowance")
    op.drop_column("subscription_templates", "display_order")
    op.drop_column("subscription_templates", "validity_days")
    op.drop_column("subscription_templates", "lesson_duration_minutes")
