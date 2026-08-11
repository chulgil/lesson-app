import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/pending_actions_summary.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/profile/profile_facade.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/schedule_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _teacherId = 'teacher_test';

/// Route paths pushed via context.push — recorded by stub GoRoute builders.
class _RouterSpy {
  final List<String> pushedRoutes = [];
}

List<Override> _overrides({
  int connectionCount = 0,
  int bookingCount = 0,
  int lessonRequestCount = 0,
  int scheduleChangeCount = 0,
}) {
  return [
    pendingRequestCountProvider.overrideWith((ref) async => connectionCount),
    pendingBookingsCountProvider(
      _teacherId,
    ).overrideWith((_) async => bookingCount),
    todayRequestsProvider(
      _teacherId,
    ).overrideWith((_) async => _requests(lessonRequestCount)),
    pendingScheduleChangeRequestsProvider(
      _teacherId,
    ).overrideWith((_) async => _events(scheduleChangeCount)),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  _RouterSpy? routerSpy,
}) async {
  final spy = routerSpy ?? _RouterSpy();
  // GoRouter with real routes wired to spy stubs — avoids the Timer-pending
  // crash a bare context.go()/Future.delayed combo triggers in widget tests.
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder:
            (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: PendingActionsSummary(teacherId: _teacherId),
              ),
            ),
      ),
      GoRoute(
        path: '/invite/requests',
        builder: (_, state) {
          spy.pushedRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('connection-stub'));
        },
      ),
      GoRoute(
        path: '/schedule/pending',
        builder: (_, state) {
          spy.pushedRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('booking-stub'));
        },
      ),
      GoRoute(
        path: '/schedule/lesson-requests',
        builder: (_, state) {
          spy.pushedRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('lesson-request-stub'));
        },
      ),
      GoRoute(
        path: '/schedule-change-requests',
        builder: (_, state) {
          spy.pushedRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('schedule-change-stub'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PendingActionsSummary', () {
    testWidgets('총합 0 → 렌더 없음 (SizedBox.shrink)', (tester) async {
      await _pump(tester, overrides: _overrides());

      expect(find.byType(PendingActionsSummary), findsOneWidget);
      expect(find.textContaining('오늘 확인할 항목'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4개 카운트 합산 → 제목에 총합 표시 + 카테고리별 칩 노출', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          connectionCount: 1,
          bookingCount: 2,
          lessonRequestCount: 3,
          scheduleChangeCount: 1,
        ),
      );

      expect(
        find.text(AppStrings.pendingActionsSummaryTitle(7)),
        findsOneWidget,
      );
      expect(
        find.text(
          AppStrings.phaseStatLabel(
            AppStrings.pendingActionsConnectionLabel,
            1,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          AppStrings.phaseStatLabel(AppStrings.pendingActionsBookingLabel, 2),
        ),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.phaseStatLabel(AppStrings.lessonRequest, 3)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.phaseStatLabel(AppStrings.scheduleChange, 1)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('0건 카테고리는 칩이 렌더되지 않음', (tester) async {
      await _pump(tester, overrides: _overrides(connectionCount: 2));

      expect(
        find.text(
          AppStrings.phaseStatLabel(
            AppStrings.pendingActionsConnectionLabel,
            2,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppStrings.pendingActionsBookingLabel),
        findsNothing,
      );
      expect(find.textContaining(AppStrings.lessonRequest), findsNothing);
      expect(find.textContaining(AppStrings.scheduleChange), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('연결 칩 탭 → pendingRequests 라우트로 push', (tester) async {
      final spy = _RouterSpy();
      await _pump(
        tester,
        overrides: _overrides(connectionCount: 1),
        routerSpy: spy,
      );

      await tester.tap(
        find.text(
          AppStrings.phaseStatLabel(
            AppStrings.pendingActionsConnectionLabel,
            1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(spy.pushedRoutes, contains('/invite/requests'));
    });

    testWidgets('예약승인 칩 탭 → teacherId 쿼리 포함 push', (tester) async {
      final spy = _RouterSpy();
      await _pump(
        tester,
        overrides: _overrides(bookingCount: 1),
        routerSpy: spy,
      );

      await tester.tap(
        find.text(
          AppStrings.phaseStatLabel(AppStrings.pendingActionsBookingLabel, 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        spy.pushedRoutes,
        contains('/schedule/pending?teacherId=$_teacherId'),
      );
    });

    testWidgets('레슨요청 칩 탭 → lessonRequests 라우트로 push', (tester) async {
      final spy = _RouterSpy();
      await _pump(
        tester,
        overrides: _overrides(lessonRequestCount: 2),
        routerSpy: spy,
      );

      await tester.tap(
        find.text(AppStrings.phaseStatLabel(AppStrings.lessonRequest, 2)),
      );
      await tester.pumpAndSettle();

      expect(
        spy.pushedRoutes,
        contains('/schedule/lesson-requests?teacherId=$_teacherId'),
      );
    });

    testWidgets('일정변경 칩 탭 → scheduleChangeRequests 라우트로 push', (tester) async {
      final spy = _RouterSpy();
      await _pump(
        tester,
        overrides: _overrides(scheduleChangeCount: 1),
        routerSpy: spy,
      );

      await tester.tap(
        find.text(AppStrings.phaseStatLabel(AppStrings.scheduleChange, 1)),
      );
      await tester.pumpAndSettle();

      expect(
        spy.pushedRoutes,
        contains('/schedule-change-requests?teacherId=$_teacherId'),
      );
    });

    testWidgets('320px 좁은 폭 + 다건 → 레이아웃 오버플로 없음', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(
          connectionCount: 5,
          bookingCount: 12,
          lessonRequestCount: 8,
          scheduleChangeCount: 3,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

List<UnifiedLessonRequest> _requests(int count) {
  return List.generate(
    count,
    (i) => UnifiedLessonRequest(
      id: 'request_$i',
      studentId: 'student_$i',
      teacherId: _teacherId,
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      status: UnifiedRequestStatus.pending,
      createdAt: DateTime(2026, 5, 4),
      preferredSlots: const [
        PreferredTimeSlot(
          priority: 1,
          dayOfWeek: 1,
          startTime: '16:00',
          endTime: '17:00',
        ),
      ],
    ),
  );
}

List<RequestEvent> _events(int count) {
  return List.generate(
    count,
    (i) => RequestEvent(
      id: 'event_$i',
      requestId: 'request_$i',
      actorType: ProposerRole.student,
      actorId: 'student_$i',
      eventType: RequestEventType.scheduleChangeProposed,
      createdAt: DateTime(2026, 5, 4, 10),
    ),
  );
}
