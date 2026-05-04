"""Verify Phase 6a alembic migration `add_sub_expiry_dispatch_log`.

Plan C §1 — 다중 인스턴스 발화 방어용 dedup 테이블.
"""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_dispatch_log_revision_chains_after_no_show_policy() -> None:
    """0011 의 down_revision 이 0010 unify_no_show_policy."""
    script = _script()
    rev = script.get_revision("add_sub_expiry_dispatch_log")
    assert rev is not None
    assert rev.down_revision == "unify_no_show_policy"


def test_single_alembic_head() -> None:
    """단일 head 가 유지되는지 확인 (head 이름은 마이그레이션 추가 시 변동)."""
    script = _script()
    heads = list(script.get_heads())
    assert len(heads) == 1, f"expected single head, got {heads}"


def test_recording_owner_file_key_chains_after_dispatch_log() -> None:
    """recording owner/file_key migration follows payment cleanup migration."""
    script = _script()
    rev = script.get_revision("add_recording_owner_file_key")
    assert rev is not None
    assert rev.down_revision == "drop_pg_fields"


def test_relationship_practice_permissions_chains_after_recording_owner() -> None:
    """relationship practice permissions migration follows recording owner migration."""
    script = _script()
    rev = script.get_revision("add_relation_practice_permissions")
    assert rev is not None
    assert rev.down_revision == "add_recording_owner_file_key"


def test_parent_visibility_settings_chains_after_relationship_permissions() -> None:
    """parent visibility settings migration follows relationship permissions migration."""
    script = _script()
    rev = script.get_revision("add_parent_visibility_settings")
    assert rev is not None
    assert rev.down_revision == "add_relation_practice_permissions"


def test_parent_api_spec_alignment_chains_after_parent_visibility_settings() -> None:
    """parent API spec alignment migration follows parent visibility settings migration."""
    script = _script()
    rev = script.get_revision("align_parent_api_spec")
    assert rev is not None
    assert rev.down_revision == "add_parent_visibility_settings"


def test_subscription_alert_days_set_chains_after_parent_api_spec_alignment() -> None:
    """subscription alert days-set migration follows parent API spec alignment."""
    script = _script()
    rev = script.get_revision("add_subscription_alert_days_set")
    assert rev is not None
    assert rev.down_revision == "align_parent_api_spec"


def test_dispatch_log_migration_creates_unique_constraint() -> None:
    """upgrade() 가 UNIQUE(subscription_id, milestone, sent_date, recipient_user_id)."""
    script = _script()
    rev = script.get_revision("add_sub_expiry_dispatch_log")
    src_path = Path(rev.module.__file__)
    source = src_path.read_text()
    assert "uq_sub_expiry_dispatch" in source
    assert "subscription_id" in source
    assert "milestone" in source
    assert "recipient_user_id" in source
    assert "sent_date" in source


def test_dispatch_log_migration_has_downgrade() -> None:
    """downgrade() drop_table 포함 — 롤백 가능성 보장."""
    script = _script()
    rev = script.get_revision("add_sub_expiry_dispatch_log")
    src_path = Path(rev.module.__file__)
    source = src_path.read_text()
    assert "def downgrade" in source
    assert "drop_table" in source
