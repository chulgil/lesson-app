"""BookingStatus enum 정렬 검증 — Plan B Phase 1 (#238).

frontend SSOT: `docs/specs/lesson/lesson_master.md` §10.2 — 7값.
결정 게이트 (2026-04-29):
- §6.1 noShow → 옵션 A (제거, NoShowRecord 테이블이 SSOT)
- §6.2 rejected → 옵션 A (제거, decline_reason 컬럼으로 사유 보존)
"""

import pytest


def test_booking_status_has_seven_spec_values() -> None:
    """spec §10.2 의 7값과 1:1 일치 (approved/rejected/noShow 제거 + confirmed/unavailable/expired 추가)."""
    from app.models.schedule import BookingStatus

    expected = {
        "pending",
        "confirmed",
        "changeRequested",
        "completed",
        "cancelled",
        "unavailable",
        "expired",
    }
    actual = {s.value for s in BookingStatus}
    assert actual == expected, f"diff: {actual ^ expected}"


def test_booking_status_rejects_legacy_approved() -> None:
    """레거시 'approved' 값은 더 이상 BookingStatus 멤버 아님 (rename → confirmed)."""
    from app.models.schedule import BookingStatus

    with pytest.raises(ValueError):
        BookingStatus("approved")


def test_booking_status_rejects_legacy_rejected() -> None:
    """레거시 'rejected' 값은 더 이상 BookingStatus 멤버 아님 (decline_reason 컬럼으로 분리)."""
    from app.models.schedule import BookingStatus

    with pytest.raises(ValueError):
        BookingStatus("rejected")


def test_booking_status_rejects_legacy_no_show() -> None:
    """레거시 'noShow' 값은 더 이상 BookingStatus 멤버 아님 (NoShowRecord 테이블로 분리)."""
    from app.models.schedule import BookingStatus

    with pytest.raises(ValueError):
        BookingStatus("noShow")
