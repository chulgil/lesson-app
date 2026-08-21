"""Timezone isolation guard — KST is defined in exactly one place.

글로벌 확장 전제 (옵시디언 56-글로벌-확장-전략): 레슨 시각을 KST 벽시계로
해석하는 코드가 서비스·잡 전반에 인라인으로 흩어지면 멀티 타임존 전환 시
마이그레이션 지점을 특정할 수 없다. 그래서 KST/기본 타임존은
``app/core/timezones.py`` 한 곳에서만 정의하고, 나머지는 전부 import 한다.

이 테스트는 FE ``test/architecture`` 계약 테스트와 같은 소스-스캔 패턴으로
인라인 재정의를 기계적으로 차단한다.
"""

from __future__ import annotations

import re
from pathlib import Path

from app.core.timezones import DEFAULT_TIMEZONE_NAME, KST, tz_of

APP_DIR = Path(__file__).resolve().parents[1] / "app"
SEAM = APP_DIR / "core" / "timezones.py"

# Inline definitions this guard forbids outside the seam module. The
# ``timedelta(hours=9)`` form is the legacy fixed-offset spelling of KST.
INLINE_PATTERNS = (
    re.compile(r'ZoneInfo\(\s*"Asia/Seoul"'),
    re.compile(r"timezone\(\s*timedelta\(\s*hours\s*=\s*9\b"),
    re.compile(r'"Asia/Seoul"'),
)


def test_kst_is_defined_only_in_the_timezones_seam() -> None:
    violations: list[str] = []
    for path in sorted(APP_DIR.rglob("*.py")):
        if path == SEAM:
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in INLINE_PATTERNS:
            if pattern.search(text):
                violations.append(f"{path.relative_to(APP_DIR.parent)}: {pattern.pattern}")
    assert not violations, (
        "KST/'Asia/Seoul' 은 app/core/timezones.py 에서만 정의한다. "
        "인라인 정의 대신 `from app.core.timezones import KST` "
        "(기본 타임존 이름은 DEFAULT_TIMEZONE_NAME) 를 사용할 것. 위반:\n" + "\n".join(violations)
    )


class TestTzOf:
    def test_none_falls_back_to_kst(self) -> None:
        assert tz_of(None) is KST

    def test_empty_string_falls_back_to_kst(self) -> None:
        assert tz_of("") is KST

    def test_valid_iana_name_resolves(self) -> None:
        assert str(tz_of("America/New_York")) == "America/New_York"

    def test_default_name_resolves_to_kst_equivalent(self) -> None:
        assert str(tz_of(DEFAULT_TIMEZONE_NAME)) == "Asia/Seoul"

    def test_invalid_name_falls_back_to_kst(self) -> None:
        assert tz_of("Not/AZone") is KST

    def test_garbage_value_falls_back_to_kst(self) -> None:
        assert tz_of("../etc/passwd") is KST
