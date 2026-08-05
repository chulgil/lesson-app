#!/usr/bin/env python3
"""Figma mirror drift check (advisory).

Figma DS 파일은 **코드 → Figma 단방향 미러**다. 코드가 SSOT 이므로 FE UI 가
바뀌면 Figma 는 그만큼 낡는다. 이 훅은 원장(`.harness/status/figma-sync.json`)
에 적힌 `synced_commit` 이후로 쌓인 **UI 변경 커밋 수**를 세어 세션 시작 시
알려준다.

경고만 한다 — stderr 출력 + 항상 exit 0. 무엇을 언제 반영할지는 사람이 정한다.

원장 갱신은 Figma 를 실제로 갱신한 사람이 같은 작업에서 커밋한다.
원장이 없거나 git 이 없으면 조용히 종료한다(신규 클론·CI 방해 금지).
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

LEDGER = ".harness/status/figma-sync.json"

# UI 로 간주하는 경로 — presentation 계층과 테마 토큰만.
# domain/data 변경은 화면 모양을 바꾸지 않으므로 제외한다.
UI_PATHSPECS = [
    "frontend/lib/**/presentation/**",
    "frontend/lib/core/theme/**",
    "frontend/lib/core/widgets/**",
]

NOTICE_COMMITS = 1  # 1건만 밀려도 알린다
LOUD_COMMITS = 5  # 이 이상이면 문구를 강화


def find_project_root(start: Path) -> Path | None:
    for candidate in [start, *start.parents]:
        if (candidate / ".harness").is_dir():
            return candidate
    return None


def git(root: Path, *args: str) -> str | None:
    try:
        out = subprocess.run(
            ["git", *args],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip()


def main() -> None:
    root = find_project_root(Path.cwd())
    if root is None:
        return

    ledger_path = root / LEDGER
    if not ledger_path.is_file():
        return

    try:
        ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return

    synced = (ledger.get("synced_commit") or "").strip()
    if not synced:
        return

    # 기준 커밋이 이 클론에 없으면(shallow/신규) 조용히 종료
    if git(root, "cat-file", "-e", f"{synced}^{{commit}}") is None:
        return

    commits = git(root, "log", "--oneline", f"{synced}..HEAD", "--", *UI_PATHSPECS)
    if commits is None:
        return
    commit_lines = [c for c in commits.splitlines() if c.strip()]
    if len(commit_lines) < NOTICE_COMMITS:
        return

    files = git(root, "diff", "--name-only", f"{synced}..HEAD", "--", *UI_PATHSPECS)
    file_lines = sorted({f for f in (files or "").splitlines() if f.strip()})

    # 영향 feature 를 뽑아 어디를 볼지 바로 알 수 있게 한다
    features = sorted(
        {
            part.split("/")[3]
            for part in file_lines
            if part.startswith("frontend/lib/features/") and len(part.split("/")) > 3
        }
    )

    loud = len(commit_lines) >= LOUD_COMMITS
    head = "밀렸습니다 — 반영을 검토하세요" if loud else "밀렸습니다"

    out = [
        f"[figma-sync] Figma 미러가 UI 커밋 {len(commit_lines)}건 {head}.",
        f"  기준 커밋: {synced[:8]}  (원장: {LEDGER})",
        f"  변경 파일: {len(file_lines)}개",
    ]
    if features:
        out.append(f"  영향 feature: {', '.join(features[:8])}")
    out.append("  미반영 커밋:")
    for line in commit_lines[:5]:
        out.append(f"    - {line}")
    if len(commit_lines) > 5:
        out.append(f"    … 외 {len(commit_lines) - 5}건")
    out.append("  갱신 후에는 원장의 synced_commit 을 같은 작업에서 커밋하세요.")

    for line in out:
        print(line, file=sys.stderr)


if __name__ == "__main__":
    main()
