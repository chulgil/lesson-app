// Lesson route definitions

import 'package:go_router/go_router.dart';

import '../../../features/lessons/presentation/screens/add_lesson_screen.dart';
import '../../../features/lessons/presentation/screens/edit_lesson_screen.dart';
import '../../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../../features/lessons/presentation/screens/bulk_feedback_screen.dart';
import '../../../features/lessons/presentation/screens/quick_feedback_screen.dart';
import '../../../features/lessons/presentation/screens/quick_feedback_student_list.dart';
import '../app_routes.dart';

/// Lesson management routes
List<GoRoute> lessonRoutes = [
  // Add Lesson
  GoRoute(
    path: AppRoutes.addLesson,
    name: 'addLesson',
    builder: (context, state) {
      final params = state.uri.queryParameters;
      final hour = params['hour'] != null ? int.tryParse(params['hour']!) : null;
      final minute = params['minute'] != null ? int.tryParse(params['minute']!) : null;

      return AddLessonScreen(
        preselectedStudentId: params['studentId'],
        preselectedDate: params['date'],
        preselectedHour: hour,
        preselectedMinute: minute,
      );
    },
  ),

  // Bulk Feedback
  GoRoute(
    path: AppRoutes.bulkFeedback,
    name: 'bulkFeedback',
    builder: (context, state) => const BulkFeedbackScreen(),
  ),

  // Quick Feedback - Student List (before lessonDetail to avoid :id matching)
  GoRoute(
    path: AppRoutes.quickFeedbackList,
    name: 'quickFeedbackList',
    builder: (context, state) => const QuickFeedbackStudentList(),
  ),

  // Quick Feedback - Write Feedback
  GoRoute(
    path: AppRoutes.quickFeedback,
    name: 'quickFeedback',
    builder: (context, state) => QuickFeedbackScreen(
      lessonId: state.pathParameters['id'] ?? '',
    ),
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
