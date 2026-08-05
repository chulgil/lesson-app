// Student management route definitions

import 'package:go_router/go_router.dart';

import '../../../features/students/presentation/screens/add_student_screen.dart';
import '../../../features/students/presentation/screens/add_student_method_screen.dart';
import '../../../features/lessons/presentation/screens/lesson_note_history_screen.dart';
import '../../../features/gamification/presentation/screens/badge_collection_screen.dart';
import '../../../features/gamification/presentation/screens/student_growth_detail_screen.dart';
import '../../../features/students/presentation/screens/edit_student_screen.dart';
import '../../../features/students/presentation/screens/student_detail_screen.dart';
import '../../../features/students/presentation/screens/announcement_history_screen.dart';
import '../app_routes.dart';

/// Student management routes
List<GoRoute> studentRoutes = [
  // Add Student Method Selection
  GoRoute(
    path: AppRoutes.addStudentMethod,
    name: 'addStudentMethod',
    builder: (context, state) => const AddStudentMethodScreen(),
  ),

  // Add Student (direct registration)
  GoRoute(
    path: AppRoutes.addStudent,
    name: 'addStudent',
    builder:
        (context, state) =>
            AddStudentScreen(returnTo: state.uri.queryParameters['returnTo']),
  ),

  // Announcement History
  // NOTE: must stay above studentDetail — go_router matches in declaration
  // order, and '/students/:id' would otherwise capture 'announcement-history'
  // as a studentId (see test/core/router/student_routes_shadow_test.dart).
  GoRoute(
    path: AppRoutes.announcementHistory,
    name: 'announcementHistory',
    builder: (context, state) => const AnnouncementHistoryScreen(),
  ),

  // Student Detail
  GoRoute(
    path: AppRoutes.studentDetail,
    name: 'studentDetail',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return StudentDetailScreen(
        studentId: state.pathParameters['id'] ?? '',
        membershipId: extra?['membershipId'] as String?,
      );
    },
  ),

  // Student Lesson Notes History
  GoRoute(
    path: AppRoutes.studentNotes,
    name: 'studentNotes',
    builder:
        (context, state) => LessonNoteHistoryScreen(
          studentId: state.pathParameters['id'] ?? '',
        ),
  ),

  // Edit Student
  GoRoute(
    path: AppRoutes.editStudent,
    name: 'editStudent',
    builder:
        (context, state) =>
            EditStudentScreen(studentId: state.pathParameters['id'] ?? ''),
  ),

  // Badge Collection
  GoRoute(
    path: AppRoutes.badgeCollection,
    name: 'badgeCollection',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return BadgeCollectionScreen(studentId: studentId);
    },
  ),

  // Student Growth Detail (P2 — Job 9)
  GoRoute(
    path: AppRoutes.studentGrowthDetail,
    name: 'studentGrowthDetail',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return StudentGrowthDetailScreen(studentId: studentId);
    },
  ),
];
