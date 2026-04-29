"""Verify alembic revision chain integrity.

`add_reschedule_deadline_hours` 가 존재하지 않는 `add_bank_account_change_logs`
를 down_revision 으로 참조하여 `alembic upgrade head` 가 KeyError 로 실패함.
fix: down_revision 을 실제 직전 head (`e34fbc3ccb63`) 로 수정.

Refs #252.
"""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _script() -> ScriptDirectory:
    """Project root 의 alembic.ini 를 읽어 ScriptDirectory 반환."""
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_alembic_chain_resolves_to_single_head() -> None:
    """모든 마이그레이션이 단일 head 로 수렴해야 한다 (체인 단절 0건)."""
    script = _script()
    heads = script.get_heads()
    assert len(heads) == 1, f"alembic chain 다중 head 또는 단절: heads={heads}"


def test_alembic_chain_walks_from_base_to_head() -> None:
    """base→head 전체 walk 가 KeyError 없이 완주해야 한다 (체인 단절 0건)."""
    script = _script()
    head = script.get_current_head()
    assert head is not None, "head revision 없음"

    revisions = list(script.walk_revisions(base="base", head=head))
    assert len(revisions) >= 9, f"기대 마이그레이션 9건+, 실제 {len(revisions)}건 — 체인 단절 의심"


def test_add_reschedule_deadline_hours_down_revision_resolves() -> None:
    """add_reschedule_deadline_hours.down_revision 이 실제 존재하는 revision 이어야."""
    script = _script()
    rev = script.get_revision("add_reschedule_deadline_hours")
    assert rev is not None, "add_reschedule_deadline_hours revision 없음"

    down = rev.down_revision
    assert down is not None, "down_revision 이 None"

    target = script.get_revision(down)
    assert target is not None, f"down_revision='{down}' 이 존재하지 않는 fictional revision — 체인 단절 (#252)"
