#!/usr/bin/env python3
"""LoopDetectionMiddleware for cg-harness.

Tracks repeated edits to the same file and warns the agent to step back instead
of making small variations to the same broken approach.
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path
from typing import Any

STATUS_DIR = Path(".harness/status")
LOOP_FILE = STATUS_DIR / "loop-detection.json"
THRESHOLD = 4
WINDOW_SECONDS = 20 * 60


def _extract_path(payload: dict[str, Any]) -> str | None:
    tool_input = payload.get("tool_input")
    if isinstance(tool_input, dict):
        for key in ("file_path", "path"):
            value = tool_input.get(key)
            if isinstance(value, str) and value:
                return value

    for key in ("file_path", "path"):
        value = payload.get(key)
        if isinstance(value, str) and value:
            return value
    return None


def _load() -> dict[str, Any]:
    if not LOOP_FILE.is_file():
        return {"files": {}}
    try:
        data = json.loads(LOOP_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"files": {}}
    if not isinstance(data, dict):
        return {"files": {}}
    files = data.get("files")
    if not isinstance(files, dict):
        data["files"] = {}
    return data


def main() -> None:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        payload = {}

    path = _extract_path(payload)
    if not path:
        print("Success")
        return

    now = int(time.time())
    STATUS_DIR.mkdir(parents=True, exist_ok=True)
    state = _load()
    files: dict[str, Any] = state["files"]
    entry = files.get(path)
    if not isinstance(entry, dict):
        entry = {"count": 0, "first_seen": now, "last_seen": now}

    if now - int(entry.get("first_seen", now)) > WINDOW_SECONDS:
        entry = {"count": 0, "first_seen": now, "last_seen": now}

    entry["count"] = int(entry.get("count", 0)) + 1
    entry["last_seen"] = now
    files[path] = entry
    state["updated_at"] = now
    LOOP_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")

    if int(entry["count"]) >= THRESHOLD:
        print(
            "[cg-harness] LoopDetectionMiddleware: repeated edits detected for "
            f"{path} ({entry['count']} times). consider reconsidering your approach, "
            "re-read the spec, or use /cg-unstuck."
        )
        return

    print("Success")


if __name__ == "__main__":
    main()
