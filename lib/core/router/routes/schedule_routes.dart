// Schedule and booking route definitions

import 'package:go_router/go_router.dart';

import '../../../features/schedule/domain/entities/group_class.dart';
import '../../../features/schedule/domain/entities/group_class_schedule.dart';
import '../../../features/schedule/presentation/screens/group_class_attendance_screen.dart';
import '../../../features/schedule/presentation/screens/group_class_detail_screen.dart';
import '../../../features/schedule/presentation/screens/lesson_booking_screen.dart';
import '../../../features/schedule/presentation/screens/lesson_request_screen.dart';
import '../../../features/schedule/presentation/screens/lesson_requests_screen.dart';
import '../../../features/schedule/presentation/screens/my_lesson_requests_screen.dart';
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
        isTrialLesson: extra?['isTrialLesson'] ?? false,
        remainingReschedules: extra?['remainingReschedules'],
        totalReschedules: extra?['totalReschedules'],
      );
    },
  ),

  // Lesson Request (student requesting to resume lessons with previous teacher)
  GoRoute(
    path: AppRoutes.lessonRequest,
    name: 'lessonRequest',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return LessonRequestScreen(
        teacherId: extra?['teacherId'] ??
            state.uri.queryParameters['teacherId'] ??
            '',
        teacherName: extra?['teacherName'] ??
            state.uri.queryParameters['teacherName'] ??
            '선생님',
        studentId: extra?['studentId'] ??
            state.uri.queryParameters['studentId'] ??
            '',
        studentName: extra?['studentName'] ??
            state.uri.queryParameters['studentName'] ??
            '',
        previousLessonPeriod: extra?['previousLessonPeriod'] ??
            state.uri.queryParameters['previousLessonPeriod'],
      );
    },
  ),

  // Lesson Requests (teacher view of received lesson requests)
  GoRoute(
    path: AppRoutes.lessonRequests,
    name: 'lessonRequests',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return LessonRequestsScreen(
        teacherId: extra?['teacherId'] ??
            state.uri.queryParameters['teacherId'] ??
            'teacher_1',
      );
    },
  ),

  // My Lesson Requests (student view of sent lesson requests)
  GoRoute(
    path: AppRoutes.myLessonRequests,
    name: 'myLessonRequests',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return MyLessonRequestsScreen(
        studentId: extra?['studentId'] ??
            state.uri.queryParameters['studentId'] ??
            '',
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
        remainingReschedules: extra?['remainingReschedules'] ?? 2,
        totalReschedules: extra?['totalReschedules'] ?? 2,
        instrument:
            extra?['instrument'] ?? state.uri.queryParameters['instrument'],
        subscriptionId: extra?['subscriptionId'] ??
            state.uri.queryParameters['subscriptionId'], // 🆕
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

  // ============================================================
  // Group Class routes
  // ============================================================

  // Group Class Detail (student view - booking/waitlist)
  GoRoute(
    path: AppRoutes.groupClassDetail,
    name: 'groupClassDetail',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return GroupClassDetailScreen(
        scheduleId: state.pathParameters['id'] ?? extra['scheduleId'],
        studentId: extra['studentId'],
        schedule: extra['schedule'] as GroupClassSchedule,
        groupClass: extra['groupClass'] as GroupClass,
      );
    },
  ),

  // Group Class Attendance (teacher view - attendance check)
  GoRoute(
    path: AppRoutes.groupClassAttendance,
    name: 'groupClassAttendance',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return GroupClassAttendanceScreen(
        scheduleId: state.pathParameters['id'] ?? extra['scheduleId'],
        schedule: extra['schedule'] as GroupClassSchedule,
        groupClass: extra['groupClass'] as GroupClass,
      );
    },
  ),
];
