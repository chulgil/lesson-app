// Main app router configuration
//
// This file combines all domain-specific routes into a single router.
// Individual route definitions are in the routes/ subdirectory.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../widgets/notebook/notebook_surfaces.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/extensions/user_role_visuals.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/onboarding/onboarding_facade.dart';
import '../../features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'app_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/home_routes.dart';
import 'routes/lesson_routes.dart';
import 'routes/student_routes.dart';
import 'routes/profile_routes.dart';
import 'routes/schedule_routes.dart';
import 'routes/practice_routes.dart';
import 'routes/parent_routes.dart';
import 'routes/search_routes.dart';
import 'routes/invite_routes.dart';
import 'routes/notification_routes.dart';
import 'routes/settings_routes.dart';
import 'routes/share_routes.dart';
import 'routes/subscription_routes.dart';
import 'routes/academy_routes.dart';

// Re-export AppRoutes for convenient imports
export 'app_routes.dart';

/// Auth-aware redirect paths.
const _publicPaths = [AppRoutes.login, '/login'];

/// Public path prefixes (token-based shares, no auth required) — R2 #318.
/// #1217 — 무가입 자녀 성장 리포트 프리뷰도 동일한 미인증 접근 정책을 따른다.
const _publicPathPrefixes = ['/student/summary/', '/growth-report/'];

const _roleSelectPath = AppRoutes.roleSelect;

/// Teacher onboarding phase used to subdivide the [AuthNeedsOnboarding] gate
/// (_audits/2026-06-10-teacher-flow-ux-audit.md §4.2 A2).
///
/// - [profileA]: 이름/악기 미입력 → `teacherProfileSetup`
/// - [firstAvailability]: 프로필 완료, 활성 `WeeklySchedule` 0개 → `teacherFirstAvailability`
/// - [complete]: 위 두 단계 모두 완료 (역할 기반 home 으로 진입 허용)
///
/// 학생/학부모 역할에는 의미가 없으므로 [complete] 로 간주한다 (기존 동작 유지).
enum OnboardingPhase { profileA, firstAvailability, complete }

/// Pure auth-aware redirect decision (remote mode).
///
/// Extracted from the [GoRouter.redirect] closure so the guard rules are unit
/// testable without a router/widget tree. Returns the path to redirect to, or
/// ``null`` to allow [currentPath].
///
/// [teacherPhase] (default [OnboardingPhase.complete]) subdivides the
/// [AuthNeedsOnboarding] state when the user is a teacher so partially-
/// completed onboarding lands on the correct step instead of always bouncing
/// to `roleSelect`. The phase is computed once per redirect from Riverpod at
/// the [GoRouter.redirect] closure; tests can pass it explicitly.
String? resolveAuthRedirect(
  AuthState authState,
  String currentPath, {
  OnboardingPhase teacherPhase = OnboardingPhase.complete,
}) {
  final isPublic =
      _publicPaths.contains(currentPath) ||
      _publicPathPrefixes.any(currentPath.startsWith);
  final isRoleSelect = currentPath == _roleSelectPath;
  final isSplash = currentPath == AppRoutes.splash;

  if (authState is AuthLoading) return null;

  if (authState is AuthUnauthenticated && !isPublic) {
    return AppRoutes.login;
  }

  // New OAuth signup: terms agreement is collected inline inside
  // RoleSelectScreen (phone_verification_policy.md §2.3).
  if (authState is AuthNeedsRole && !isRoleSelect) {
    // #1267 — target-role QR scan must reach the scanner before a role is
    // chosen, otherwise RoleSelectScreen always appears first and the
    // "skip role-select" acceptance criterion breaks. Once the scan resolves
    // a target-role invite, ScanInviteScreen calls setRole() itself and the
    // AuthNeedsOnboarding gate below takes over routing.
    if (currentPath == AppRoutes.inviteScan) return null;
    return AppRoutes.roleSelect;
  }

  // Onboarding not completed: redirect to profile setup
  if (authState is AuthNeedsOnboarding) {
    final isOnboarding =
        currentPath.contains('/onboarding/') ||
        currentPath == AppRoutes.studentInviteCode ||
        currentPath == AppRoutes.parentInviteCode ||
        // Deep-link invite (lessonapp://invite/code) must survive the
        // onboarding gate, otherwise the link is silently dropped.
        currentPath == AppRoutes.inviteCode ||
        // Code submission pushes to inviteConfirm carrying the Invite extra;
        // a redirect here would drop the extra and break the connection flow.
        currentPath == AppRoutes.inviteConfirm;

    // Teacher 만 phase 세분화. 학생/학부모는 기존 동작 (roleSelect 폴백) 유지.
    final isTeacher = authState.role == UserRole.teacher;
    if (isTeacher && !isOnboarding && !isRoleSelect) {
      switch (teacherPhase) {
        case OnboardingPhase.profileA:
          return AppRoutes.teacherProfileSetup;
        case OnboardingPhase.firstAvailability:
          return AppRoutes.teacherFirstAvailability;
        case OnboardingPhase.complete:
          // Phase 미상(데이터 로딩 중) — 기존 폴백 유지.
          return AppRoutes.roleSelect;
      }
    }

    if (!isOnboarding && !isRoleSelect) {
      return AppRoutes.roleSelect;
    }
  }

  // Splash is the initial location: once auth resolves, an authenticated user
  // must be sent to home instead of being stranded on the loading screen.
  if (authState is AuthAuthenticated &&
      (isPublic || isRoleSelect || isSplash)) {
    return authState.role.homeRoute;
  }

  return null;
}

/// Compute the current teacher onboarding phase from Riverpod state.
///
/// Async providers are read snapshot-only (no `await`). When data is not yet
/// loaded the function returns [OnboardingPhase.complete] so the existing
/// fallback in [resolveAuthRedirect] (roleSelect) keeps applying — avoiding
/// race conditions where the router flickers to a wrong screen before data
/// arrives.
OnboardingPhase resolveTeacherOnboardingPhase(WidgetRef ref) {
  // 1) profile (name + instruments) 존재 여부
  final profileSnap = ref.read(currentTeacherProfileProvider);
  final profile = profileSnap.valueOrNull;
  final hasProfileA =
      profile != null &&
      profile.name.isNotEmpty &&
      profile.instruments.isNotEmpty;
  if (!hasProfileA) {
    // 데이터 로딩 중이면 phase 를 단정하지 않는다.
    return profileSnap.hasValue
        ? OnboardingPhase.profileA
        : OnboardingPhase.complete;
  }

  // 2) 활성 WeeklySchedule 1개 이상 여부
  final userId = profile.userId;
  final availSnap = ref.read(teacherAvailabilityProvider(userId));
  final availability = availSnap.valueOrNull;
  final hasActiveSchedule =
      availability != null &&
      availability.weeklySchedules.any((s) => s.isActive);
  if (!hasActiveSchedule) {
    return availSnap.hasValue
        ? OnboardingPhase.firstAvailability
        : OnboardingPhase.complete;
  }

  return OnboardingPhase.complete;
}

/// Bridges a Riverpod auth state stream to GoRouter's [refreshListenable].
///
/// GoRouter re-evaluates [GoRouter.redirect] whenever the supplied
/// [Listenable] notifies. Wrapping the auth state stream here lets a
/// **single** router instance react to auth changes without being rebuilt
/// (avoids GoRouter teardown on every auth/mode change — issue: router
/// re-creation on each `build`).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// App router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create router with auth-aware redirect.
  ///
  /// Redirect + [refreshListenable] are applied **regardless of mock mode**:
  /// mock mode only swaps data repositories, while routing/redirect must behave
  /// identically. Previously mock mode produced a static router with no redirect,
  /// so a single early `mockDataModeProvider` read (default USE_MOCK=true) cached
  /// a redirect-less router that never re-evaluated auth — leaving logout stuck.
  ///
  /// [refreshListenable] drives redirect re-evaluation on auth state changes.
  /// The router itself must be created **once** and reused; auth changes flow
  /// through this listenable rather than router re-creation.
  static GoRouter createRouter(WidgetRef ref, {Listenable? refreshListenable}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      refreshListenable: refreshListenable,
      redirect: (context, state) => resolveAuthRedirect(
        ref.read(authNotifierProvider),
        state.matchedLocation,
        teacherPhase: resolveTeacherOnboardingPhase(ref),
      ),
      routes: [
        // Combine all domain-specific routes
        ...authRoutes,
        ...homeRoutes,
        ...lessonRoutes,
        ...studentRoutes,
        ...profileRoutes,
        ...scheduleRoutes,
        ...practiceRoutes,
        ...parentRoutes,
        ...searchRoutes,
        ...inviteRoutes,
        ...notificationRoutes,
        ...settingsRoutes,
        ...shareRoutes,
        ...subscriptionRoutes,
        ...academyRoutes,
      ],
      errorBuilder: (context, state) => NotebookScreenScaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
