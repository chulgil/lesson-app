# Backend Remote API Gap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the remaining frontend `EnvironmentConfig.useMockData` repository exceptions by filling the backend API and DB gaps needed for real remote repositories.

**Architecture:** Treat the Flutter domain repository interfaces as client contracts, but keep server ownership in FastAPI services, Pydantic schemas, SQLAlchemy models, and Alembic migrations. Prioritize endpoints that replace mock fallbacks without broad product changes: schedule confirmation cards, parent child profiles, practice library/repertoire/notes, and tuition deposit records.

**Tech Stack:** FastAPI, SQLAlchemy async ORM, Alembic, Pydantic v2, pytest, ruff, Flutter repository contract checks.

---

## Current Backend-Relevant Gaps

Frontend exceptions currently allowed in `frontend/test/architecture/layer_boundaries_test.dart`:

- `lib/features/lessons/presentation/providers/payment_repository_provider.dart`
- `lib/features/parent_home/presentation/providers/child_profile_provider.dart`
- `lib/features/practice/presentation/providers/piece_repository_provider.dart`
- `lib/features/practice/presentation/providers/practice_note_provider.dart`
- `lib/features/practice/presentation/providers/practice_repertoire_repository_provider.dart`
- `lib/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart`

Backend status:

- Schedule confirmation cards exist at `/api/v1/schedule/confirmation-cards`, but schema names do not match the Flutter card contract (`proposed_*` vs `suggested*`, `title` required, missing direct subscription lookup/dismiss-all convenience).
- Parent relations exist at `/api/v1/parents/me/children`, but the frontend child profile contract expects child-profile shaped data and teacher connect/disconnect operations.
- Practice repertoires/sections/notes partially exist under `/api/v1/practice`, but frontend expects a richer repertoire API, direct note CRUD, piece library CRUD/search, section order/update helpers, recordings metadata, and assignment helpers.
- `Payment`/`TuitionSettings` models exist, but backend intentionally has no `/payments` API. This should remain blocked until a billing product decision is made, or be limited to legacy tuition deposit tracking with explicit naming.

---

## Task 1: Open Tracking Issues and Freeze the Backend Contract

**Files:**
- Read: `frontend/test/architecture/layer_boundaries_test.dart`
- Read: `frontend/lib/features/lessons/domain/repositories/payment_repository.dart`
- Read: `frontend/lib/features/parent_home/domain/repositories/child_profile_repository.dart`
- Read: `frontend/lib/features/practice/domain/repositories/piece_repository.dart`
- Read: `frontend/lib/features/practice/domain/repositories/practice_note_repository.dart`
- Read: `frontend/lib/features/practice/domain/repositories/practice_repertoire_repository.dart`
- Read: `frontend/lib/features/schedule/domain/repositories/schedule_confirmation_card_repository.dart`
- Create: GitHub issues, one per backend slice

**Step 1: Create backend issues**

Run:

```bash
gh issue create --title "백엔드 스케줄 확인 카드 원격 계약 정렬" --body "Flutter schedule confirmation card provider의 mock fallback 제거를 위한 backend API/schema 정렬."
gh issue create --title "백엔드 부모 자녀 프로필 원격 계약 보강" --body "ChildProfileRepository mock fallback 제거를 위한 parent-child profile API 보강."
gh issue create --title "백엔드 연습 곡/레퍼토리/노트 원격 API 보강" --body "Practice piece/repertoire/note mock fallback 제거를 위한 backend API/DB 보강."
gh issue create --title "백엔드 레거시 수강료 입금 API 정책 결정" --body "PaymentRepository mock fallback은 결제 제품 정책 미확정 상태라 API 구현 또는 명시적 보류를 결정."
```

**Step 2: Add a backend contract test scaffold**

Create `backend/tests/test_frontend_remote_gap_contract.py`.

Test target:

```python
def test_backend_exposes_remote_gap_candidate_routes(client):
    response = client.get("/api/v1/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/schedule/confirmation-cards" in paths
    assert "/api/v1/parents/me/children" in paths
    assert "/api/v1/practice/repertoires" in paths
```

**Step 3: Run the scaffold**

Run:

```bash
cd backend && uv run pytest tests/test_frontend_remote_gap_contract.py -q
```

Expected: PASS for existing routes. Add TODO assertions only after each slice defines exact new paths.

**Step 4: Commit**

```bash
git add backend/tests/test_frontend_remote_gap_contract.py
git commit -m "test: capture frontend remote api gaps"
```

---

## Task 2: Align Schedule Confirmation Card API With Flutter Contract

**Why first:** Backend already has most of this feature. This is the smallest backend change that can remove a frontend mock exception.

**Files:**
- Modify: `backend/app/schemas/schedule_confirmation.py`
- Modify: `backend/app/services/schedule_confirmation_service.py`
- Modify: `backend/app/api/v1/schedule_confirmations.py`
- Test: `backend/tests/test_schedule_confirmation_cards.py`

**Backend contract to support:**

- `GET /api/v1/schedule/confirmation-cards?student_id={id}&status=pending`
- `GET /api/v1/schedule/confirmation-cards/{card_id}`
- `GET /api/v1/schedule/confirmation-cards/by-subscription/{subscription_id}`
- `POST /api/v1/schedule/confirmation-cards`
- `PATCH /api/v1/schedule/confirmation-cards/{card_id}/status`
- `POST /api/v1/schedule/confirmation-cards/dismiss-all`

**Step 1: Write failing tests**

Add tests that assert:

- Student sees only own pending cards.
- Parent with active relation sees child pending cards.
- Teacher sees only cards they created.
- `by-subscription` returns the matching card or 404.
- `dismiss-all` only dismisses cards visible to the current actor.
- Response includes Flutter-friendly aliases:
  - `suggestedDay`
  - `suggestedTime`
  - `lessonDuration`
  - `suggestedDay2`
  - `suggestedTime2`
  - `suggestedDay3`
  - `suggestedTime3`

Run:

```bash
cd backend && uv run pytest tests/test_schedule_confirmation_cards.py -q
```

Expected: FAIL because aliases/convenience endpoints are missing.

**Step 2: Implement schema aliases**

In `ScheduleConfirmationCardResponse`, add computed/serialized fields that map current DB fields:

- `proposed_day` -> `suggestedDay`
- `proposed_time` -> `suggestedTime`
- `proposed_duration` -> `lessonDuration`
- first three `proposed_slots` entries -> `suggestedDay*` and `suggestedTime*`
- same values as snake_case `suggested_day`, `suggested_time`, `lesson_duration`,
  `suggested_day2/3`, and `suggested_time2/3` for Flutter generated JSON
- `teacher_name` resolved from either `users.id` or `teachers.id`

Do not rename DB columns in this task.

**Step 3: Implement service helpers**

Add methods:

- `get_card_by_subscription_id(subscription_id, current_user)`
- `update_card_status(card_id, status, responded_at, current_user)`
- `dismiss_all_pending(student_id, current_user)`

Use the existing `_can_access` logic, but extend it to allow parents with active `ParentChildRelation`.
Teacher access must accept both auth user id and linked Teacher profile id because subscription issuance
stores profile ids while direct card creation may store user ids.

**Step 3-1: Guard booking materialization**

When a card is confirmed, create bookings only if no other card for the same `subscription_id` is already
confirmed. This keeps the endpoint safe when frontend and backend both surface confirmation flows or duplicate
cards are created during retries.

**Step 4: Run tests**

```bash
cd backend && uv run pytest tests/test_schedule_confirmation_cards.py -q
cd backend && uv run pytest tests/test_parent_api_spec_alignment.py tests/test_subscriptions.py -q
cd backend && uv run ruff check app/schemas/schedule_confirmation.py app/services/schedule_confirmation_service.py app/api/v1/schedule_confirmations.py tests/test_schedule_confirmation_cards.py
```

Expected: all pass.

**Step 5: Commit**

```bash
git add backend/app/schemas/schedule_confirmation.py backend/app/services/schedule_confirmation_service.py backend/app/api/v1/schedule_confirmations.py backend/tests/test_schedule_confirmation_cards.py
git commit -m "feat: align schedule confirmation card api"
```

---

## Task 3: Add Parent Child Profile Remote Contract

**Why second:** Parent-child visibility already exists, but frontend needs child-profile shaped CRUD and teacher connect/disconnect semantics.

**Files:**
- Modify: `backend/app/schemas/parent.py`
- Modify: `backend/app/services/parent_service.py`
- Modify: `backend/app/api/v1/parents.py`
- Test: `backend/tests/test_parent_child_profiles.py`

**Backend contract to support:**

- `GET /api/v1/parents/{parent_id}/child-profiles`
- `GET /api/v1/parents/child-profiles/{child_id}`
- `POST /api/v1/parents/child-profiles`
- `PUT /api/v1/parents/child-profiles/{child_id}`
- `DELETE /api/v1/parents/child-profiles/{child_id}`
- `POST /api/v1/parents/child-profiles/{child_id}/teacher`
- `DELETE /api/v1/parents/child-profiles/{child_id}/teacher`

**Step 1: Write failing tests**

Assert:

- Parent can list only active linked children.
- Parent cannot read/update an unrelated child.
- Soft delete unlinks or inactivates relation without deleting `students`.
- Teacher connect requires a real teacher and active parent-child relation.
- Disconnect removes only the requested teacher relation or membership link.

Run:

```bash
cd backend && uv run pytest tests/test_parent_child_profiles.py -q
```

Expected: FAIL because child-profile endpoints are missing.

**Step 2: Add schemas**

Add:

- `ChildProfileResponse`
- `ChildProfileCreate`
- `ChildProfileUpdate`
- `ChildTeacherConnectRequest`

Response should be derived from `Student` plus relation metadata:

- `id`
- `name`
- `birth_date`
- `profile_image_url`
- `profile_color`
- `status`
- `parent_id`
- `teacher_id`
- `teacher_name`
- `linked_at`

**Step 3: Implement service methods**

Use existing `ParentChildRelation`, `Student`, `Teacher`, and relationship/membership tables. Do not create a second child table.

Methods:

- `get_child_profiles(parent_id, current_user)`
- `get_child_profile(child_id, current_user)`
- `create_child_profile(body, current_user)`
- `update_child_profile(child_id, body, current_user)`
- `delete_child_profile(child_id, current_user)`
- `connect_teacher_to_child(child_id, body, current_user)`
- `disconnect_teacher_from_child(child_id, current_user)`

**Step 4: Run tests**

```bash
cd backend && uv run pytest tests/test_parent_child_profiles.py tests/test_parent_api_spec_alignment.py tests/test_parents.py -q
cd backend && uv run ruff check app/schemas/parent.py app/services/parent_service.py app/api/v1/parents.py tests/test_parent_child_profiles.py
```

Expected: all pass.

**Step 5: Commit**

```bash
git add backend/app/schemas/parent.py backend/app/services/parent_service.py backend/app/api/v1/parents.py backend/tests/test_parent_child_profiles.py
git commit -m "feat: add parent child profile api"
```

---

## Task 4: Add Practice Piece Library API

**Why third:** `PieceRepository` has no clear backend equivalent. This needs DB/API work but is smaller than the full repertoire repository.

**Files:**
- Modify: `backend/app/models/practice.py`
- Modify: `backend/app/schemas/practice.py`
- Modify: `backend/app/services/practice_service.py`
- Modify: `backend/app/api/v1/practice.py`
- Create: `backend/alembic/versions/YYYYMMDD_HHMM_add_practice_pieces.py`
- Test: `backend/tests/test_practice_pieces.py`

**DB model:**

Add `PracticePiece`:

- `id`
- `owner_teacher_id`, nullable for shared/system library if needed
- `title`
- `composer`
- `opus`
- `movement`
- `difficulty`
- `notes`
- `created_at`
- `updated_at`

Add student assignment table `StudentPracticePiece`:

- `id`
- `student_id`
- `piece_id`
- `progress`
- `progress_percentage`
- `started_at`
- `completed_at`
- unique `(student_id, piece_id)`

**API contract:**

- `GET /api/v1/practice/pieces`
- `GET /api/v1/practice/pieces/{piece_id}`
- `POST /api/v1/practice/pieces`
- `PUT /api/v1/practice/pieces/{piece_id}`
- `DELETE /api/v1/practice/pieces/{piece_id}`
- `GET /api/v1/practice/pieces/search?q={query}`
- `GET /api/v1/practice/students/{student_id}/repertoire`
- `POST /api/v1/practice/students/{student_id}/pieces/{piece_id}`
- `DELETE /api/v1/practice/students/{student_id}/pieces/{piece_id}`
- `PATCH /api/v1/practice/students/{student_id}/pieces/{piece_id}/progress`

**Step 1: Write failing tests**

Assert:

- Teacher can CRUD own pieces.
- Search filters by title/composer.
- Teacher can assign a piece only to a student they teach.
- Student can read own repertoire.
- Parent can read linked child repertoire.
- Duplicate assignment is idempotent or returns 409 consistently.

Run:

```bash
cd backend && uv run pytest tests/test_practice_pieces.py -q
```

Expected: FAIL because models/routes are missing.

**Step 2: Add model and migration**

Use explicit indexes:

- `idx_practice_piece_owner`
- `idx_student_piece_student`
- `uk_student_piece`

Include FK constraints to `teachers.id`, `students.id`, and `practice_pieces.id`.

**Step 3: Add schemas and service**

Keep response JSON field names compatible with Flutter:

- `progressPercentage`
- `startedAt`
- `completedAt`
- `createdAt`
- `updatedAt`

**Step 4: Run tests**

```bash
cd backend && uv run pytest tests/test_practice_pieces.py tests/test_practice.py -q
cd backend && uv run ruff check app/models/practice.py app/schemas/practice.py app/services/practice_service.py app/api/v1/practice.py tests/test_practice_pieces.py
```

Expected: all pass.

**Step 5: Commit**

```bash
git add backend/app/models/practice.py backend/app/schemas/practice.py backend/app/services/practice_service.py backend/app/api/v1/practice.py backend/alembic/versions/*add_practice_pieces.py backend/tests/test_practice_pieces.py
git commit -m "feat: add practice piece library api"
```

---

## Task 5: Complete Practice Repertoire, Section, Note, and Recording Remote API

**Why fourth:** This is the largest slice. It should build on the existing `practice_repertoires`, `practice_sections`, `practice_notes`, and `practice_recordings` tables instead of replacing them.

**Files:**
- Modify: `backend/app/models/practice.py`
- Modify: `backend/app/schemas/practice.py`
- Modify: `backend/app/services/practice_service.py`
- Modify: `backend/app/api/v1/practice.py`
- Create: `backend/alembic/versions/YYYYMMDD_HHMM_align_practice_repertoire_remote_contract.py`
- Test: `backend/tests/test_practice_repertoire_remote_contract.py`
- Test: `backend/tests/test_practice_notes.py`

**API additions:**

- `PATCH /api/v1/practice/repertoires/{id}/archive`
- `PATCH /api/v1/practice/repertoires/{id}/restore`
- `DELETE /api/v1/practice/repertoires/{id}/permanent`
- `GET /api/v1/practice/sections/{section_id}`
- `PATCH /api/v1/practice/sections/{section_id}/daily-completion`
- `PATCH /api/v1/practice/sections/{section_id}/repeat`
- `PATCH /api/v1/practice/sections/{section_id}/practice-count`
- `PATCH /api/v1/practice/sections/{section_id}/last-practiced-at`
- `PUT /api/v1/practice/repertoires/{id}/section-orders`
- `GET /api/v1/practice/sections/{section_id}/notes`
- `POST /api/v1/practice/sections/{section_id}/notes`
- `PUT /api/v1/practice/notes/{note_id}`
- `DELETE /api/v1/practice/notes/{note_id}`
- `POST /api/v1/practice/recordings`
- `DELETE /api/v1/practice/recordings/{recording_id}`
- `PATCH /api/v1/practice/sections/{section_id}/representative-recording`
- `GET /api/v1/practice/recordings/orphaned`
- `PATCH /api/v1/practice/recordings/{recording_id}/reassign`
- `GET /api/v1/practice/students/{student_id}/sections-with-repertoire`
- `GET /api/v1/practice/recordings/with-section-info`

**Step 1: Write failing tests**

Focus tests on backend-owned behavior:

- Archive/restore/permanent delete.
- Section order update persists sort order.
- Daily completion toggles date-specific status.
- Repeat toggle and practice-count increment update counters atomically.
- Note CRUD enforces section ownership.
- Recording metadata CRUD enforces section/student access.
- Parent with linked child can read, but cannot mutate unless product decision allows it.

Run:

```bash
cd backend && uv run pytest tests/test_practice_repertoire_remote_contract.py tests/test_practice_notes.py -q
```

Expected: FAIL because endpoints and response shape are incomplete.

**Step 2: Add missing columns if needed**

Current model already has many frontend fields. Add only fields proven missing by tests, likely:

- `PracticeSection.youtube_url`
- `PracticeSection.youtube_video_id`
- `PracticeSection.youtube_start_seconds`
- `PracticeSection.youtube_end_seconds`
- `PracticeSection.teaching_resource_ids`
- `PracticeSection.assigned_by_teacher_id`
- `PracticeSection.practice_item_id`

Add FK constraints where applicable.

**Step 3: Implement service methods**

Keep mutation methods transactional and authorization-first:

- resolve section -> repertoire -> student
- check teacher/student/linked-parent access
- mutate
- flush/refresh
- return Pydantic response

**Step 4: Run tests**

```bash
cd backend && uv run pytest tests/test_practice_repertoire_remote_contract.py tests/test_practice_notes.py tests/test_practice.py tests/test_recordings.py -q
cd backend && uv run ruff check app/models/practice.py app/schemas/practice.py app/services/practice_service.py app/api/v1/practice.py tests/test_practice_repertoire_remote_contract.py tests/test_practice_notes.py
```

Expected: all pass.

**Step 5: Commit**

```bash
git add backend/app/models/practice.py backend/app/schemas/practice.py backend/app/services/practice_service.py backend/app/api/v1/practice.py backend/alembic/versions/*align_practice_repertoire_remote_contract.py backend/tests/test_practice_repertoire_remote_contract.py backend/tests/test_practice_notes.py
git commit -m "feat: complete practice repertoire remote api"
```

---

## Task 6: Decide and Either Implement or Explicitly Defer Legacy Tuition Deposit API

**Why last:** The frontend `PaymentRepository` is broad, while backend comments explicitly say this is not an app-managed payment/PG surface. Implementing it blindly risks creating the wrong product.

**Files if implementing legacy tuition deposit tracking:**
- Create: `backend/app/api/v1/payments.py`
- Create: `backend/app/schemas/payment.py`
- Create: `backend/app/services/payment_service.py`
- Modify: `backend/app/api/v1/__init__.py`
- Modify: `backend/app/models/payment.py`
- Create: `backend/alembic/versions/YYYYMMDD_HHMM_add_payment_foreign_keys.py`
- Test: `backend/tests/test_payments.py`

**Preferred decision:** Defer PG/app-admin billing. Implement only “legacy tuition deposit records” if current product needs it.

**If implementing, API contract:**

- `GET /api/v1/payments`
- `GET /api/v1/payments/{payment_id}`
- `POST /api/v1/payments`
- `PUT /api/v1/payments/{payment_id}`
- `DELETE /api/v1/payments/{payment_id}`
- `GET /api/v1/payments/summary`
- `GET /api/v1/payments/overdue`
- `GET /api/v1/payments/tuition-settings/{student_id}`
- `PUT /api/v1/payments/tuition-settings/{student_id}`

**Step 1: Write failing policy/contract tests**

Assert:

- OpenAPI describes these as `legacy tuition deposit`, not app billing.
- Teacher can manage payment records only for their students.
- Student/parent can read own/linked records and mark paid if allowed.
- Teacher only can confirm.
- No card/PG fields are exposed.

Run:

```bash
cd backend && uv run pytest tests/test_payments.py -q
```

Expected: FAIL if implementing. If deferring, create a docs-only decision and do not add routes.

**Step 2: Implement or defer**

Implement only if the product decision is “legacy tuition deposit tracking is required now.”

If deferring, update:

- `docs/specs/tech_decision.md`
- GitHub issue body/comment

State that frontend should keep this exception until billing spec is approved.

**Step 3: Commit**

Implementation:

```bash
git add backend/app/api/v1/payments.py backend/app/schemas/payment.py backend/app/services/payment_service.py backend/app/api/v1/__init__.py backend/app/models/payment.py backend/alembic/versions/*payment*.py backend/tests/test_payments.py
git commit -m "feat: add legacy tuition deposit api"
```

Deferral:

```bash
git add docs/specs/tech_decision.md
git commit -m "docs: defer legacy payment api"
```

---

## Task 7: Backend Verification and Frontend Exception Reduction Handoff

**Files:**
- Modify only if needed: `docs/specs/tech_decision.md`
- Do not modify frontend in this backend branch unless the user explicitly asks.

**Step 1: Run backend verification**

```bash
cd backend && uv run ruff check .
cd backend && uv run pytest -q
```

Expected:

- ruff passes
- all backend tests pass

**Step 2: Optional frontend contract verification**

If frontend changes are present in the same workspace, do not commit them here. Only run:

```bash
cd frontend && flutter test test/architecture
cd frontend && flutter analyze
```

Expected:

- architecture tests pass
- analyze passes

**Step 3: Push**

```bash
git push
```

**Step 4: Close issues**

Close each issue only after its commit is pushed and verification output is recorded in the issue comment.

---

## Recommended Execution Order

1. Schedule confirmation card API alignment.
2. Parent child profile API.
3. Practice piece library API.
4. Practice repertoire/section/note/recording API completion.
5. Payment policy decision; implement only if explicitly approved.

This order removes the easiest frontend mock exception first and postpones the highest product-risk area.
