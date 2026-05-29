"""Contract tests for normalized feedback template storage."""

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


def test_feedback_template_tags_are_normalized_in_metadata() -> None:
    """Tags must be rows with FK/unique constraints, not a JSON array column."""
    template_table = Base.metadata.tables["feedback_templates"]
    tag_table = Base.metadata.tables["feedback_template_tags"]

    assert "tags" not in template_table.c
    assert "feedback_templates.id" in _foreign_key_targets(
        "feedback_template_tags",
        "template_id",
    )

    indexes = {
        tuple(index.expressions)
        for index in tag_table.indexes
        if index.unique
    }
    assert (tag_table.c.template_id, tag_table.c.tag) in indexes


def test_feedback_template_migration_is_chained_and_normalized() -> None:
    """Alembic migration should create normalized feedback template tables."""
    script = _script()
    rev = script.get_revision("add_feedback_template_tables")
    assert rev is not None
    assert rev.down_revision == "align_schedule_confirmation_status_enum"

    source = Path(rev.module.__file__).read_text()
    assert "feedback_templates" in source
    assert "feedback_template_tags" in source
    assert "fk_feedback_template_tags_template_id_feedback_templates" in source
    assert "uk_feedback_template_tag" in source
    assert "create_type=False" in source


def test_teaching_resource_tags_are_normalized_in_metadata() -> None:
    """Resource tags must be searchable rows, not a JSON array column."""
    resource_table = Base.metadata.tables["teaching_resources"]
    tag_table = Base.metadata.tables["teaching_resource_tags"]

    assert "tags" not in resource_table.c
    assert "teaching_resources.id" in _foreign_key_targets(
        "teaching_resource_tags",
        "resource_id",
    )

    indexes = {
        tuple(index.expressions)
        for index in tag_table.indexes
        if index.unique
    }
    assert (tag_table.c.resource_id, tag_table.c.tag) in indexes


def test_teaching_resource_tag_migration_is_chained_and_normalized() -> None:
    """Alembic migration should create normalized teaching resource tag rows."""
    script = _script()
    rev = script.get_revision("normalize_teaching_resource_tags")
    assert rev is not None
    assert rev.down_revision == "add_feedback_template_tables"

    source = Path(rev.module.__file__).read_text()
    assert "teaching_resource_tags" in source
    assert "fk_teaching_resource_tags_resource_id_teaching_resources" in source
    assert "uk_teaching_resource_tag" in source
    assert "op.drop_column(\"teaching_resources\", \"tags\")" in source
