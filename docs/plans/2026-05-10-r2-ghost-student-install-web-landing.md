# R2 Ghost Student Install Web Landing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the old FastAPI Jinja2 landing idea with a Ghost-rendered student install landing and backend public data APIs.

**Architecture:** Ghost on `lessonaza.com` owns public HTML, SEO, and Kakao preview rendering. FastAPI owns invite validation, lesson summary share-token issuance, read-only summary data, and audit fields. Public API responses must expose only minimum fields and keep all business logic in service classes.

**Tech Stack:** FastAPI 0.115+, SQLAlchemy 2 async, PostgreSQL 17, Alembic, Pydantic v2, Ghost theme customization, Flutter deep links.

---

## References

- Primary spec: `docs/specs/lesson/invite/student_install_web_landing_spec.md`
- Invite spec: `docs/specs/lesson/invite/invite_system_v2.md`
- Backend spec: `docs/specs/backend/backend_spec.md`
- Current backend invite code: `backend/app/api/v1/invites.py`, `backend/app/services/invite_service.py`, `backend/app/models/invite.py`

## Task 1: Public Invite Landing Contract

**Files:**
- Create: `backend/app/api/v1/public.py`
- Create: `backend/app/schemas/public_landing.py`
- Create: `backend/app/services/public_landing_service.py`
- Modify: `backend/app/api/v1/__init__.py`
- Test: `backend/tests/test_public_invite_landing.py`

**Step 1: Write the failing tests**

Test cases:
- valid invite code returns 200 without auth
- unknown invite code returns 404
- expired/revoked/used invite returns 410
- response includes `teacher.name`, `teacher.instrument`, `share.url`, `share.app_deep_link`
- response does not include email, phone number, internal notes, payment fields

**Step 2: Run test to verify it fails**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_public_invite_landing.py -q
```

Expected: fail because `/api/v1/public/invites/{code}/landing` does not exist.

**Step 3: Implement minimal service/router/schema**

Implementation notes:
- Router prefix: `/api/v1/public`
- Router delegates all DB work to `PublicLandingService`.
- Service resolves `Invite` by uppercase code.
- Service validates `InviteStatus.active`, `expires_at > now`, and usage limits.
- Teacher instrument should be resolved from teacher/student domain if present. If current data is absent, return `null` rather than guessing.
- Build URLs from settings, with default public web base `https://lessonaza.com`.

**Step 4: Run focused tests**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_public_invite_landing.py -q
```

Expected: pass.

**Step 5: Commit**

```bash
git add backend/app/api/v1/public.py backend/app/schemas/public_landing.py backend/app/services/public_landing_service.py backend/app/api/v1/__init__.py backend/tests/test_public_invite_landing.py
git commit -m "초대 공개 랜딩 API 추가"
```

## Task 2: Lesson Summary Share Token DB Model

**Files:**
- Create: `backend/app/models/lesson_summary_share_token.py`
- Create: `backend/alembic/versions/20260510_1300_add_lesson_summary_share_tokens.py`
- Modify: `backend/app/models/__init__.py`
- Test: `backend/tests/test_lesson_summary_share_tokens.py`

**Step 1: Write the failing tests**

Test cases:
- token row stores `token_hash`, not raw token
- `access_count` cannot be negative
- `expires_at` is required
- model metadata includes FK from `lesson_id` to `lessons.id`
- model metadata includes FK from `teacher_id` to `users.id`

**Step 2: Run test to verify it fails**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_lesson_summary_share_tokens.py -q
```

Expected: fail because model/table does not exist.

**Step 3: Add model and migration**

Model columns:
- `id`
- `lesson_id`
- `teacher_id`
- `student_id`
- `token_hash`
- `expires_at`
- `revoked_at`
- `last_accessed_at`
- `access_count`
- timestamps

Constraints:
- unique `token_hash`
- `access_count >= 0`
- indexes on `lesson_id`, `teacher_id`, `expires_at`

**Step 4: Run model and migration tests**

Run:

```bash
cd backend
ALEMBIC_DATABASE_URL=sqlite+aiosqlite:////private/tmp/lesson_app_summary_token_contract.db uv run --python /opt/homebrew/bin/python3.12 alembic upgrade head
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_lesson_summary_share_tokens.py -q
```

Expected: pass.

**Step 5: Commit**

```bash
git add backend/app/models/lesson_summary_share_token.py backend/app/models/__init__.py backend/alembic/versions/20260510_1300_add_lesson_summary_share_tokens.py backend/tests/test_lesson_summary_share_tokens.py
git commit -m "레슨 요약 공유 토큰 테이블 추가"
```

## Task 3: Lesson Summary Share API

**Files:**
- Create: `backend/app/schemas/lesson_summary_share.py`
- Create: `backend/app/services/lesson_summary_share_service.py`
- Modify: `backend/app/api/v1/lessons.py`
- Test: `backend/tests/test_lesson_summary_share_api.py`

**Step 1: Write the failing tests**

Test cases:
- owning teacher can create a share token
- non-owning teacher gets 403
- missing lesson gets 404
- response has Ghost web URL, app deep link, expiry, Korean share text
- share text includes teacher name and instrument when available
- raw token is returned once in response but only hash is persisted

**Step 2: Run test to verify it fails**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_lesson_summary_share_api.py -q
```

Expected: fail because `POST /api/v1/lesson-summaries/{lesson_id}/share` does not exist.

**Step 3: Implement minimal API**

Implementation notes:
- Endpoint may live in a new router or existing lessons router, but path must match the spec.
- Router delegates to `LessonSummaryShareService`.
- Generate an opaque token with `secrets.token_urlsafe`.
- Persist SHA-256 hash only.
- Default expiry is 24 hours.
- URL base should be configurable, defaulting to `https://lessonaza.com`.

**Step 4: Run focused tests**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_lesson_summary_share_api.py -q
```

Expected: pass.

**Step 5: Commit**

```bash
git add backend/app/schemas/lesson_summary_share.py backend/app/services/lesson_summary_share_service.py backend/app/api/v1/lessons.py backend/tests/test_lesson_summary_share_api.py
git commit -m "레슨 요약 공유 API 추가"
```

## Task 4: Public Student Summary API

**Files:**
- Modify: `backend/app/api/v1/public.py`
- Modify: `backend/app/schemas/public_landing.py`
- Modify: `backend/app/services/public_landing_service.py`
- Test: `backend/tests/test_public_student_summary.py`

**Step 1: Write the failing tests**

Test cases:
- valid token returns public summary without auth
- expired token returns 410
- revoked token returns 410
- unknown token returns 404
- successful read increments `access_count`
- successful read updates `last_accessed_at`
- response excludes payment/contact/internal memo fields

**Step 2: Run test to verify it fails**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_public_student_summary.py -q
```

Expected: fail because `/api/v1/public/student-summaries/{token}` does not exist.

**Step 3: Implement minimal read API**

Implementation notes:
- Hash incoming token and find `LessonSummaryShareToken`.
- Validate expiry/revocation.
- Join/read lesson, teacher, student, lesson note/homework fields using existing models.
- Keep summary fields conservative if source columns are absent.
- Increment audit fields in the same transaction.

**Step 4: Run focused tests**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_public_student_summary.py -q
```

Expected: pass.

**Step 5: Commit**

```bash
git add backend/app/api/v1/public.py backend/app/schemas/public_landing.py backend/app/services/public_landing_service.py backend/tests/test_public_student_summary.py
git commit -m "학생 레슨 요약 공개 조회 API 추가"
```

## Task 5: Architecture and Documentation Verification

**Files:**
- Modify: `docs/specs/backend/backend_spec.md`
- Modify: `backend/tests/test_backend_architecture_contract.py` if a new router pattern needs an explicit allow/deny rule

**Step 1: Add contract documentation**

Document:
- Ghost owns `/invite/{code}` and `/student/{token}/summary` HTML.
- Backend owns `/api/v1/public/*` data.
- No FastAPI Jinja2 templates for this issue.
- Admin API keys are server-only.

**Step 2: Run verification**

Run:

```bash
cd backend
uv run --python /opt/homebrew/bin/python3.12 ruff check app tests
uv run --python /opt/homebrew/bin/python3.12 python -m pytest tests/test_backend_architecture_contract.py -q
uv run --python /opt/homebrew/bin/python3.12 python -m pytest -q
```

Expected: all pass.

**Step 3: Commit and push**

```bash
git add docs/specs/backend/backend_spec.md backend/tests/test_backend_architecture_contract.py
git commit -m "Ghost 학생 랜딩 백엔드 계약 문서화"
git push
```
