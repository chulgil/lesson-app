---
name: matt-to-issues
version: 1.0.0
description: "Matt Pocock의 to-issues/to-prd 패턴을 Lessonaza spec과 로컬 이슈 파일로 변환하는 스킬"
last_updated: 2026-05-09
source: "Adapted from mattpocock/skills (MIT): skills/engineering/to-issues and skills/engineering/to-prd"
---

# Matt To Issues

## Purpose

Turn a clarified plan, PRD, or `.harness/spec` into small vertical slices that can be implemented independently. Each issue must have user-visible value, clear acceptance criteria, and verification evidence.

## Inputs

Read:

- `.harness/spec/{feature}.md` or current PRD
- `.harness/interview/{feature}.md` when available
- `.harness/knowledge/glossary.md`
- `docs/specs/{domain}/**`
- `docs/specs/glossary.md`

## Output Location

If the task is tracked in GitHub Issues, prepare issue bodies for `gh issue create`.

If not, write local files:

- `.harness/issues/{YYYY-MM-DD}-{feature}-{NN}.md`

Create `.harness/issues/` if it does not exist.

## Issue Template

```markdown
# {User-visible slice}

## Outcome

## Scope

## Out Of Scope

## Acceptance Criteria

- [ ] ...

## Verification

- Command:
- Expected evidence:

## Dependencies

## Notes
```

## Lessonaza Slicing Rules

- Slice vertically through teacher/parent/student workflows, not horizontally by Flutter layer.
- Keep backend contract changes separate from pure presentation changes when rollback risk differs.
- Include empty, loading, error, and permission states when UI is touched.
- Include spec sync work when code changes affect `docs/specs/**`.
- Each issue should be independently testable with `flutter analyze`, targeted widget tests, architecture tests, or backend scenario tests.

## Exit Criteria

- Every acceptance criterion maps to a verification command or review artifact.
- Dependencies form a DAG, not a cycle.
- The first issue can start without requiring all later design questions to be solved.
- Any unresolved ambiguity is listed in the issue, not hidden in prose.

