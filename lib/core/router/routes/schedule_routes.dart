// Schedule and booking route definitions

import 'package:go_router/go_router.dart';

import '../../../features/schedule/presentation/screens/lesson_booking_screen.dart';
import '../../../features/schedule/presentation/screens/my_bookings_screen.dart';
import '../../../features/schedule/presentation/screens/pending_bookings_screen.dart';
import '../../../features/schedule/presentation/screens/register_regular_lesson_screen.dart';
import '../../../features/schedule/presentation/screens/teacher_availability_screen.dart';
import '../app_routes.dart';

/// Schedule and booking routes
List<GoRoute> scheduleRoutes = [
  // ============================================================
  // Student-facing routes (new chip-based booking system)
  // ============================================================

  // Lesson Booking (chip-based UI for trial/one-time lessons)
  GoRoute(
    path: AppRoutes.lessonBooking,
    name: 'lessonBooking',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return LessonBookingScreen(
        teacherId: extra?['teacherId'] ??
            state.uri.queryParameters['teacherId'] ??
            'teacher_1',
        teacherName: extra?['teacherName'] ??
            state.uri.queryParameters['teacherName'] ??
            '선생님',
        instrument: extra?['instrument'] ??
            state.uri.queryParameters['instrument'] ??
            '바이올린',
        studentId:
            extra?['studentId'] ?? state.uri.queryParameters['studentId'],
        studentName:
            extra?['studentName'] ?? state.uri.queryParameters['studentName'],
        remainingLessons: extra?['remainingLessons'],
        totalLessons: extra?['totalLessons'],
        isReschedule: extra?['isReschedule'] ?? false,
        remainingReschedules: extra?['remainingReschedules'],
        totalReschedules: extra?['totalReschedules'],
      );
    },
  ),

  // My Bookings (student view of their bookings)
  GoRoute(
    path: AppRoutes.myBookings,
    name: 'myBookings',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return MyBookingsScreen(
        studentId:
            extra?['studentId'] ?? state.uri.queryParameters['studentId'] ?? '',
        studentName: extra?['studentName'] ??
            state.uri.queryParameters['studentName'] ??
            '',
        teacherId:
            extra?['teacherId'] ?? state.uri.queryParameters['teacherId'] ?? '',
        teacherName: extra?['teacherName'] ??
            state.uri.queryParameters['teacherName'] ??
            '',
        remainingReschedules: extra?['remainingReschedules'] ?? 3,
        totalReschedules: extra?['totalReschedules'] ?? 3,
        instrument:
            extra?['instrument'] ?? state.uri.queryParameters['instrument'],
      );
    },
  ),

  // ============================================================
  // Teacher-facing routes
  // ============================================================

  // Teacher Availability Management
  GoRoute(
    path: AppRoutes.teacherAvailability,
    name: 'teacherAvailability',
    builder: (context, state) {
      final teacherId =
          state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return TeacherAvailabilityScreen(teacherId: teacherId);
    },
  ),

  // Pending Bookings (teacher approval queue)
  GoRoute(
    path: AppRoutes.pendingBookings,
    name: 'pendingBookings',
    builder: (context, state) {
      final teacherId =
          state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return PendingBookingsScreen(teacherId: teacherId);
    },
  ),

  // Register Regular Lesson (teacher direct registration for existing students)
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
];
