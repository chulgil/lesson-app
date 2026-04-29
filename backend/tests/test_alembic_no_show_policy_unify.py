"""alembic 0010_unify_no_show_policy 검증 — Plan B Phase 5c (#239).

NoShowPolicy 4값 통합 + 레거시 group_classes.no_show_policy (deduct/noDeduct) 변환.
"""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_unify_no_show_policy_chained_to_align_booking_status() -> None:
    """0010 의 down_revision 이 align_booking_status."""
    script = _script()
    rev = script.get_revision("unify_no_show_policy")
    assert rev is not None
    assert rev.down_revision == "align_booking_status"


def test_unify_no_show_policy_descendants_chain() -> None:
    """0010 위에 후속 revision 이 있어도 단일 chain (no branching)."""
    script = _script()
    heads = list(script.get_heads())
    assert len(heads) == 1, f"expected single head, got {heads}"
    # 0010 까지 거꾸로 따라갈 수 있어야 함 (chain 정합)
    head = script.get_revision(heads[0])
    chain = {head.revision}
    cursor = head
    while cursor.down_revision:
        down = cursor.down_revision if isinstance(cursor.down_revision, str) else cursor.down_revision[0]
        cursor = script.get_revision(down)
        chain.add(cursor.revision)
    assert "unify_no_show_policy" in chain


def test_unify_no_show_policy_data_migration_present() -> None:
    """upgrade() 가 deduct→deductCredit, noDeduct→noDeduction UPDATE 포함."""
    script = _script()
    rev = script.get_revision("unify_no_show_policy")
    src_path = Path(rev.module.__file__)
    source = src_path.read_text()
    # 데이터 변환 SSOT
    assert "deductCredit" in source
    assert "noDeduction" in source
    assert "halfCredit" in source
    assert "reschedule" in source
    # 레거시 → 새 값 매핑
    assert "deduct" in source  # legacy 'deduct' 등장 (UPDATE WHERE 조건)
    assert "noDeduct" in source  # legacy 'noDeduct' 등장
