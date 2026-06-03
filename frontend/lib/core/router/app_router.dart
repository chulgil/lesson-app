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
import '../../features/auth/presentation/extensions/user_role_visuals.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
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

// Re-export AppRoutes for convenient imports
export 'app_routes.dart';

/// Auth-aware redirect paths.
const _publicPaths = [AppRoutes.login, '/login'];

/// Public path prefixes (token-based shares, no auth required) — R2 #318.
const _publicPathPrefixes = ['/student/summary/'];

const _roleSelectPath = AppRoutes.roleSelect;

/// Pure auth-aware redirect decision (remote mode).
///
/// Extracted from the [GoRouter.redirect] closure so the guard rules are unit
/// testable without a router/widget tree. Returns the path to redirect to, or
/// ``null`` to allow [currentPath].
String? resolveAuthRedirect(AuthState authState, String currentPath) {
  final isPublic =
      _publicPaths.contains(currentPath) ||
      _publicPathPrefixes.any(currentPath.startsWith);
  final isRoleSelect = currentPath == _roleSelectPath;

  if (authState is AuthLoading) return null;

  if (authState is AuthUnauthenticated && !isPublic) {
    return AppRoutes.login;
  }

  // New OAuth signup: terms agreement is collected inline inside
  // RoleSelectScreen (phone_verification_policy.md §2.3).
  if (authState is AuthNeedsRole && !isRoleSelect) {
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
    if (!isOnboarding && !isRoleSelect) {
      return AppRoutes.roleSelect;
    }
  }

  if (authState is AuthAuthenticated && (isPublic || isRoleSelect)) {
    return authState.role.homeRoute;
  }

  return null;
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
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
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
  static GoRouter createRouter(
    WidgetRef ref, {
    Listenable? refreshListenable,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      refreshListenable: refreshListenable,
      redirect: (context, state) => resolveAuthRedirect(
        ref.read(authNotifierProvider),
        state.matchedLocation,
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
      ],
      errorBuilder: (context, state) => NotebookScreenScaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
