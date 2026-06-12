// Schedule and booking route definitions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../widgets/notebook/notebook_surfaces.dart';
import '../route_params.dart';
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
import '../../../features/schedule/presentation/screens/lesson_booking_screen.dart';
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
      // 2026-06-12 — #703 잔존 (개행 분리 폴백이라 grep 누락). teacher
      // 본인 화면이므로 폴백은 현재 로그인 사용자.
      final extra = state.extra as Map<String, dynamic>?;
      final fromExtra = extra?['teacherId'] as String?;
      return AllLessonRequestsScreen(
        teacherId: (fromExtra != null && fromExtra.isNotEmpty)
            ? fromExtra
            : teacherIdParamOrCurrent(context, state),
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
  // 학생 선착순 직접 예약 (#580 student_direct_booking_spec)
  GoRoute(
    path: AppRoutes.lessonDirectBooking,
    name: 'lessonDirectBooking',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is! LessonBookingParams) {
        return const NotebookScreenScaffold(
          body: Center(child: Text(AppStrings.cannotLoadData)),
        );
      }
      return LessonBookingScreen(params: extra);
    },
  ),

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
      // 2026-06-12 — 하드코딩 'teacher_1' 폴백 제거. remote(베타)에서
      // 조회는 teacher_1 / 저장은 본인 계정으로 갈라져 "추가해도 무반응"
      // 버그의 근본 원인이었다 (mock 은 currentUserId==teacher_1 이라
      // 우연히 일치해 재현 불가).
      final teacherId = teacherIdParamOrCurrent(context, state);
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
      final teacherId = teacherIdParamOrCurrent(context, state);
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
        teacherId: teacherIdExtraOrCurrent(context, extra),
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
      final extra = state.extra as Map<String, dynamic>?;
      if (extra == null) {
        return const NotebookScreenScaffold(
          body: Center(child: Text(AppStrings.groupClassInfoUnavailable)),
        );
      }
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
      final extra = state.extra as Map<String, dynamic>?;
      if (extra == null) {
        return const NotebookScreenScaffold(
          body: Center(child: Text(AppStrings.groupClassInfoUnavailable)),
        );
      }
      return GroupClassAttendanceScreen(
        scheduleId: state.pathParameters['id'] ?? extra['scheduleId'],
        schedule: extra['schedule'] as GroupClassSchedule,
        groupClass: extra['groupClass'] as GroupClass,
      );
    },
  ),
];
