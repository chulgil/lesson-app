"""Single source of truth for service timezones.

글로벌 확장 전제 (옵시디언 56-글로벌-확장-전략, 2026-08-21): 한국 단일 운영
기간의 "KST 벽시계" 해석은 전부 이 모듈을 거친다. 인라인
``ZoneInfo("Asia/Seoul")`` / ``timezone(timedelta(hours=9))`` 재정의는
``tests/test_timezone_isolation.py`` 가드가 차단한다.

멀티 타임존 전환 시나리오: 잡/서비스가 ``KST`` 상수 대신 ``tz_of(
user.timezone)`` 을 읽도록 호출부만 바꾸면 된다 — 정의 지점이 한 곳이므로
전환 대상이 grep 한 번으로 특정된다. ``users.timezone`` /
``academies.timezone`` 컬럼은 초기 스키마부터 존재한다.
"""

from __future__ import annotations

from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

# Default service timezone name — model column defaults and signup fallback
# share this value.
DEFAULT_TIMEZONE_NAME = "Asia/Seoul"

# The only KST definition in the codebase. ``Asia/Seoul`` has been fixed at
# UTC+9 since 1988, so this is equivalent to the legacy
# ``timezone(timedelta(hours=9))`` spelling it replaces.
KST = ZoneInfo(DEFAULT_TIMEZONE_NAME)


def tz_of(name: str | None) -> ZoneInfo:
    """Resolve an IANA timezone name (e.g. ``users.timezone``) to a tzinfo.

    Falls back to :data:`KST` for ``None``/empty/unknown names — a bad stored
    value must never break scheduling, it just degrades to the service
    default.
    """
    if not name:
        return KST
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError):
        return KST
