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


def test_dispatch_log_chains_to_current_head() -> None:
    """0011 이 head 체인 안에 있고, 단일 head 가 유지된다.

    2026-04-30 Phase 3-1 에서 `backup_lsc_legacy` 가 0011 위에 추가되어
    head 가 이동했다. 0011 자체가 head 였던 시점은 끝났지만, 단일 head
    유지(linear chain)는 보장.
    """
    script = _script()
    heads = list(script.get_heads())
    assert len(heads) == 1, f"expected single head, got {heads}"
    walked = {rev.revision for rev in script.walk_revisions()}
    assert "add_sub_expiry_dispatch_log" in walked


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
