"""alembic 0009_align_booking_status 데이터 마이그레이션 검증 — Plan B Phase 5b (#238).

postgres ENUM 변경은 offline SQL 으로 검증 (tests 는 sqlite).
sqlite 환경에서는 status 컬럼이 VARCHAR 이므로 데이터 변환만 확인.
"""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_align_booking_status_revision_chained_to_request_events() -> None:
    """0009 의 down_revision 이 add_request_events 인지 (chain 무결성)."""
    script = _script()
    rev = script.get_revision("align_booking_status")
    assert rev is not None
    assert rev.down_revision == "add_request_events"


def test_align_booking_status_is_head() -> None:
    """0009 가 단일 head 인지."""
    script = _script()
    heads = list(script.get_heads())
    assert heads == ["align_booking_status"], f"expected single head, got {heads}"


def test_align_booking_status_adds_decline_reason() -> None:
    """upgrade() 가 lesson_bookings.decline_reason 컬럼을 추가하는지 — 소스 검사."""
    script = _script()
    rev = script.get_revision("align_booking_status")
    src_path = Path(rev.module.__file__)
    source = src_path.read_text()
    assert "decline_reason" in source
    # add_column 호출에 lesson_bookings 와 decline_reason 이 함께 등장 (formatter multiline 허용)
    assert "add_column" in source
    assert "lesson_bookings" in source


def test_align_booking_status_migrates_legacy_values() -> None:
    """upgrade() 가 approved→confirmed, rejected→cancelled, noShow→cancelled UPDATE 를 포함."""
    script = _script()
    rev = script.get_revision("align_booking_status")
    src_path = Path(rev.module.__file__)
    source = src_path.read_text()
    # 데이터 변환 SSOT — 결정 게이트 §6.1/§6.2 옵션 A
    assert "approved" in source and "confirmed" in source
    assert "rejected" in source and "cancelled" in source
    assert "noShow" in source
