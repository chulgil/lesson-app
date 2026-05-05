# Flutter Architecture Hardening Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align the Flutter frontend implementation with the Riverpod layer contract instead of relying on legacy exceptions.

**Architecture:** Keep the existing feature-first structure and Riverpod state management. Move repository implementations to data, keep contracts in domain, centralize mock/remote selection in presentation/core providers, and split startup responsibilities out of `main.dart`.

**Tech Stack:** Flutter, Dart, Riverpod, riverpod_annotation, build_runner, flutter_test architecture tests.

---

## Task 1: Tighten The Contract Test Baseline

**Files:**
- Modify: `frontend/test/architecture/layer_boundaries_test.dart`

**Steps:**
1. Run `cd frontend && flutter test test/architecture/layer_boundaries_test.dart` and confirm the current test passes.
2. For each refactor slice below, remove the matching legacy exception from `_legacyRepositoryImplementationExceptions` or `_mockDataBranchExceptions`.
3. Run the layer boundary test after each exception removal. Expected: fail until the corresponding code is moved, then pass.
4. Keep remaining exceptions explicit and documented with a reason.

## Task 2: Move Legacy Domain Repository Implementations

**Files:**
- Modify domain contracts under:
  - `frontend/lib/features/lessons/domain/repositories/`
  - `frontend/lib/features/search/domain/repositories/`
  - `frontend/lib/features/parent_home/domain/repositories/`
  - `frontend/lib/features/settings/domain/repositories/`
  - `frontend/lib/features/profile/domain/repositories/`
  - `frontend/lib/features/practice/domain/repositories/`
- Create/move implementations under matching `frontend/lib/features/*/data/repositories/`.
- Update presentation providers/imports that instantiate mocks.

**Steps:**
1. Pick one feature group at a time.
2. Move `Mock*Repository`, `Hive*Repository`, or other concrete implementations from domain files to data repository files.
3. Keep domain files as interfaces only.
4. Update imports at construction sites.
5. Remove the matching architecture test exception.
6. Run `cd frontend && flutter test test/architecture/layer_boundaries_test.dart`.

## Task 3: Centralize Repository Mock/Remote Selection

**Files:**
- Modify direct repository provider branches:
  - `frontend/lib/features/lessons/presentation/providers/payment_repository_provider.dart`
  - `frontend/lib/features/parent_home/presentation/providers/child_profile_provider.dart`
  - `frontend/lib/features/practice/presentation/providers/piece_repository_provider.dart`
  - `frontend/lib/features/practice/presentation/providers/practice_note_provider.dart`
  - `frontend/lib/features/practice/presentation/providers/practice_repertoire_repository_provider.dart`
  - `frontend/lib/features/schedule/presentation/providers/group_class_booking_providers.dart`
  - `frontend/lib/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart`
- Modify data imports as needed.

**Steps:**
1. Replace direct `EnvironmentConfig.useMockData` repository selection with `createRepository<T>()` where a remote implementation exists.
2. If only one implementation exists, document why it remains a true exception or add a local factory that does not spread mock branching.
3. Prefer `@Riverpod(keepAlive: true)` for touched repository providers when practical.
4. Regenerate code with `cd frontend && dart run build_runner build --delete-conflicting-outputs`.
5. Remove matching exceptions from `_mockDataBranchExceptions`.
6. Run `flutter test test/architecture/layer_boundaries_test.dart`.

## Task 4: Split Startup Bootstrap From main.dart

**Files:**
- Create:
  - `frontend/lib/core/startup/app_bootstrap.dart`
  - `frontend/lib/core/startup/startup_recovery.dart`
  - `frontend/lib/core/startup/startup_provider_observer.dart`
- Modify:
  - `frontend/lib/main.dart`

**Steps:**
1. Move provider observer code into `startup_provider_observer.dart`.
2. Move recording path recovery helpers into `startup_recovery.dart`.
3. Move Firebase/audio/Hive/date/orientation startup sequence into `app_bootstrap.dart`.
4. Keep public startup recovery accessors working for existing UI callers.
5. Leave `main.dart` responsible for binding initialization, invoking bootstrap, and `runApp`.
6. Run `flutter analyze` and `flutter test test/architecture`.

## Task 5: Final Verification

**Commands:**
- `cd frontend && dart run build_runner build --delete-conflicting-outputs`
- `cd frontend && dart format <changed dart files>`
- `cd frontend && flutter test test/architecture`
- `cd frontend && flutter analyze`
- `rg -n "presentation/providers" frontend/lib/features/*/domain frontend/lib/features/*/data --glob '*.dart' --glob '!*.g.dart'`

**Expected:**
- Architecture tests pass.
- Analyzer has no issues.
- Forbidden presentation import scan returns no matches.
- Exception lists are smaller, and remaining entries are documented.
