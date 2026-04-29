"""NoShowPolicy 4값 통합 검증 — Plan B Phase 5c (#239).

결정 게이트 (2026-04-29): 4값 단일 enum 채택.
- deductCredit, halfCredit, noDeduction, reschedule
- 레거시 2값 (deduct/noDeduct) 제거
- IndividualNoShowPolicy (schedule_ext.py) 와 동일 enum 으로 통합 (별도 클래스 폐기)
"""

import pytest


def test_no_show_policy_has_four_spec_values() -> None:
    """schedule.py NoShowPolicy 가 4값 SSOT."""
    from app.models.schedule import NoShowPolicy

    expected = {"deductCredit", "halfCredit", "noDeduction", "reschedule"}
    actual = {p.value for p in NoShowPolicy}
    assert actual == expected, f"diff: {actual ^ expected}"


def test_no_show_policy_rejects_legacy_deduct() -> None:
    """레거시 'deduct' 값은 더 이상 NoShowPolicy 멤버 아님."""
    from app.models.schedule import NoShowPolicy

    with pytest.raises(ValueError):
        NoShowPolicy("deduct")


def test_no_show_policy_rejects_legacy_no_deduct() -> None:
    """레거시 'noDeduct' 값은 더 이상 NoShowPolicy 멤버 아님."""
    from app.models.schedule import NoShowPolicy

    with pytest.raises(ValueError):
        NoShowPolicy("noDeduct")


def test_individual_no_show_policy_aliased_to_no_show_policy() -> None:
    """IndividualNoShowPolicy 는 schedule.py NoShowPolicy 와 동일 (단일 SSOT)."""
    from app.models.schedule import NoShowPolicy
    from app.models.schedule_ext import IndividualNoShowPolicy

    # 통합 후: 동일 enum 이거나 동일 값 집합
    assert {p.value for p in IndividualNoShowPolicy} == {p.value for p in NoShowPolicy}
