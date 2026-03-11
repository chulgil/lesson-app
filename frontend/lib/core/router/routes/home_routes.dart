// Home screen route definitions

import 'package:go_router/go_router.dart';

import '../../../features/home/presentation/screens/assignment_dashboard_screen.dart';
import '../../../features/home/presentation/screens/home_screen.dart';
import '../../../features/student_home/presentation/screens/student_home_screen.dart';
import '../../../features/parent_home/presentation/screens/parent_home_screen.dart';
import '../app_routes.dart';

/// Home routes for teacher, student, and parent
List<GoRoute> homeRoutes = [
  // Teacher Home
  GoRoute(
    path: AppRoutes.home,
    name: 'home',
    builder: (context, state) => const HomeScreen(),
  ),

  // Student Home
  GoRoute(
    path: AppRoutes.studentHome,
    name: 'studentHome',
    builder: (context, state) => const StudentHomeScreen(),
  ),

  // Parent Home
  GoRoute(
    path: AppRoutes.parentHome,
    name: 'parentHome',
    builder: (context, state) => const ParentHomeScreen(),
  ),

  // Assignment Dashboard
  GoRoute(
    path: AppRoutes.assignmentDashboard,
    name: 'assignmentDashboard',
    builder: (context, state) => const AssignmentDashboardScreen(),
  ),
];
