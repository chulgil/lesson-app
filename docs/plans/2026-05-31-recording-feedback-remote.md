# Recording Feedback Remote Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace recording feedback's in-memory-only behavior with repository-backed remote persistence while preserving the existing widget-facing provider API.

**Architecture:** Add a small `RecordingFeedbackRepository` abstraction with mock and remote implementations. Keep `recordingFeedbackListProvider(recordingId)` returning `List<RecordingFeedback>` so existing UI stays stable; the notifier loads from the repository after build and writes through the repository on add.

**Tech Stack:** Flutter, Riverpod, Dio `ApiClient`, `flutter_test`.

---

### Task 1: Remote Repository Contract

**Files:**
- Create: `frontend/lib/features/practice/domain/repositories/recording_feedback_repository.dart`
- Create: `frontend/lib/features/practice/data/repositories/mock_recording_feedback_repository.dart`
- Create: `frontend/lib/features/practice/data/repositories/remote_recording_feedback_repository.dart`
- Test: `frontend/test/features/practice/remote_recording_feedback_repository_test.dart`

**Steps:**
1. Write failing tests for list/create/update/delete endpoint paths.
2. Implement manual JSON mapping for backend camelCase and snake_case response aliases.
3. Run targeted repository tests.

### Task 2: Provider Wiring

**Files:**
- Modify: `frontend/lib/features/practice/presentation/providers/recording_feedback_provider.dart`
- Test: `frontend/test/features/practice/recording_feedback_provider_test.dart`

**Steps:**
1. Add a plain `Provider<RecordingFeedbackRepository>` using `createRepository`.
2. Change `RecordingFeedbackList.build` to load from repository asynchronously.
3. Change `add` to call repository and append the returned feedback.
4. Keep notification side effect intact.

### Task 3: Verification

**Commands:**
- `cd frontend && flutter --no-version-check test test/features/practice/remote_recording_feedback_repository_test.dart test/features/practice/recording_feedback_provider_test.dart`
- `cd frontend && flutter --no-version-check analyze`
- `git diff --check`
