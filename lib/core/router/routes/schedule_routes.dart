// Schedule and booking route definitions

import 'package:go_router/go_router.dart';

import '../../../features/schedule/presentation/screens/booking_detail_screen.dart';
import '../../../features/schedule/presentation/screens/booking_list_screen.dart';
import '../../../features/schedule/presentation/screens/pending_bookings_screen.dart';
import '../../../features/schedule/presentation/screens/register_regular_lesson_screen.dart';
import '../../../features/schedule/presentation/screens/select_teacher_screen.dart';
import '../../../features/schedule/presentation/screens/lesson_type_select_screen.dart';
import '../../../features/schedule/presentation/screens/regular_lesson_request_screen.dart';
import '../../../features/schedule/presentation/screens/trial_lesson_request_screen.dart';
import '../../../models/teacher_student_relation.dart';
import '../app_routes.dart';

/// Schedule and booking routes
List<GoRoute> scheduleRoutes = [
  // Select Teacher
  GoRoute(
    path: AppRoutes.selectTeacher,
    name: 'selectTeacher',
    builder: (context, state) => const SelectTeacherScreen(),
  ),

  // Lesson Type Select
  GoRoute(
    path: AppRoutes.lessonTypeSelect,
    name: 'lessonTypeSelect',
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님';
      return LessonTypeSelectScreen(
        teacherId: teacherId,
        teacherName: teacherName,
      );
    },
  ),

  // Pending Bookings
  GoRoute(
    path: AppRoutes.pendingBookings,
    name: 'pendingBookings',
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return PendingBookingsScreen(teacherId: teacherId);
    },
  ),

  // Trial/One-Time Lesson Request
  GoRoute(
    path: AppRoutes.trialLessonRequest,
    name: 'trialLessonRequest',
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님';
      final studentId = state.uri.queryParameters['studentId'];
      final lessonTypeStr = state.uri.queryParameters['lessonType'];
      final lessonType = lessonTypeStr == 'oneTime'
          ? LessonType.oneTime
          : LessonType.trial;
      return TrialLessonRequestScreen(
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: studentId,
        lessonType: lessonType,
      );
    },
  ),

  // Regular Lesson Request (Student-initiated)
  GoRoute(
    path: AppRoutes.regularLessonRequest,
    name: 'regularLessonRequest',
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      final teacherName = state.uri.queryParameters['teacherName'] ?? '선생님';
      final studentId = state.uri.queryParameters['studentId'];
      return RegularLessonRequestScreen(
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: studentId,
      );
    },
  ),

  // Register Regular Lesson (Teacher direct registration)
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

  // Booking List
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

  // Booking Detail
  GoRoute(
    path: AppRoutes.bookingDetail,
    name: 'bookingDetail',
    builder: (context, state) => BookingDetailScreen(
      bookingId: state.pathParameters['id'] ?? '',
    ),
  ),
];
