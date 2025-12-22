import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lessons/presentation/screens/add_lesson_screen.dart';
import '../../features/lessons/presentation/screens/edit_lesson_screen.dart';
import '../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../features/profile/presentation/screens/instrument_management_screen.dart';
import '../../features/profile/presentation/screens/lesson_time_settings_screen.dart';
import '../../features/profile/presentation/screens/payment_management_screen.dart';
import '../../features/profile/presentation/screens/repertoire_management_screen.dart';
import '../../features/schedule/presentation/screens/booking_detail_screen.dart';
import '../../features/schedule/presentation/screens/booking_list_screen.dart';
import '../../features/schedule/presentation/screens/pending_bookings_screen.dart';
import '../../features/schedule/presentation/screens/register_regular_lesson_screen.dart';
import '../../features/schedule/presentation/screens/select_teacher_screen.dart';
import '../../features/schedule/presentation/screens/trial_lesson_request_screen.dart';
import '../../features/practice/presentation/screens/practice_repertoire_screen.dart';
import '../../features/practice/presentation/screens/add_repertoire_screen.dart';
import '../../features/practice/presentation/screens/repertoire_detail_screen.dart';
import '../../features/practice/presentation/screens/add_section_screen.dart';
import '../../features/practice/presentation/screens/section_detail_screen.dart';
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
  static const instrumentManagement = '/profile/instruments';
  static const repertoireManagement = '/profile/repertoire';
  static const lessonTimeSettings = '/profile/lesson-time';
  static const paymentManagement = '/profile/payments';

  // Schedule routes
  static const selectTeacher = '/schedule/teachers';
  static const pendingBookings = '/schedule/pending';
  static const trialLessonRequest = '/schedule/trial/request';
  static const registerRegularLesson = '/schedule/regular/register';
  static const bookingList = '/schedule/bookings';
  static const bookingDetail = '/schedule/booking/:id';

  // Practice routes
  static const practiceRepertoire = '/practice/repertoire';
  static const addRepertoire = '/practice/repertoire/add';
  static const repertoireDetail = '/practice/repertoire/:id';
  static const addSection = '/practice/section/add';
  static const sectionDetail = '/practice/section/:id';
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

      // Instrument Management
      GoRoute(
        path: AppRoutes.instrumentManagement,
        name: 'instrumentManagement',
        builder: (context, state) => const InstrumentManagementScreen(),
      ),

      // Repertoire Management
      GoRoute(
        path: AppRoutes.repertoireManagement,
        name: 'repertoireManagement',
        builder: (context, state) => const RepertoireManagementScreen(),
      ),

      // Lesson Time Settings
      GoRoute(
        path: AppRoutes.lessonTimeSettings,
        name: 'lessonTimeSettings',
        builder: (context, state) => const LessonTimeSettingsScreen(),
      ),

      // Payment Management
      GoRoute(
        path: AppRoutes.paymentManagement,
        name: 'paymentManagement',
        builder: (context, state) => const PaymentManagementScreen(),
      ),

      // Schedule - Select Teacher
      GoRoute(
        path: AppRoutes.selectTeacher,
        name: 'selectTeacher',
        builder: (context, state) => const SelectTeacherScreen(),
      ),

      // Schedule - Pending Bookings
      GoRoute(
        path: AppRoutes.pendingBookings,
        name: 'pendingBookings',
        builder: (context, state) {
          final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
          return PendingBookingsScreen(teacherId: teacherId);
        },
      ),

      // Schedule - Trial Lesson Request
      GoRoute(
        path: AppRoutes.trialLessonRequest,
        name: 'trialLessonRequest',
        builder: (context, state) {
          final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
          final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님';
          final studentId = state.uri.queryParameters['studentId']; // Optional
          return TrialLessonRequestScreen(
            teacherId: teacherId,
            teacherName: teacherName,
            studentId: studentId,
          );
        },
      ),

      // Schedule - Register Regular Lesson
      GoRoute(
        path: AppRoutes.registerRegularLesson,
        name: 'registerRegularLesson',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RegisterRegularLessonScreen(
            teacherId: extra?['teacherId'] ?? 'teacher_1',
            teacherName: extra?['teacherName'] ?? '선생님',
            studentId: extra?['studentId'],
            studentName: extra?['studentName'],
          );
        },
      ),

      // Schedule - Booking List
      GoRoute(
        path: AppRoutes.bookingList,
        name: 'bookingList',
        builder: (context, state) {
          return BookingListScreen(
            teacherId: state.uri.queryParameters['teacherId'],
            studentId: state.uri.queryParameters['studentId'],
          );
        },
      ),

      // Schedule - Booking Detail
      GoRoute(
        path: AppRoutes.bookingDetail,
        name: 'bookingDetail',
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Practice - Repertoire List
      GoRoute(
        path: AppRoutes.practiceRepertoire,
        name: 'practiceRepertoire',
        builder: (context, state) {
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return PracticeRepertoireScreen(studentId: studentId);
        },
      ),

      // Practice - Add Repertoire
      GoRoute(
        path: AppRoutes.addRepertoire,
        name: 'addRepertoire',
        builder: (context, state) {
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return AddRepertoireScreen(studentId: studentId);
        },
      ),

      // Practice - Repertoire Detail
      GoRoute(
        path: AppRoutes.repertoireDetail,
        name: 'repertoireDetail',
        builder: (context, state) {
          final repertoireId = state.pathParameters['id'] ?? '';
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return RepertoireDetailScreen(
            repertoireId: repertoireId,
            studentId: studentId,
          );
        },
      ),

      // Practice - Add Section
      GoRoute(
        path: AppRoutes.addSection,
        name: 'addSection',
        builder: (context, state) {
          final repertoireId = state.uri.queryParameters['repertoireId'] ?? '';
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return AddSectionScreen(
            repertoireId: repertoireId,
            studentId: studentId,
          );
        },
      ),

      // Practice - Section Detail
      GoRoute(
        path: AppRoutes.sectionDetail,
        name: 'sectionDetail',
        builder: (context, state) {
          final sectionId = state.pathParameters['id'] ?? '';
          final repertoireId = state.uri.queryParameters['repertoireId'] ?? '';
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return SectionDetailScreen(
            sectionId: sectionId,
            repertoireId: repertoireId,
            studentId: studentId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
