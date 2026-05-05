# Backend Subscription Integrity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close GitHub issue #255 by strengthening subscription API authorization, counters, lifecycle transitions, and frontend event snapshot parity.

**Architecture:** Keep the existing FastAPI service shape. Add shared subscription access checks in `SubscriptionService`, align computed response fields with the Flutter entity, update expiry processing to maintain relationship status, and expose RequestEvent snapshot fields in Flutter.

**Tech Stack:** FastAPI, SQLAlchemy async, Pydantic, pytest, Flutter/Dart json_serializable/Hive.

---

### Task 1: Backend Regression Tests

**Files:**
- Modify: `backend/tests/test_subscriptions.py`
- Modify: `backend/tests/test_subscription_expiry_service.py`

**Steps:**
1. Add tests proving unauthorized subscription detail/update/payment operations return 403.
2. Add tests for monthly/trial/package+bonus `remaining_lessons`.
3. Add tests that `use-reschedule` increments `used_reschedule_count` and rejects exhausted credits.
4. Add tests that expiry transitions related `TeacherStudentRelation` to `expired` and later `past`.
5. Run focused pytest and confirm the new tests fail before implementation.

### Task 2: Backend Fixes

**Files:**
- Modify: `backend/app/services/subscription_service.py`
- Modify: `backend/app/schemas/subscription.py`
- Modify: `backend/app/services/subscription_expiry_service.py`

**Steps:**
1. Route subscription read/write operations through the existing access helper.
2. Restrict teacher mutations to the owner teacher resolved through membership/class.
3. Calculate `remaining_lessons` using `total_lessons` or `lessons_per_month` plus `bonus_count`, with trial fallback.
4. Increment and cap reschedule credits.
5. Transition relationship status during expiry scan.

### Task 3: Frontend RequestEvent Snapshot Fields

**Files:**
- Modify: `frontend/lib/features/schedule/domain/entities/request_event.dart`
- Regenerate/modify: `frontend/lib/features/schedule/domain/entities/request_event.g.dart`

**Steps:**
1. Add `changeCreditUsed`, `changeCreditRemainingAfter`, and `keepsSessionNumber` fields.
2. Update constructor, `copyWith`, Hive adapter, JSON serialization.
3. Run targeted Dart tests or analyzer for affected code.

### Task 4: Verification and Close Issue

**Steps:**
1. Run focused backend tests.
2. Run focused frontend tests/analyzer for changed files.
3. Close GitHub issue #255 with a summary and verification evidence.
