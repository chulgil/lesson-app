"""Academy payment fuzzy matching algorithm — AC-M3 §3.

Spec: docs/specs/web/academy/payment_matching_spec.md §3.

핵심 원칙 (§1):
- 알고리즘은 **제안만** 한다. 자동 매칭 X — 학원장 1탭 확정만.
- 6개 약한 신호의 **가중 합**. 단일 신호 자동 매칭 금지.
- 한국 특수 패턴 (가족 호칭, 메모 코드, 학생명 토큰) 신호 분리.

신호 가중치 (§3.1):
- 0.40 amount_exact (±100원 / 부분 / 그 외)
- 0.25 name_levenshtein (정규화 후 거리 비율)
- 0.15 student_name_token (학생명 substring)
- 0.10 family_title (가족 호칭 + 학생명 인접)
- 0.05 memo_code (memo_raw 에 deposit_code 일치)
- 0.05 time_proximity (≤7d → 1.0 / ≤14d → 0.5)

임계치 (§3.1):
- ≥ 0.85: 강한 제안 (학원장 1탭 확정 후보 상단)
- 0.60 ~ 0.84: 약한 제안 (후보 리스트)
- < 0.60: 미제안
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta

# §3.2: 가족 호칭 접미사 — 정규화 시 제거 + 가족 호칭 신호로 별도 처리.
_FAMILY_TITLES: tuple[str, ...] = (
    "외할머니",
    "외할아버지",
    "할아버지",
    "할머니",
    "어머니",
    "아버지",
    "아빠",
    "엄마",
    "이모",
    "고모",
    "삼촌",
)

# 신호별 가중치 (§3.1).
WEIGHTS: dict[str, float] = {
    "amount_exact": 0.40,
    "name_levenshtein": 0.25,
    "student_name_token": 0.15,
    "family_title": 0.10,
    "memo_code": 0.05,
    "time_proximity": 0.05,
}

# 임계치 (§3.1).
STRONG_SUGGESTION_THRESHOLD: float = 0.85
WEAK_SUGGESTION_THRESHOLD: float = 0.60


# ---------------------------------------------------------------------------
# 정규화 (§3.2)
# ---------------------------------------------------------------------------


def normalize_depositor(raw: str) -> str:
    """매칭 비교용 정규화. 원문은 audit 보존 — 이 함수 결과를 저장하지 말 것.

    1. 공백 제거
    2. 한글만 추출 (숫자/영문 제거 — 메모 코드/영문은 별도 신호)
    3. 가족 호칭 접미사 제거 (별도 신호로 처리)

    예시 (§3.2):
    - ``"김지민 어머니"`` → ``"김지민"``
    - ``"0418지민"`` → ``"지민"``
    - ``"이지수아빠"`` → ``"이지수"``
    - ``"KIM JIMIN"`` → ``""`` (영문 제거)
    """
    s = re.sub(r"\s+", "", raw or "")
    s = re.sub(r"[^가-힣]", "", s)
    for suffix in _FAMILY_TITLES:
        if s.endswith(suffix):
            return s[: -len(suffix)]
    return s


def has_family_title(raw: str) -> bool:
    """입금자명에 가족 호칭이 포함되어 있는가 — 정규화 전 한글 부분만 검사."""
    cleaned = re.sub(r"[^가-힣]", "", re.sub(r"\s+", "", raw or ""))
    return any(cleaned.endswith(t) for t in _FAMILY_TITLES)


# ---------------------------------------------------------------------------
# 신호별 점수 계산
# ---------------------------------------------------------------------------


def _levenshtein(a: str, b: str) -> int:
    """Pure Python Levenshtein distance — 짧은 한국어 이름(2~5자)만 비교하므로 충분."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        curr = [i] + [0] * len(b)
        for j, cb in enumerate(b, start=1):
            cost = 0 if ca == cb else 1
            curr[j] = min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
        prev = curr
    return prev[-1]


def score_amount(tx_amount: int, invoice_total: int) -> float:
    """§3.1 amount_exact: ±100원 일치 → 1.0, 부분 입금 → 0.5, 그 외 → 0."""
    if invoice_total <= 0:
        return 0.0
    diff = abs(tx_amount - invoice_total)
    if diff <= 100:
        return 1.0
    if tx_amount < invoice_total:  # 부분 입금 (§7.2)
        return 0.5
    return 0.0  # 초과는 §7.3 별도 처리


def score_name_levenshtein(depositor_raw: str, student_name: str) -> float:
    """§3.1 name_levenshtein: 정규화 후 (1 - dist/max_len)."""
    normalized = normalize_depositor(depositor_raw)
    if not normalized or not student_name:
        return 0.0
    max_len = max(len(normalized), len(student_name))
    if max_len == 0:
        return 0.0
    dist = _levenshtein(normalized, student_name)
    return max(0.0, 1.0 - dist / max_len)


def score_student_name_token(depositor_raw: str, student_name: str) -> float:
    """§3.1/§3.4 학생명 토큰 매칭.

    - 학생 이름 전체가 정규화된 입금자명에 substring → 1.0
    - 학생 이름의 마지막 2글자만 substring (성씨 누락 케이스) → 0.7
    - 그 외 → 0.0
    """
    if len(student_name) < 1:
        return 0.0
    normalized = normalize_depositor(depositor_raw)
    if not normalized:
        return 0.0
    if student_name in normalized:
        return 1.0
    if len(student_name) >= 2 and student_name[-2:] in normalized:
        return 0.7
    return 0.0


def score_family_title(depositor_raw: str, student_name: str) -> float:
    """§3.3 가족 호칭 + 학생 이름 토큰 인접 → 1.0."""
    if not has_family_title(depositor_raw):
        return 0.0
    return 1.0 if score_student_name_token(depositor_raw, student_name) > 0 else 0.0


def score_memo_code(memo_raw: str | None, deposit_code: str | None) -> float:
    """§3.5 memo_raw 에 학생 deposit_code substring → 1.0."""
    if not memo_raw or not deposit_code:
        return 0.0
    return 1.0 if deposit_code in memo_raw else 0.0


def score_time_proximity(tx_at: datetime, invoice_ref_at: datetime | None) -> float:
    """§3.1 입금 시각 ↔ 청구 발송 근접: ≤7d → 1.0 / ≤14d → 0.5 / 그 외 → 0."""
    if invoice_ref_at is None:
        return 0.0
    delta = abs(tx_at - invoice_ref_at)
    if delta <= timedelta(days=7):
        return 1.0
    if delta <= timedelta(days=14):
        return 0.5
    return 0.0


# ---------------------------------------------------------------------------
# 가중 합 (§3.1)
# ---------------------------------------------------------------------------


def compute_match_score(
    *,
    tx_amount: int,
    tx_at: datetime,
    depositor_raw: str,
    memo_raw: str | None,
    invoice_total: int,
    invoice_ref_at: datetime | None,
    student_name: str,
    deposit_code: str | None,
) -> tuple[float, dict[str, float]]:
    """6 신호 가중 합. 반환: (total_score, features dict).

    features 는 ``AcademyPaymentMatchSuggestion.features`` JSON 에 저장 — 학원장이
    매칭 근거를 시각화 (§6.1 ``"✓ 금액일치"``, ``"✓ 가족호칭"`` 등) 할 때 사용.
    """
    features = {
        "amount_exact": score_amount(tx_amount, invoice_total),
        "name_levenshtein": score_name_levenshtein(depositor_raw, student_name),
        "student_name_token": score_student_name_token(depositor_raw, student_name),
        "family_title": score_family_title(depositor_raw, student_name),
        "memo_code": score_memo_code(memo_raw, deposit_code),
        "time_proximity": score_time_proximity(tx_at, invoice_ref_at),
    }
    total = sum(features[k] * WEIGHTS[k] for k in features)
    return total, features


__all__ = [
    "STRONG_SUGGESTION_THRESHOLD",
    "WEAK_SUGGESTION_THRESHOLD",
    "WEIGHTS",
    "compute_match_score",
    "has_family_title",
    "normalize_depositor",
    "score_amount",
    "score_family_title",
    "score_memo_code",
    "score_name_levenshtein",
    "score_student_name_token",
    "score_time_proximity",
]
