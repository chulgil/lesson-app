#!/usr/bin/env python3
"""Keyword detector hook for cg-harness.

UserPromptSubmit 단계에서 사용자 입력을 stdin 으로 받아,
cg-ralph / cg-unstuck / cg-qa 트리거 키워드를 감지하고
원 프롬프트 뒤에 <skill-suggestion> 블록을 덧붙여 stdout 으로 내보낸다.

키워드가 없으면 원본을 그대로 통과시킨다.

Adapted from Q00/ouroboros (MIT).
"""

from __future__ import annotations

import re
import sys

KEYWORD_MAP: list[tuple[tuple[str, ...], str]] = [
    (
        (
            "ralph",
            "계속 돌려",
            "멈추지 마",
            "될 때까지",
            "실패하면 다시",
            "keep going",
            "don't stop",
            "until it works",
        ),
        "cg-ralph",
    ),
    (
        (
            "unstuck",
            "막혔어",
            "i'm stuck",
            "im stuck",
            "i am stuck",
            "think sideways",
            "측면으로 생각",
            "측면 사고",
            "lateral thinking",
        ),
        "cg-unstuck",
    ),
    (
        (
            "qa verdict",
            "quality check",
            "품질 확인",
            "qa 판정",
        ),
        "cg-qa",
    ),
    (
        (
            "drift",
            "드리프트",
            "session status",
            "내가 벗어나고 있나",
            "harness status",
            "상태 보고",
        ),
        "cg-status",
    ),
]


def _word_boundary_match(pattern: str, text: str) -> bool:
    """ASCII 경계 또는 한글 포함 시 서브스트링 매치."""
    if re.search(r"[^\x00-\x7f]", pattern):
        return pattern in text
    return bool(re.search(r"(?:^|\b)" + re.escape(pattern) + r"(?:\b|$)", text))


def detect(text: str) -> tuple[str, str] | None:
    lower = text.lower().strip()
    for patterns, skill in KEYWORD_MAP:
        for pattern in patterns:
            if _word_boundary_match(pattern, lower):
                return skill, pattern
    return None


def main() -> None:
    try:
        user_input = sys.stdin.read()
    except OSError:
        user_input = ""

    stripped = user_input.strip()
    match = detect(stripped) if stripped else None

    if match is None:
        sys.stdout.write(user_input)
        return

    skill, keyword = match
    suggestion = (
        f"\n\n<skill-suggestion>\n"
        f"MATCHED SKILL:\n"
        f'- /{skill} — detected "{keyword}"\n'
        f"</skill-suggestion>\n"
    )
    sys.stdout.write(user_input.rstrip() + suggestion)


if __name__ == "__main__":
    main()
