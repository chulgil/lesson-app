---
name: matt-zoom-out
version: 1.0.0
description: "Matt Pocock의 zoom-out 패턴을 Lessonaza에 맞춘 시스템 맥락 설명 스킬"
last_updated: 2026-05-09
source: "Adapted from mattpocock/skills (MIT): skills/engineering/zoom-out"
---

# Matt Zoom Out

## Purpose

Use this when a file, module, bug, or feature feels locally understandable but Lessonaza system context is missing. The output is a concise explanation of how the current area fits into the larger app.

## Inputs To Read

Prefer this order:

1. The file or module under discussion
2. Nearby tests
3. `CLAUDE.md`
4. relevant `docs/specs/{domain}/**`
5. `.harness/knowledge/glossary.md`
6. `docs/specs/glossary.md`
7. relevant architecture docs

Do not scan the whole repository unless the local context is insufficient.

## Output Shape

```markdown
## Zoomed Out View

### What This Area Is For

### Upstream Callers

### Downstream Dependencies

### Domain Terms In Play

### Invariants To Preserve

### Likely Change Boundary

### Verification To Trust
```

## Lessonaza Rules

- Explain the system, do not edit code.
- Preserve feature-first Clean Architecture: `presentation -> domain <- data`.
- Call out whether the touched area affects teacher, parent, student, schedule, lesson, subscription, or practice flows.
- Prefer terms from `.harness/knowledge/glossary.md` and `docs/specs/glossary.md`.
- If the module boundary looks wrong, propose an architecture follow-up instead of mixing refactor work into the current task.

