// Schedule and booking route definitions

import 'package:go_router/go_router.dart';

import '../../../features/schedule/domain/entities/unified_lesson_request.dart';
import '../../../features/schedule/domain/entities/group_class.dart';
import '../../../features/schedule/domain/entities/group_class_schedule.dart';
import '../../../features/schedule/presentation/screens/group_class_attendance_screen.dart';
import '../../../features/schedule/presentation/screens/group_class_detail_screen.dart';
import '../../../features/search/presentation/screens/teacher_search_screen.dart';
import '../../../features/schedule/presentation/screens/unified_lesson_request_screen.dart';
import '../../../features/schedule/presentation/screens/request_completion_screen.dart';
import '../../../features/schedule/presentation/screens/all_lesson_requests_screen.dart';
import '../../../features/schedule/presentation/screens/request_detail_screen.dart';
import '../../../features/schedule/presentation/screens/my_bookings_screen.dart';
import '../../../features/schedule/presentation/screens/pending_bookings_screen.dart';
import '../../../features/schedule/presentation/screens/register_regular_lesson_screen.dart';
import '../../../features/schedule/presentation/screens/teacher_availability_split_page.dart';
import '../../../features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';
import '../app_routes.dart';

/// Schedule and booking routes
List<GoRoute> scheduleRoutes = [
  // ============================================================
  // Student-facing routes (new chip-based booking system)
  // ============================================================

  // Select Teacher (used by student getting-started card)
  GoRoute(
    path: AppRoutes.selectTeacher,
    name: 'selectTeacher',
    builder: (context, state) => const TeacherSearchScreen(),
  ),

  // Unified Lesson Request (replaces LessonBookingScreen + LessonRequestScreen)
  GoRoute(
    path: AppRoutes.lessonBooking,
    name: 'lessonBooking',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is UnifiedLessonRequestParams) {
        return UnifiedLessonRequestScreen(params: extra);
      }
      // Fallback: construct params from map (backward compatibility)
      final map = extra as Map<String, dynamic>?;
      return UnifiedLessonRequestScreen(
        params: UnifiedLessonRequestParams(
          teacherId:
              map?['teacherId'] ??
              state.uri.queryParameters['teacherId'] ??
              'teacher_1',
          teacherName:
              map?['teacherName'] ??
              state.uri.queryParameters['teacherName'] ??
              '선생님',
          teacherInstruments:
              (map?['teacherInstruments'] as List<String>?) ?? ['바이올린'],
          isReturningStudent: map?['isReturningStudent'] ?? false,
          previousInstrument: map?['previousInstrument'],
          previousDay: map?['previousDay'],
          previousTime: map?['previousTime'],
        ),
      );
    },
  ),

  // Request Completion (after lesson request submission)
  GoRoute(
    path: AppRoutes.requestCompletion,
    name: 'requestCompletion',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is RequestCompletionParams) {
        return RequestCompletionScreen(params: extra);
      }
      // Fallback: should not happen in normal flow
      return const RequestCompletionScreen(
        params: RequestCompletionParams(
          teacherName: '',
          instrument: '',
          lessonType: LessonRequestType.trial,
          preferredSlots: [],
          duration: 60,
        ),
      );
    },
  ),

  // Request Detail (Jira-ticket style detail view)
  GoRoute(
    path: AppRoutes.requestDetail,
    name: 'requestDetail',
    builder: (context, state) {
      final requestId = state.pathParameters['id'] ?? '';
      final extra = state.extra as Map<String, dynamic>?;
      return RequestDetailScreen(
        requestId: requestId,
        viewerRole: extra?['viewerRole'] ?? 'teacher',
      );
    },
  ),

  // Lesson Requests (teacher view — full calendar + filter screen)
  GoRoute(
    path: AppRoutes.lessonRequests,
    name: 'lessonRequests',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return AllLessonRequestsScreen(
        teacherId:
            extra?['teacherId'] ??
            state.uri.queryParameters['teacherId'] ??
            'teacher_1',
      );
    },
  ),

  // My Lesson Requests (student view — full calendar + filter screen)
  GoRoute(
    path: AppRoutes.myLessonRequests,
    name: 'myLessonRequests',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final studentId =
          extra?['studentId'] ?? state.uri.queryParameters['studentId'] ?? '';
      return AllLessonRequestsScreen(
        teacherId: studentId,
        viewerRole: 'student',
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
        studentName:
            extra?['studentName'] ??
            state.uri.queryParameters['studentName'] ??
            '',
        teacherId:
            extra?['teacherId'] ?? state.uri.queryParameters['teacherId'] ?? '',
        teacherName:
            extra?['teacherName'] ??
            state.uri.queryParameters['teacherName'] ??
            '',
        remainingReschedules: extra?['remainingReschedules'] ?? 2,
        totalReschedules: extra?['totalReschedules'] ?? 2,
        instrument:
            extra?['instrument'] ?? state.uri.queryParameters['instrument'],
        subscriptionId:
            extra?['subscriptionId'] ??
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
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
      return TeacherAvailabilitySplitPage(teacherId: teacherId);
    },
  ),

  // Teacher Vacation Mode (#431) — 다중 기간 휴가 등록 진입 화면 (skeleton)
  GoRoute(
    path: AppRoutes.teacherVacationMode,
    name: 'teacherVacationMode',
    builder: (context, state) => const TeacherVacationModeScreen(),
  ),

  // Pending Bookings (teacher approval queue)
  GoRoute(
    path: AppRoutes.pendingBookings,
    name: 'pendingBookings',
    builder: (context, state) {
      final teacherId = state.uri.queryParameters['teacherId'] ?? 'teacher_1';
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
