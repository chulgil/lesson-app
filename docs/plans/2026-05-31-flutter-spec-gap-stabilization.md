# Flutter Spec Gap Stabilization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the confirmed Flutter runtime errors/no-op paths from the spec audit and align optimistic spec statuses with the current implementation.

**Architecture:** Keep the patch narrow. Remote analytics must not throw for screen-backed providers when a beta API does not yet exist; it should derive what it can from `/analytics/monthly-stats` and return empty aggregates for unsupported sections. Existing subscription detail routing should be reused instead of adding a new screen.

**Tech Stack:** Flutter, Riverpod, GoRouter, `flutter_test`, existing `ApiClient`/repository patterns.

---

### Task 1: Analytics Remote Fallbacks

**Files:**
- Modify: `frontend/lib/features/analytics/data/repositories/remote_analytics_repository.dart`
- Test: `frontend/test/features/analytics/remote_analytics_repository_test.dart`

**Steps:**
1. Write tests that call `getRevenueAnalytics`, `getStudentProgress`, `getRetentionAnalytics`, and `getStudentSummaryList` on `RemoteAnalyticsRepository`.
2. Verify the tests fail because the methods throw `UnimplementedError`.
3. Implement minimal remote-safe behavior. Use `/analytics/monthly-stats` for revenue fields and return empty aggregates where no API exists.
4. Run the analytics test and `flutter analyze`.

### Task 2: Subscription Detail CTA

**Files:**
- Modify: `frontend/lib/features/schedule/presentation/screens/request_detail_screen.dart`
- Test: existing targeted widget/architecture coverage if available; otherwise static route contract via `rg` and analyzer.

**Steps:**
1. Replace the “coming soon” handler with `context.push(AppRoutes.subscriptionDetail, extra: {'viewerRole': viewerRole})` when the request has a subscription id.
2. Keep a defensive info message only when no subscription id can be resolved.
3. Run targeted schedule/request tests if a narrow test exists, then `flutter analyze`.

### Task 3: Spec Status Corrections

**Files:**
- Modify: `docs/specs/feature_hub.md`
- Modify: `docs/specs/user/user_master.md`
- Modify: `docs/specs/schedule/schedule_master.md`
- Modify: `docs/specs/dev/frontend_backend_gap_analysis.md`

**Steps:**
1. Change Kakao/Apple SSO from complete to pending/Google-only where the text currently overstates implementation.
2. Change parent dashboard status to clarify 4-tab UI is complete but real data is partial.
3. Change schedule confirmation card remote status from complete to mock/local fallback.
4. Keep wording short and factual.

### Task 4: Verification

**Commands:**
- `cd frontend && flutter --no-version-check test test/features/analytics/remote_analytics_repository_test.dart`
- `cd frontend && flutter --no-version-check analyze`
- `git diff --check`
