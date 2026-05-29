"""Contract tests for subscription-related database foreign keys."""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def _foreign_key_targets(table_name: str, column_name: str) -> set[str]:
    table = Base.metadata.tables[table_name]
    column = table.c[column_name]
    return {fk.target_fullname for fk in column.foreign_keys}


def test_subscription_models_define_core_foreign_keys() -> None:
    """SQLAlchemy metadata should prevent orphan subscription rows in create_all DBs."""
    assert "students.id" in _foreign_key_targets("subscriptions", "student_id")
    assert "class_memberships.id" in _foreign_key_targets("subscriptions", "membership_id")
    assert "subscriptions.id" in _foreign_key_targets("subscription_usages", "subscription_id")
    assert "teachers.id" in _foreign_key_targets("subscription_templates", "teacher_id")
    assert "teachers.id" in _foreign_key_targets("subscription_proposals", "teacher_id")
    assert "students.id" in _foreign_key_targets("subscription_proposals", "student_id")
    assert "subscription_templates.id" in _foreign_key_targets("subscription_proposals", "template_id")
    assert "subscription_templates.id" in _foreign_key_targets("subscription_proposals", "recommended_template_id")
    assert "subscription_templates.id" in _foreign_key_targets("subscription_proposals", "selected_template_id")
    assert "subscriptions.id" in _foreign_key_targets("subscription_proposals", "subscription_id")
    assert "subscriptions.id" in _foreign_key_targets("subscription_proposals", "previous_subscription_id")
    assert "subscriptions.id" in _foreign_key_targets("request_events", "subscription_id")


def test_subscription_fk_migration_is_chained_and_declares_constraints() -> None:
    """Alembic migration should add the same FK constraints for upgraded databases."""
    script = _script()
    rev = script.get_revision("add_subscription_fk_constraints")
    assert rev is not None
    assert rev.down_revision == "add_request_event_schedule_change_snapshots"

    source = Path(rev.module.__file__).read_text()
    for name in [
        "fk_subscriptions_student_id_students",
        "fk_subscriptions_membership_id_class_memberships",
        "fk_subscription_usages_subscription_id_subscriptions",
        "fk_subscription_templates_teacher_id_teachers",
        "fk_subscription_proposals_teacher_id_teachers",
        "fk_subscription_proposals_student_id_students",
        "fk_subscription_proposals_template_id_subscription_templates",
        "fk_sub_proposals_recommended_template_id_templates",
        "fk_sub_proposals_selected_template_id_templates",
        "fk_subscription_proposals_subscription_id_subscriptions",
        "fk_sub_proposals_previous_subscription_id_subscriptions",
        "fk_request_events_subscription_id_subscriptions",
    ]:
        assert len(name) <= 63
        assert name in source


def test_subscription_counter_check_migration_is_chained_and_declares_constraints() -> None:
    """Alembic migration should add subscription counter check constraints."""
    script = _script()
    rev = script.get_revision("add_subscription_counter_checks")
    assert rev is not None
    assert rev.down_revision == "add_bulk_teacher_action_event_types"

    source = Path(rev.module.__file__).read_text()
    for name in [
        "ck_subscriptions_non_negative_counters",
        "ck_subscriptions_lesson_counter_capacity",
        "ck_subscriptions_reschedule_counter_capacity",
    ]:
        assert name in source
