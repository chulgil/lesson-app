---
name: matt-grill-with-docs
version: 1.0.0
description: "Matt Pocock의 grill-with-docs 패턴을 Lessonaza cg-harness에 맞춘 요구사항 인터뷰 + 유비쿼터스 언어 + ADR 기록 스킬"
last_updated: 2026-05-09
source: "Adapted from mattpocock/skills (MIT): skills/engineering/grill-with-docs"
---

# Matt Grill With Docs

## Purpose

Use this before writing a spec, PRD, issue, or implementation plan. The goal is to remove ambiguity, force domain language into shared docs, and preserve hard decisions as ADRs.

For Lessonaza, write into:

- `.harness/interview/{YYYY-MM-DD}-{slug}.md`
- `.harness/knowledge/glossary.md`
- `docs/specs/glossary.md` when a domain term must be permanent
- `docs/specs/tech_decision.md` or `docs/adr/{NNNN}-{slug}.md` when a durable decision is made
- `.harness/spec/{YYYY-MM-DD}-{slug}.md` when ready for Phase 2

## Hard Gate

Do not implement during this skill. The output is clarified intent, shared vocabulary, and decision records.

## Workflow

### 1. Load Existing Context

Read only the smallest useful set:

- `CLAUDE.md`
- `.harness/README.md`
- `.harness/knowledge/glossary.md`
- `docs/specs/glossary.md`
- relevant `docs/specs/{domain}/**`
- latest `.harness/journal/**`

Summarize what Lessonaza already calls this domain. Prefer existing terms over inventing new names.

### 2. Grill The Request

Ask focused questions until these are clear:

- User role: teacher, parent, student, or admin
- Lesson/subscription/schedule state transition affected
- Source of truth between frontend, backend, and Hive/mock data
- UX edge cases and empty/error/loading states
- Compatibility with existing specs under `docs/specs/`
- Verification evidence expected at the end

Ask one question at a time when interacting with the user. If running autonomously, list assumptions and mark each as `accepted`, `rejected`, or `needs-user`.

### 3. Build Shared Language

Update `.harness/knowledge/glossary.md` first. Promote to `docs/specs/glossary.md` only when the term is stable across features.

Use this shape:

```markdown
## {Term}

- Meaning: ...
- Avoid saying: ...
- Code naming: ...
- Related specs: ...
```

### 4. Capture Durable Decisions

Use `docs/specs/tech_decision.md` for project-wide architecture decisions. Use `docs/adr/{NNNN}-{slug}.md` if ADRs are already active for the touched area.

Do not create ADRs for transient implementation details.

### 5. Produce Interview Output

Write `.harness/interview/{YYYY-MM-DD}-{slug}.md` with:

- request summary
- clarified requirements
- accepted assumptions
- rejected assumptions
- open questions
- glossary updates
- decisions created or touched
- recommended next phase

## Exit Criteria

- no material ambiguity remains, or open questions are explicit
- glossary terms are updated or confirmed unchanged
- durable decisions are captured
- next action is Phase 2 spec or a bounded spike

