import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/mock/mock_lesson_data_ids.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/presentation/providers/lesson_class_providers.dart';
import 'package:lessonaza/features/students/presentation/providers/membership_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_detail_screen.dart';

/// M-2 bottom-sheet migration — SubscriptionDetailScreen's compare-schedule
/// (선생님: "다른 시간 제안하기") and withdraw-schedule-decision ("결정 변경")
/// entry points used to push the full-screen SuggestAlternativeScreen; both
/// now open showSuggestAlternativeBottomSheet as a nested sheet instead.
TeacherAvailability _availability(String teacherId) {
  return TeacherAvailability(
    id: teacherId,
    teacherId: teacherId,
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
  );
}

Subscription _activeSubscription() {
  return Subscription(
    id: 'sub_1',
    studentId: 'student_1',
    membershipId: 'membership_1',
    type: SubscriptionType.monthly,
    lessonsPerMonth: 4,
    usedLessons: 2,
    amount: 280000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 4, 1),
  );
}

List<Override> _baseOverrides({required List<RequestEvent> sessionEvents}) {
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

  return [
    subscriptionProvider(
      'sub_1',
    ).overrideWith((ref) async => _activeSubscription()),
    subscriptionUsageHistoryProvider(
      'sub_1',
    ).overrideWith((ref) async => const []),
    subscriptionSessionEventsProvider(
      subscriptionId: 'sub_1',
      sessionNumber: 3,
    ).overrideWith((ref) async => sessionEvents),
    membershipProvider('membership_1').overrideWith(
      (ref) async => ClassMembership(
        id: 'membership_1',
        lessonClassId: 'class_1',
        studentId: 'student_1',
        instrument: '피아노',
        status: MembershipStatus.active,
        monthlyFee: 280000,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    lessonClassProvider('class_1').overrideWith(
      (ref) async => LessonClass(
        id: 'class_1',
        teacherId: MockLessonDataIds.teacherPrimary,
        name: '피아노 레슨',
        type: LessonClassType.private,
        paymentType: PaymentType.parent,
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
    studentNameMapProvider.overrideWithValue({'student_1': '김민준'}),
    teacherNameMapProvider.overrideWithValue({
      MockLessonDataIds.teacherPrimary: '김선아',
    }),
    weekLessonsWithPreviewProvider((
      weekStart: weekStart,
      teacherId: MockLessonDataIds.teacherPrimary,
    )).overrideWith((ref) async => const []),
    teacherAvailabilityProvider(MockLessonDataIds.teacherPrimary).overrideWith(
      (ref) async => _availability(MockLessonDataIds.teacherPrimary),
    ),
  ];
}

void main() {
  testWidgets(
    '다른 시간 제안하기 (compare schedule) opens a bottom sheet, not a pushed '
    'full-screen route',
    (tester) async {
      final events = [
        RequestEvent(
          id: 'evt_1',
          requestId: 'sub_1',
          actorType: ProposerRole.student,
          actorId: 'student_1',
          eventType: RequestEventType.scheduleChangeProposed,
          suggestedSlots: [
            TimeSlotOption(
              id: 'slot_1',
              dayOfWeek: 0,
              startTime: '16:00',
              endTime: '17:00',
            ),
          ],
          sessionNumber: 3,
          createdAt: DateTime(2026, 5, 4),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(sessionEvents: events),
          child: const MaterialApp(
            home: SubscriptionDetailScreen(
              subscriptionId: 'sub_1',
              viewerRole: 'teacher',
              initialSelectedSession: 3,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Student proposed → teacher (viewer) sees the ScheduleChoiceBar with
      // the compare CTA wired to _handleCompareSchedule.
      expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
      await tester.tap(find.text(AppStrings.scheduleChangeCounter));
      // Fixed-duration pumps (not pumpAndSettle) — an unrelated background
      // banner provider on this screen never settles in the test harness,
      // same reasoning as subscription_detail_screen_visual_contract_test.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
    },
  );

  testWidgets('결정 변경 (withdraw schedule decision) opens a bottom sheet, not a '
      'pushed full-screen route', (tester) async {
    final events = [
      RequestEvent(
        id: 'evt_1',
        requestId: 'sub_1',
        actorType: ProposerRole.teacher,
        actorId: MockLessonDataIds.teacherPrimary,
        eventType: RequestEventType.scheduleChangeProposed,
        suggestedSlots: [
          TimeSlotOption(
            id: 'slot_1',
            dayOfWeek: 0,
            startTime: '16:00',
            endTime: '17:00',
          ),
        ],
        sessionNumber: 3,
        createdAt: DateTime(2026, 5, 4),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(sessionEvents: events),
        child: const MaterialApp(
          home: SubscriptionDetailScreen(
            subscriptionId: 'sub_1',
            viewerRole: 'teacher',
            initialSelectedSession: 3,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Teacher (viewer) proposed → waiting on the student, so the bar shows
    // the withdraw CTA wired to _handleWithdrawScheduleDecision.
    expect(find.text(AppStrings.withdrawApproval), findsOneWidget);
    await tester.tap(find.text(AppStrings.withdrawApproval));
    // Fixed-duration pumps (not pumpAndSettle) — see comment above.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
