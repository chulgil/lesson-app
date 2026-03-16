// Main app router configuration
//
// This file combines all domain-specific routes into a single router.
// Individual route definitions are in the routes/ subdirectory.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../config/environment.dart';
import '../../features/auth/domain/entities/user_role.dart';
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
import 'routes/subscription_routes.dart';

// Re-export AppRoutes for convenient imports
export 'app_routes.dart';

/// Auth-aware redirect paths.
const _publicPaths = [AppRoutes.login, '/login'];
const _roleSelectPath = AppRoutes.roleSelect;
const _termsAgreementPath = AppRoutes.termsAgreement;

/// App router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create router with optional auth-aware redirect.
  ///
  /// In mock mode: no redirect (existing behavior).
  /// In remote mode: redirects unauthenticated users to /login.
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      redirect:
          EnvironmentConfig.useMockData
              ? null
              : (context, state) {
                final authState = ref.read(authNotifierProvider);
                final currentPath = state.matchedLocation;
                final isPublic = _publicPaths.contains(currentPath);
                final isRoleSelect = currentPath == _roleSelectPath;
                final isTermsAgreement = currentPath == _termsAgreementPath;

                if (authState is AuthLoading) return null;

                if (authState is AuthUnauthenticated && !isPublic) {
                  return AppRoutes.login;
                }

                // New OAuth signup: terms agreement → role selection
                if (authState is AuthNeedsRole) {
                  final termsAgreed =
                      ref.read(authNotifierProvider.notifier).termsAgreed;
                  if (!termsAgreed && !isTermsAgreement) {
                    return AppRoutes.termsAgreement;
                  }
                  if (termsAgreed && !isRoleSelect) {
                    return AppRoutes.roleSelect;
                  }
                }

                // Onboarding not completed: redirect to profile setup
                if (authState is AuthNeedsOnboarding) {
                  final isOnboarding = currentPath.contains('/onboarding/');
                  if (!isOnboarding) {
                    return authState.role == UserRole.teacher
                        ? AppRoutes.teacherProfileSetup
                        : AppRoutes.studentProfileSetup;
                  }
                }

                if (authState is AuthAuthenticated &&
                    (isPublic || isRoleSelect || isTermsAgreement)) {
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
        ...subscriptionRoutes,
      ],
      errorBuilder:
          (context, state) => Scaffold(
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
      ...subscriptionRoutes,
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
