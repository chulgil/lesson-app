# Backend Loop Verification Contract

> Status: Active
> Scope: Backend API, DB, migration, and GitHub issue loops
> Updated: 2026-05-07

## Purpose

Long-running backend loops must leave enough evidence that a new API can replace frontend mock data, follows the current architecture, and is safe to ship. This contract captures the repeatable process learned from the backend issue loop around schedule, onboarding, subscription, and notification APIs.

## Loop Contract

| Step | Rule |
|------|------|
| Issue | Create or identify one GitHub issue before coding. Close it only after commit, push, and verification evidence are posted. |
| Scope | Keep backend work scoped to `backend/` and required spec or harness files. Do not stage unrelated frontend or generated changes. |
| Spec check | Compare frontend repository contracts, domain entities, and existing specs before adding an API. Reuse existing endpoints when they already cover the contract. |
| DB design | Treat PostgreSQL and Alembic as the product database contract. SQLite-compatible test runs are useful only as migration smoke checks. |
| TDD | Add a failing API or migration contract test first for new backend behavior. Record the RED failure reason in the issue comment. |
| Architecture | Preserve FastAPI route -> service -> model boundaries. Keep role and ownership checks in service logic or shared dependencies. |
| Migration | Add Alembic revisions for schema changes and confirm the project has a single expected head. |
| Verification | Run targeted tests, lint, relevant architecture tests, Alembic head checks, and full backend pytest before claiming completion. |
| Evidence | Post commands, pass counts, RED/GREEN notes, and commit SHA to the GitHub issue before closing. |
| Parallel agents | Use coding agents for independent investigation or disjoint file ownership. Run full backend pytest in one main workspace after integration. |

## Mock Replacement Checklist

- The frontend mock repository has a matching remote repository or a documented backend endpoint.
- Request and response fields round-trip every frontend domain field that is not explicitly derived locally.
- Role-specific behavior is covered for teacher, student, and parent where applicable.
- Red-dot, unread, confirmation, payment status, and schedule change state are persisted server-side, not inferred only in UI state.
- Pagination, filtering, and ownership constraints are specified where list APIs can grow.
- API tests verify default creation behavior when the frontend expects settings to exist before the user edits them.
- DB constraints encode natural uniqueness where business rules require one active row or one user-scoped preference.

## Completion Gate

Before committing a backend loop, confirm:

- `uv run ruff check ...` passes for touched backend files.
- Targeted pytest for the changed behavior passes.
- Relevant architecture or contract tests pass.
- `uv run alembic heads` reports the expected head.
- `uv run pytest -q` passes unless a documented external blocker exists.
- `git diff --cached --check` passes.
- `git diff --cached --stat` contains only intended files.

## Issue Comment Template

```text
Implemented <feature> and pushed commit <sha>.

Verification:
- RED: <test command or case> first failed with <reason>.
- GREEN: <targeted pytest command> -> <pass count>.
- Lint: <ruff command> -> All checks passed.
- Regression: <contract or architecture command> -> <pass count>.
- Migration: uv run alembic heads -> <head>.
- Full backend suite: uv run pytest -q -> <pass count>.
```
