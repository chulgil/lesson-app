// Student management route definitions

import 'package:go_router/go_router.dart';

import '../../../features/students/presentation/screens/add_student_screen.dart';
import '../../../features/students/presentation/screens/add_student_method_screen.dart';
import '../../../features/lessons/presentation/screens/lesson_note_history_screen.dart';
import '../../../features/students/presentation/screens/edit_student_screen.dart';
import '../../../features/students/presentation/screens/student_detail_screen.dart';
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
    builder: (context, state) => const AddStudentScreen(),
  ),

  // Student Detail
  GoRoute(
    path: AppRoutes.studentDetail,
    name: 'studentDetail',
    builder: (context, state) => StudentDetailScreen(
      studentId: state.pathParameters['id'] ?? '',
    ),
  ),

  // Student Lesson Notes History
  GoRoute(
    path: AppRoutes.studentNotes,
    name: 'studentNotes',
    builder: (context, state) => LessonNoteHistoryScreen(
      studentId: state.pathParameters['id'] ?? '',
    ),
  ),

  // Edit Student
  GoRoute(
    path: AppRoutes.editStudent,
    name: 'editStudent',
    builder: (context, state) => EditStudentScreen(
      studentId: state.pathParameters['id'] ?? '',
    ),
  ),
];
