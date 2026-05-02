#!/usr/bin/env python3
"""Session Start hook for cg-harness.

하네스 상태를 읽어 세션 시작 시 간단한 컨텍스트 배너를 stderr 로 출력한다.
성공 경로는 stdout 를 비워 Claude 컨텍스트 오염을 피한다.

Adapted from Q00/ouroboros (MIT).
"""

from __future__ import annotations

import sys
from pathlib import Path


def find_project_root(start: Path) -> Path | None:
    for parent in [start, *start.parents]:
        if (parent / ".harness").is_dir() or (parent / ".cg").is_dir():
            return parent
    return None


def read_current(root: Path) -> str | None:
    candidate = root / ".harness" / "status" / "current.md"
    if not candidate.is_file():
        return None
    try:
        text = candidate.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return text or None


def main() -> None:
    root = find_project_root(Path.cwd())
    if root is None:
        return

    current = read_current(root)
    if current is None:
        return

    head = "\n".join(current.splitlines()[:10])
    print("[cg-harness] .harness/status/current.md:", file=sys.stderr)
    print(head, file=sys.stderr)


if __name__ == "__main__":
    main()
