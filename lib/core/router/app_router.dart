// Main app router configuration
//
// This file combines all domain-specific routes into a single router.
// Individual route definitions are in the routes/ subdirectory.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'routes/settings_routes.dart';

// Re-export AppRoutes for convenient imports
export 'app_routes.dart';

/// App router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
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
      ...settingsRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
