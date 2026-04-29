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


def test_dispatch_log_is_alembic_head() -> None:
    """0011 이 단일 head."""
    script = _script()
    heads = list(script.get_heads())
    assert heads == ["add_sub_expiry_dispatch_log"], f"expected single head add_sub_expiry_dispatch_log, got {heads}"


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
