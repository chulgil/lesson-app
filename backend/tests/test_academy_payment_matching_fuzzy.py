"""Unit tests for fuzzy matching algorithm — AC-M3 §3.

Spec: docs/specs/web/academy/payment_matching_spec.md §3.

Pure function 단위 — DB 없음, fixture 없음.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.services.academy_payment_matching_fuzzy import (
    STRONG_SUGGESTION_THRESHOLD,
    WEAK_SUGGESTION_THRESHOLD,
    compute_match_score,
    has_family_title,
    normalize_depositor,
    score_amount,
    score_family_title,
    score_memo_code,
    score_name_levenshtein,
    score_student_name_token,
    score_time_proximity,
)

# ---------------------------------------------------------------------------
# §3.2 정규화 — spec 본문 예시 4건 그대로
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("김지민 어머니", "김지민"),
        ("김지민어머니", "김지민"),
        ("0418지민", "지민"),
        ("이지수아빠", "이지수"),
        ("KIM JIMIN", ""),  # 영문 제거
        ("", ""),
        ("  김 지민  ", "김지민"),  # 공백 제거
    ],
)
def test_normalize_depositor_spec_examples(raw: str, expected: str) -> None:
    assert normalize_depositor(raw) == expected


def test_has_family_title_detects_suffix() -> None:
    assert has_family_title("김지민 어머니") is True
    assert has_family_title("지민이엄마") is True
    assert has_family_title("이지수아빠") is True
    assert has_family_title("김지민") is False
    assert has_family_title("") is False


# ---------------------------------------------------------------------------
# §3.1 신호별 점수
# ---------------------------------------------------------------------------


def test_score_amount_exact_within_100_won() -> None:
    """±100원 일치 → 1.0."""
    assert score_amount(200_000, 200_000) == 1.0
    assert score_amount(200_050, 200_000) == 1.0  # 50원 차 — 정확 일치 간주
    assert score_amount(199_900, 200_000) == 1.0


def test_score_amount_partial_payment_returns_half() -> None:
    """부분 입금 (tx < invoice) → 0.5."""
    assert score_amount(100_000, 200_000) == 0.5


def test_score_amount_over_payment_returns_zero() -> None:
    """초과 입금 → 0 (§7.3 별도 처리)."""
    assert score_amount(300_000, 200_000) == 0.0


def test_score_name_levenshtein_exact_match() -> None:
    """정규화 후 정확 일치 → 1.0."""
    assert score_name_levenshtein("김지민 어머니", "김지민") == 1.0


def test_score_name_levenshtein_partial() -> None:
    """1글자 차이 → 1 - 1/3 ≈ 0.667."""
    score = score_name_levenshtein("김지호", "김지민")
    assert 0.6 < score < 0.7


def test_score_student_name_token_full_match() -> None:
    """학생 이름 전체 substring → 1.0."""
    assert score_student_name_token("이지수아빠", "이지수") == 1.0


def test_score_student_name_token_surname_missing() -> None:
    """성씨 누락 (마지막 2글자만 일치) → 0.7."""
    assert score_student_name_token("지민이엄마", "김지민") == 0.7


def test_score_student_name_token_no_match() -> None:
    assert score_student_name_token("박철수", "김지민") == 0.0


def test_score_family_title_requires_both_signals() -> None:
    """가족 호칭 + 학생 이름 토큰 모두 있을 때만 1.0."""
    assert score_family_title("김지민 어머니", "김지민") == 1.0
    assert score_family_title("김지민", "김지민") == 0.0  # 호칭 없음
    assert score_family_title("박철수아빠", "김지민") == 0.0  # 학생 이름 없음


def test_score_memo_code_substring() -> None:
    assert score_memo_code("0418지민", "0418") == 1.0
    assert score_memo_code("입금메모", "0418") == 0.0
    assert score_memo_code(None, "0418") == 0.0
    assert score_memo_code("0418", None) == 0.0


def test_score_time_proximity_within_7d() -> None:
    base = datetime(2026, 5, 10, tzinfo=UTC)
    assert score_time_proximity(base, base) == 1.0
    assert score_time_proximity(base + timedelta(days=5), base) == 1.0
    assert score_time_proximity(base + timedelta(days=10), base) == 0.5
    assert score_time_proximity(base + timedelta(days=30), base) == 0.0
    assert score_time_proximity(base, None) == 0.0


# ---------------------------------------------------------------------------
# 가중 합 — 종합 시나리오
# ---------------------------------------------------------------------------


def test_compute_strong_suggestion_full_amount_family_title() -> None:
    """§6.1 강한 제안 (0.92): 금액 일치 + 가족 호칭 + 학생 이름."""
    base = datetime(2026, 5, 3, 14, 30, tzinfo=UTC)
    score, features = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="김지민 어머니",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base - timedelta(days=2),
        student_name="김지민",
        deposit_code=None,
    )
    # 금액 1.0×0.40 + 이름 1.0×0.25 + 토큰 1.0×0.15 + 가족 1.0×0.10 + 시각 1.0×0.05 = 0.95.
    assert score >= STRONG_SUGGESTION_THRESHOLD
    assert features["amount_exact"] == 1.0
    assert features["family_title"] == 1.0
    assert features["memo_code"] == 0.0


def test_compute_weak_suggestion_partial_amount() -> None:
    """§6.1 약한 제안 (~0.68): 부분 입금 + 가족 호칭 + 학생 이름."""
    base = datetime(2026, 5, 3, 14, 30, tzinfo=UTC)
    score, _ = compute_match_score(
        tx_amount=100_000,
        tx_at=base,
        depositor_raw="김지민 어머니",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base - timedelta(days=2),
        student_name="김지민",
        deposit_code=None,
    )
    # 금액 0.5×0.40 + 이름 1.0×0.25 + 토큰 1.0×0.15 + 가족 1.0×0.10 + 시각 1.0×0.05 = 0.75.
    assert WEAK_SUGGESTION_THRESHOLD <= score < STRONG_SUGGESTION_THRESHOLD


def test_compute_no_suggestion_for_unrelated_deposit() -> None:
    """완전 다른 입금 → 0.60 미만."""
    base = datetime(2026, 5, 3, tzinfo=UTC)
    score, _ = compute_match_score(
        tx_amount=350_000,  # 초과 → 0
        tx_at=base + timedelta(days=60),  # 시각 0
        depositor_raw="박철수",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base,
        student_name="김지민",
        deposit_code=None,
    )
    assert score < WEAK_SUGGESTION_THRESHOLD


def test_compute_memo_code_bonus() -> None:
    """메모 코드 일치 시 +0.05."""
    base = datetime(2026, 5, 3, tzinfo=UTC)
    score_with, _ = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="김지민",
        memo_raw="0418",
        invoice_total=200_000,
        invoice_ref_at=base,
        student_name="김지민",
        deposit_code="0418",
    )
    score_without, _ = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="김지민",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base,
        student_name="김지민",
        deposit_code="0418",
    )
    assert abs((score_with - score_without) - 0.05) < 0.001


# ---------------------------------------------------------------------------
# H2 — 학부모 이름 매칭 (§3.1 "학생 또는 학부모 이름 토큰", §3.4)
# ---------------------------------------------------------------------------


def test_compute_strong_suggestion_by_parent_name() -> None:
    """§3.4 학부모 본인 이름 입금 → 학부모 이름 신호로 강한 제안.

    학생명(김지민)과 무관한 학부모 이름(박영희)으로 입금해도 parent_name 이
    설정되어 있으면 이름/토큰 신호가 학부모 기준으로 산출된다.
    """
    base = datetime(2026, 5, 3, 14, 30, tzinfo=UTC)
    score, features = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="박영희",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base - timedelta(days=2),
        student_name="김지민",
        deposit_code=None,
        parent_name="박영희",
    )
    # 금액 1.0×0.40 + 이름(학부모) 1.0×0.25 + 토큰 1.0×0.15 + 시각 1.0×0.05 = 0.85.
    assert score >= STRONG_SUGGESTION_THRESHOLD
    assert features["name_levenshtein"] == 1.0
    assert features["student_name_token"] == 1.0


def test_compute_parent_name_with_family_title() -> None:
    """§3.3 학부모 이름 + 가족 호칭 ("박영희 이모") → family_title 신호."""
    base = datetime(2026, 5, 3, 14, 30, tzinfo=UTC)
    _, features = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="박영희 이모",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base - timedelta(days=2),
        student_name="김지민",
        deposit_code=None,
        parent_name="박영희",
    )
    assert features["family_title"] == 1.0


def test_compute_takes_max_of_student_and_parent_signals() -> None:
    """학생/학부모 둘 다 설정 시 더 높은 신호 채택 — 입금자=학생명이면 학생 기준."""
    base = datetime(2026, 5, 3, tzinfo=UTC)
    _, features = compute_match_score(
        tx_amount=200_000,
        tx_at=base,
        depositor_raw="김지민",
        memo_raw=None,
        invoice_total=200_000,
        invoice_ref_at=base,
        student_name="김지민",
        deposit_code=None,
        parent_name="박영희",  # 무관한 학부모 이름
    )
    assert features["student_name_token"] == 1.0
    assert features["name_levenshtein"] == 1.0
