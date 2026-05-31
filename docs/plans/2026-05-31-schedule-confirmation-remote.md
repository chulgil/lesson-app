# Schedule Confirmation Remote Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the schedule confirmation card production local fallback with a real remote repository.

**Architecture:** Add `RemoteScheduleConfirmationCardRepository` beside the existing mock repository and wire `scheduleConfirmationCardRepositoryProvider` through `createRepository`. Keep the domain entity unchanged and map backend response aliases into the existing generated snake_case shape.

**Tech Stack:** Flutter, Riverpod, Dio `ApiClient`, `flutter_test`.

---

### Task 1: Remote Repository Contract

**Files:**
- Create: `frontend/test/features/schedule/remote_schedule_confirmation_card_repository_test.dart`
- Create: `frontend/lib/features/schedule/data/repositories/remote_schedule_confirmation_card_repository.dart`

**Steps:**
1. Write failing tests for list, create, status update, dismiss-all, and by-subscription paths.
2. Run the test and confirm it fails because the remote repository file does not exist.
3. Implement the repository with `/schedule/confirmation-cards` endpoints.
4. Run the test and confirm it passes.

### Task 2: Provider Wiring

**Files:**
- Modify: `frontend/lib/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart`

**Steps:**
1. Change provider from `createLocalFallbackRepository` to `createRepository`.
2. Use mock in mock mode and remote in remote mode.
3. Run targeted test and `flutter analyze`.

### Task 3: Documentation

**Files:**
- Modify: `docs/specs/schedule/schedule_master.md`
- Modify: `docs/specs/dev/frontend_backend_gap_analysis.md`

**Steps:**
1. Mark schedule confirmation card repository as Mock/Remote complete.
2. Remove the “remote adapter needed” note for this item.
