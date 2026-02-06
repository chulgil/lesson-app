// Lesson route definitions

import 'package:go_router/go_router.dart';

import '../../../features/lessons/presentation/screens/add_lesson_screen.dart';
import '../../../features/lessons/presentation/screens/edit_lesson_screen.dart';
import '../../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../app_routes.dart';

/// Lesson management routes
List<GoRoute> lessonRoutes = [
  // Add Lesson
  GoRoute(
    path: AppRoutes.addLesson,
    name: 'addLesson',
    builder: (context, state) {
      int? hour;
      final hourStr = state.uri.queryParameters['hour'];
      if (hourStr != null) {
        hour = int.tryParse(hourStr);
      }

      return AddLessonScreen(
        preselectedStudentId: state.uri.queryParameters['studentId'],
        preselectedDate: state.uri.queryParameters['date'],
        preselectedHour: hour,
      );
    },
  ),

  // Lesson Detail
  GoRoute(
    path: AppRoutes.lessonDetail,
    name: 'lessonDetail',
    builder: (context, state) => LessonDetailScreen(
      lessonId: state.pathParameters['id'] ?? '',
    ),
  ),

  // Edit Lesson
  GoRoute(
    path: AppRoutes.editLesson,
    name: 'editLesson',
    builder: (context, state) => EditLessonScreen(
      lessonId: state.pathParameters['id'] ?? '',
    ),
  ),
];
