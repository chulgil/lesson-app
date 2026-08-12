import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/request_detail_screen.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';

// #P1 detail split — smoke test for the newly extracted app bar / event
// strip / chapter-summaries widgets. Renders through the real screen so a
// runtime layout crash (RenderBox/BoxConstraints) in any extracted piece
// surfaces here, matching the ux-rules.md widget-smoke-test contract.
void main() {
  final request = UnifiedLessonRequest(
    id: 'request_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    instrument: '피아노',
    goal: UnifiedLessonGoal.hobby,
    experience: UnifiedExperienceLevel.beginner,
    type: LessonRequestType.regular,
    status: UnifiedRequestStatus.pending,
    createdAt: DateTime(2026, 5, 4),
  );

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        unifiedRequestByIdProvider(
          request.id,
        ).overrideWith((ref) async => request),
        requestEventsProvider(
          request.id,
        ).overrideWith((ref) async => <RequestEvent>[]),
        studentNameMapProvider.overrideWithValue(const {'student_1': '김민준'}),
        teacherNameMapProvider.overrideWithValue(const {'teacher_1': '박선생'}),
        academyNameMapProvider.overrideWithValue(const {}),
        activeTeacherTemplatesProvider(
          request.teacherId,
        ).overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(
        home: RequestDetailScreen(
          requestId: 'request_1',
          viewerRole: 'teacher',
        ),
      ),
    );
  }

  testWidgets('renders a pending request without throwing', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('김민준 (정규레슨)'), findsOneWidget);
  });

  testWidgets('opens the more-actions menu without throwing', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('counter-propose (P1-4 bottom-sheet migration)', () {
    // Student made the initial request → it's the teacher (viewer)'s turn,
    // so CurrentRequestBox renders the myTurn action row with the
    // "다른 시간 제안하기" button wired to _handleCounterPropose.
    final events = [
      RequestEvent(
        id: 'evt_1',
        requestId: request.id,
        actorType: ProposerRole.student,
        actorId: request.studentId,
        eventType: RequestEventType.initialRequest,
        createdAt: DateTime(2026, 5, 4),
      ),
    ];

    Widget buildMyTurnTestable() {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );

      return ProviderScope(
        overrides: [
          unifiedRequestByIdProvider(
            request.id,
          ).overrideWith((ref) async => request),
          requestEventsProvider(request.id).overrideWith((ref) async => events),
          studentNameMapProvider.overrideWithValue(const {'student_1': '김민준'}),
          teacherNameMapProvider.overrideWithValue(const {'teacher_1': '박선생'}),
          academyNameMapProvider.overrideWithValue(const {}),
          activeTeacherTemplatesProvider(
            request.teacherId,
          ).overrideWith((ref) async => const []),
          weekLessonsWithPreviewProvider((
            weekStart: weekStart,
            teacherId: request.teacherId,
          )).overrideWith((ref) async => const []),
          teacherAvailabilityProvider(request.teacherId).overrideWith(
            (ref) async => TeacherAvailability(
              id: request.teacherId,
              teacherId: request.teacherId,
              weeklySchedules: [
                for (var d = 0; d < 7; d++)
                  WeeklySchedule(
                    id: 'ws-$d',
                    dayOfWeek: d,
                    startTime: '09:00',
                    endTime: '21:00',
                    createdAt: DateTime(2026, 1, 1),
                  ),
              ],
              exceptions: const [],
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(
          home: RequestDetailScreen(
            requestId: 'request_1',
            viewerRole: 'teacher',
          ),
        ),
      );
    }

    testWidgets('다른 시간 제안하기 opens a bottom sheet', (tester) async {
      await tester.pumpWidget(buildMyTurnTestable());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
      await tester.tap(find.text(AppStrings.scheduleChangeCounter));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // (The sheet's title text is the same string as the trigger button
      // below it, so assert on the sheet-only close icon instead.)
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(AppStrings.rejectAction), findsOneWidget);
    });
  });

  group('withdraw (M-2 bottom-sheet migration)', () {
    // Teacher already approved a slot → it's the student's turn, so
    // CurrentRequestBox renders the theirTurn withdraw button wired to
    // _handleWithdraw. status stays `approved` (still RequestPhase.request)
    // so the phase-1 turn-state logic applies.
    final approvedRequest = UnifiedLessonRequest(
      id: 'request_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      type: LessonRequestType.regular,
      status: UnifiedRequestStatus.approved,
      createdAt: DateTime(2026, 5, 4),
    );

    final events = [
      RequestEvent(
        id: 'evt_1',
        requestId: approvedRequest.id,
        actorType: ProposerRole.student,
        actorId: approvedRequest.studentId,
        eventType: RequestEventType.initialRequest,
        createdAt: DateTime(2026, 5, 4),
      ),
      RequestEvent(
        id: 'evt_2',
        requestId: approvedRequest.id,
        actorType: ProposerRole.teacher,
        actorId: approvedRequest.teacherId,
        eventType: RequestEventType.approve,
        selectedSlotIndex: 0,
        createdAt: DateTime(2026, 5, 5),
      ),
    ];

    Widget buildTheirTurnTestable() {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );

      return ProviderScope(
        overrides: [
          unifiedRequestByIdProvider(
            approvedRequest.id,
          ).overrideWith((ref) async => approvedRequest),
          requestEventsProvider(
            approvedRequest.id,
          ).overrideWith((ref) async => events),
          studentNameMapProvider.overrideWithValue(const {'student_1': '김민준'}),
          teacherNameMapProvider.overrideWithValue(const {'teacher_1': '박선생'}),
          academyNameMapProvider.overrideWithValue(const {}),
          activeTeacherTemplatesProvider(
            approvedRequest.teacherId,
          ).overrideWith((ref) async => const []),
          weekLessonsWithPreviewProvider((
            weekStart: weekStart,
            teacherId: approvedRequest.teacherId,
          )).overrideWith((ref) async => const []),
          teacherAvailabilityProvider(approvedRequest.teacherId).overrideWith(
            (ref) async => TeacherAvailability(
              id: approvedRequest.teacherId,
              teacherId: approvedRequest.teacherId,
              weeklySchedules: [
                for (var d = 0; d < 7; d++)
                  WeeklySchedule(
                    id: 'ws-$d',
                    dayOfWeek: d,
                    startTime: '09:00',
                    endTime: '21:00',
                    createdAt: DateTime(2026, 1, 1),
                  ),
              ],
              exceptions: const [],
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(
          home: RequestDetailScreen(
            requestId: 'request_1',
            viewerRole: 'teacher',
          ),
        ),
      );
    }

    testWidgets('결정 변경 opens a bottom sheet, not a pushed full-screen '
        'route', (tester) async {
      await tester.pumpWidget(buildTheirTurnTestable());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.withdrawApproval), findsOneWidget);
      await tester.tap(find.text(AppStrings.withdrawApproval));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(AppStrings.rejectAction), findsOneWidget);
    });

    testWidgets('dismissing the sheet leaves the approval unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildTheirTurnTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.withdrawApproval));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Sheet closed, withdraw button still there — no state change.
      expect(find.text(AppStrings.withdrawApproval), findsOneWidget);
    });
  });
}
