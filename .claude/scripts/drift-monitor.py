#!/usr/bin/env python3
"""Drift monitor — docs/specs ↔ 코드 동기화 추적 (lesson-app 적응판).

PostToolUse (Write|Edit) 단계에서 docs/specs 의 모든 *.md 파일을 SHA1
해시로 스냅샷 비교하여 변경을 추적한다. 결과는
`.claude/harness-signals/drift.json` 에 적재된다.

이 훅은 데이터를 적재만 하고 사람이 읽는 리포트는 별도 도구가 같은
파일을 읽어 생성한다. 기존 `check-doc-sync.sh` 와 보완 관계 — 이 쪽은
변경 이력 추적, 저쪽은 매핑 안내.

Adapted from cg-harness/Q00-ouroboros (Apache-2.0/MIT).
"""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path

SPEC_DIR = "docs/specs"
SIGNAL_DIR = ".claude/harness-signals"
DRIFT_FILE = "drift.json"
FRESH_SECONDS = 5 * 60


def find_project_root(start: Path) -> Path | None:
    """lesson-app 루트 탐색 — pubspec.yaml 또는 frontend/pubspec.yaml 으로 식별."""
    for parent in [start, *start.parents]:
        if (parent / "pubspec.yaml").is_file():
            return parent
        if (parent / "frontend" / "pubspec.yaml").is_file():
            return parent
        if (parent / "CLAUDE.md").is_file() and (parent / "docs").is_dir():
            return parent
    return None


def hash_markdown_files(base: Path) -> dict[str, str]:
    """base 아래 모든 *.md 의 SHA1 해시 맵."""
    hashes: dict[str, str] = {}
    if not base.is_dir():
        return hashes
    for path in sorted(base.rglob("*.md")):
        try:
            data = path.read_bytes()
        except OSError:
            continue
        rel = str(path.relative_to(base.parent))
        hashes[rel] = hashlib.sha1(data).hexdigest()
    return hashes


def newest_mtime(path: Path) -> float:
    if not path.exists():
        return 0.0
    newest = 0.0
    for item in path.rglob("*"):
        if item.is_file():
            mtime = item.stat().st_mtime
            if mtime > newest:
                newest = mtime
    return newest


def main() -> None:
    root = find_project_root(Path.cwd())
    if root is None:
        # 프로젝트 외부에서 호출되면 조용히 종료 (편집을 막지 않음)
        print("Success")
        return

    now = time.time()
    spec_dir = root / SPEC_DIR
    signal_dir = root / SIGNAL_DIR
    signal_dir.mkdir(parents=True, exist_ok=True)
    drift_path = signal_dir / DRIFT_FILE

    current_hashes = hash_markdown_files(spec_dir)

    previous: dict = {}
    if drift_path.is_file():
        try:
            previous = json.loads(drift_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            previous = {}

    prev_hashes: dict[str, str] = previous.get("hashes", {})
    changed = sorted(
        path
        for path, digest in current_hashes.items()
        if prev_hashes.get(path) != digest
    )
    added = sorted(p for p in current_hashes if p not in prev_hashes)
    removed = sorted(p for p in prev_hashes if p not in current_hashes)

    # 도메인별 변경 카운트 — F-패턴 진입점
    # hash_markdown_files 가 base.parent 기준 상대경로를 저장하므로
    # 경로는 "specs/<domain>/<file>.md" 형태
    by_domain: dict[str, int] = {}
    for p in changed:
        parts = Path(p).parts
        if len(parts) >= 3 and parts[0] == "specs":
            by_domain[parts[1]] = by_domain.get(parts[1], 0) + 1

    summary = {
        "changed_total": len(changed),
        "added": len(added),
        "removed": len(removed),
        "domains_touched": sorted(by_domain.keys()),
        "domain_counts": by_domain,
    }

    payload = {
        "updated_at": int(now),
        "updated_at_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
        "spec_dir": SPEC_DIR,
        "hashes": current_hashes,
        "changed": changed,
        "added": added,
        "removed": removed,
        "summary": summary,
    }
    drift_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if changed or added or removed:
        domains = ", ".join(by_domain.keys()) if by_domain else "—"
        print(
            f"[drift] spec 변경 {len(changed)}건, 신규 {len(added)}, "
            f"삭제 {len(removed)}. 도메인: {domains}. "
            f"코드 동기화 누락 여부 점검 권장."
        )
        return

    print("Success")


if __name__ == "__main__":
    main()
