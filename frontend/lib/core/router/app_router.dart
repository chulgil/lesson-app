// Main app router configuration
//
// This file combines all domain-specific routes into a single router.
// Individual route definitions are in the routes/ subdirectory.

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

/// App router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create router with optional auth-aware redirect.
  ///
  /// In mock mode: no redirect (existing behavior).
  /// In remote mode: redirects unauthenticated users to /login.
  static GoRouter createRouter(WidgetRef ref, {required bool useMockData}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      redirect: useMockData
          ? null
          : (context, state) {
              final authState = ref.read(authNotifierProvider);
              final currentPath = state.matchedLocation;
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
                    currentPath == AppRoutes.parentInviteCode;
                if (!isOnboarding && !isRoleSelect) {
                  return AppRoutes.roleSelect;
                }
              }

              if (authState is AuthAuthenticated &&
                  (isPublic || isRoleSelect)) {
                return authState.role.homeRoute;
              }

              return null;
            },
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

  /// Legacy static router (mock mode only, for backward compatibility).
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
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
