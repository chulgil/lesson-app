// Parent route definitions

import 'package:go_router/go_router.dart';

import '../../../features/parent_home/presentation/screens/child_profiles_screen.dart';
import '../../../features/parent_home/presentation/screens/child_profile_form_screen.dart';
import '../app_routes.dart';

/// Parent-specific routes
List<GoRoute> parentRoutes = [
  // Add Child Profile (must be before childProfiles for proper matching)
  GoRoute(
    path: AppRoutes.addChildProfile,
    name: 'addChildProfile',
    builder: (context, state) {
      final parentId = state.uri.queryParameters['parentId'] ?? 'parent_1';
      return ChildProfileFormScreen(parentId: parentId);
    },
  ),

  // Edit Child Profile (must be before childProfiles for proper matching)
  GoRoute(
    path: AppRoutes.editChildProfile,
    name: 'editChildProfile',
    builder: (context, state) {
      final parentId = state.uri.queryParameters['parentId'] ?? 'parent_1';
      return ChildProfileFormScreen(
        parentId: parentId,
      );
    },
  ),

  // Child Profiles List
  GoRoute(
    path: AppRoutes.childProfiles,
    name: 'childProfiles',
    builder: (context, state) {
      final parentId = state.uri.queryParameters['parentId'] ?? 'parent_1';
      return ChildProfilesScreen(parentId: parentId);
    },
  ),
];
