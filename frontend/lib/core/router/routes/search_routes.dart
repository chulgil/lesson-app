// Search route definitions

import 'package:go_router/go_router.dart';

import '../../../features/search/presentation/screens/teacher_search_screen.dart';
import '../../../features/search/presentation/screens/teacher_detail_screen.dart';
import '../../../features/search/presentation/screens/academy_detail_screen.dart';
import '../app_routes.dart';

/// Search routes
List<GoRoute> searchRoutes = [
  // Teacher Search
  GoRoute(
    path: AppRoutes.teacherSearch,
    name: 'teacherSearch',
    builder: (context, state) => const TeacherSearchScreen(),
  ),

  // Teacher Detail
  GoRoute(
    path: AppRoutes.teacherDetail,
    name: 'teacherDetail',
    builder: (context, state) => TeacherDetailScreen(
      teacherId: state.pathParameters['id'] ?? '',
    ),
  ),

  // Academy Detail
  GoRoute(
    path: AppRoutes.academyDetail,
    name: 'academyDetail',
    builder: (context, state) => AcademyDetailScreen(
      organizationId: state.pathParameters['id'] ?? '',
    ),
  ),
];
