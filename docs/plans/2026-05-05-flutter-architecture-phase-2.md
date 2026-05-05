# Flutter Architecture Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 옵시디언 Flutter advanced course의 확장성 높은 앱 아키텍처 기준에 맞춰 feature 간 presentation provider 의존, provider 내부 workflow, domain persistence annotation을 실제로 줄인다.

**Architecture:** 기존 Riverpod 기반은 유지한다. 새 구조는 `presentation -> domain <- data`를 지키고, cross-feature 접근은 facade/domain/application provider를 통해 한다. domain entity는 persistence framework 세부사항에서 점진적으로 분리한다.

**Tech Stack:** Flutter, Dart, Riverpod, riverpod_generator, json_serializable, Hive legacy, architecture contract tests.

GitHub issue: https://github.com/chulgil/lesson-app/issues/271

---

## Task 1: Follow/Auth Presentation Dependency Slice

**Files:**
- Modify: `frontend/lib/features/follow/presentation/screens/follow_feed_screen.dart`
- Modify: `frontend/lib/features/follow/presentation/screens/follow_list_screen.dart`
- Create or modify: `frontend/lib/features/auth/auth_facade.dart` or a narrower auth public API file
- Modify: `frontend/test/architecture/feature_dependency_contract_test.dart`

**Steps:**
1. Replace direct imports of `features/auth/presentation/providers/user_role_provider.dart` from follow screens with a feature public API.
2. Keep behavior unchanged: follow screens must still read current role/user id as before.
3. Update the cross-feature presentation provider baseline by removing the two follow screen entries.
4. Run `cd frontend && flutter test test/architecture/feature_dependency_contract_test.dart`.

## Task 2: Schedule Request Workflow UseCase Slice

**Files:**
- Modify: `frontend/lib/features/schedule/presentation/providers/unified_lesson_request_providers.dart`
- Create: `frontend/lib/features/schedule/domain/services/unified_lesson_request_workflow_service.dart`
- Test: add or extend focused tests if a suitable schedule domain test exists

**Steps:**
1. Extract pure request workflow operations from `UnifiedLessonRequestActions` into a domain/application service that receives `UnifiedLessonRequestRepository` and current actor ids as constructor or method parameters.
2. Keep provider invalidation and Riverpod wiring in presentation.
3. Move business steps such as create event, approve event, withdraw previous slot lookup, reject event into the service.
4. Run `cd frontend && flutter test test/architecture`.

## Task 3: Follow Domain Hive Annotation Reduction

**Files:**
- Modify: `frontend/lib/features/follow/domain/entities/follow.dart`
- Modify: `frontend/lib/features/follow/domain/entities/follow_target_type.dart`
- Modify: `frontend/lib/features/follow/domain/entities/teacher_post.dart`
- Modify generated files only through `dart run build_runner build --delete-conflicting-outputs`
- Modify: `frontend/test/architecture/layer_boundaries_test.dart`

**Steps:**
1. Remove Hive imports, `HiveObject`, `@HiveType`, and `@HiveField` from follow domain entities if they are not registered/opened as Hive boxes.
2. Preserve JSON serialization and public constructors.
3. Add an architecture test/baseline that prevents new domain Hive annotations while allowing existing legacy annotated files.
4. Run `cd frontend && dart run build_runner build --delete-conflicting-outputs`.
5. Run `cd frontend && flutter test test/architecture`.

## Final Verification

- `cd frontend && flutter test test/architecture`
- `cd frontend && flutter analyze`
- `cd frontend && rg -n "presentation/providers" lib/features/*/domain lib/features/*/data --glob '*.dart' --glob '!*.g.dart'`
- Confirm cross-feature presentation provider baseline count is lower than 209.
- Confirm domain Hive annotation count is lower or new-domain-Hive contract is added.
