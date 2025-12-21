import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lessons/presentation/screens/add_lesson_screen.dart';
import '../../features/lessons/presentation/screens/edit_lesson_screen.dart';
import '../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../features/student_home/presentation/screens/student_home_screen.dart';
import '../../features/students/presentation/screens/add_student_screen.dart';
import '../../features/students/presentation/screens/edit_student_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';

/// App route paths
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const roleSelect = '/role-select';
  static const home = '/home'; // Teacher home
  static const studentHome = '/student-home'; // Student home
  static const students = '/students';
  static const addStudent = '/students/add';
  static const studentDetail = '/students/:id';
  static const editStudent = '/students/:id/edit';
  static const lessons = '/lessons';
  static const addLesson = '/lessons/add';
  static const lessonDetail = '/lessons/:id';
  static const editLesson = '/lessons/:id/edit';
  static const practice = '/practice';
  static const profile = '/profile';
}

/// App router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Teacher Home (with bottom navigation)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Student Home (with bottom navigation)
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'studentHome',
        builder: (context, state) => const StudentHomeScreen(),
      ),

      // Add Lesson
      GoRoute(
        path: AppRoutes.addLesson,
        name: 'addLesson',
        builder: (context, state) => AddLessonScreen(
          preselectedStudentId: state.uri.queryParameters['studentId'],
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

      // Add Student
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

      // Edit Student
      GoRoute(
        path: AppRoutes.editStudent,
        name: 'editStudent',
        builder: (context, state) => EditStudentScreen(
          studentId: state.pathParameters['id'] ?? '',
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

      // TODO: Add more routes as screens are implemented
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
