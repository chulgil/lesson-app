import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/mock/mock_lesson_data_ids.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart';
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

/// M-3 Part 2 (schedule_change_unification_spec.md §4, A-2 결정) —
/// SubscriptionDetailScreen 의 회차 협상은 lessonRequestId 역조회 성공 시
/// RequestDetailScreen 을 canonical 화면으로 라우팅한다. 무연계 수강권은
/// A-1 공유 위젯(SubscriptionBottomInputBar) 경로를 데드엔드 없이 유지한다.
void main() {
  const subscriptionId = 'sub_1';
  const teacherId = MockLessonDataIds.teacherPrimary;

  Subscription activeSubscription() => Subscription(
    id: subscriptionId,
    studentId: 'student_1',
    membershipId: 'membership_1',
    type: SubscriptionType.monthly,
    lessonsPerMonth: 4,
    usedLessons: 2,
    amount: 280000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 4, 1),
  );

  RequestEvent proposalFromStudent() => RequestEvent(
    id: 'evt_proposal',
    requestId: subscriptionId,
    actorType: ProposerRole.student,
    actorId: 'student_1',
    eventType: RequestEventType.scheduleChangeProposed,
    suggestedSlots: [
      TimeSlotOption(
        id: 'slot_1',
        dayOfWeek: 0,
        startTime: '14:00',
        endTime: '15:00',
      ),
    ],
    sessionNumber: 3,
    createdAt: DateTime(2026, 7, 1),
  );

  TeacherAvailability availability() => TeacherAvailability(
    id: teacherId,
    teacherId: teacherId,
    weeklySchedules: const [],
    exceptions: const [],
    createdAt: DateTime(2026, 1, 1),
  );

  List<Override> baseOverrides({
    required List<RequestEvent> sessionEvents,
    required String? linkedRequestId,
  }) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    return [
      subscriptionProvider(
        subscriptionId,
      ).overrideWith((ref) async => activeSubscription()),
      subscriptionUsageHistoryProvider(
        subscriptionId,
      ).overrideWith((ref) async => const []),
      subscriptionSessionEventsProvider(
        subscriptionId: subscriptionId,
        sessionNumber: 3,
      ).overrideWith((ref) async => sessionEvents),
      lessonRequestIdBySubscriptionProvider(
        subscriptionId,
      ).overrideWith((ref) async => linkedRequestId),
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
          teacherId: teacherId,
          name: '피아노 레슨',
          type: LessonClassType.private,
          paymentType: PaymentType.parent,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      studentNameMapProvider.overrideWithValue({'student_1': '김민준'}),
      teacherNameMapProvider.overrideWithValue({teacherId: '김선아'}),
      weekLessonsWithPreviewProvider((
        weekStart: weekStart,
        teacherId: teacherId,
      )).overrideWith((ref) async => const []),
      teacherAvailabilityProvider(
        teacherId,
      ).overrideWith((ref) async => availability()),
    ];
  }

  /// 화면 + requestDetail 목적지. 착지한 경로를 기록한다 (spy).
  ({GoRouter router, List<String> landed}) buildRouter({
    bool highlightScheduleResponse = false,
  }) {
    final landed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => SubscriptionDetailScreen(
                subscriptionId: subscriptionId,
                viewerRole: 'teacher',
                initialSelectedSession: 3,
                highlightScheduleResponse: highlightScheduleResponse,
              ),
        ),
        GoRoute(
          path: AppRoutes.requestDetail,
          builder: (context, state) {
            landed.add('request');
            return const Scaffold(body: Text('request detail'));
          },
        ),
      ],
    );
    return (router: router, landed: landed);
  }

  testWidgets('연계된 수강권의 회차 협상(canRespond)은 요청 상세 이동 CTA 만 보여준다', (
    tester,
  ) async {
    final r = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(
          sessionEvents: [proposalFromStudent()],
          linkedRequestId: 'req_1',
        ),
        child: MaterialApp.router(routerConfig: r.router),
      ),
    );
    // Extra pumps vs. the other cases here — this is the only assertion that
    // depends on lessonRequestIdBySubscriptionProvider actually resolving
    // (the other states render their expected UI even mid-AsyncLoading).
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text(AppStrings.scheduleChangeResponseNeeded), findsOneWidget);
    expect(find.text(AppStrings.scheduleChangeGoToThread), findsOneWidget);
    // In-place negotiation UI must not render when a link exists.
    expect(find.text(AppStrings.scheduleChangeAccept), findsNothing);

    await tester.tap(find.text(AppStrings.scheduleChangeGoToThread));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(r.landed, ['request']);
  });

  testWidgets(
    '무연계 수강권의 회차 협상(canRespond)은 계속 A-1 공유 위젯으로 in-place 진행된다 (데드엔드 금지)',
    (tester) async {
      final r = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(
            sessionEvents: [proposalFromStudent()],
            linkedRequestId: null,
          ),
          child: MaterialApp.router(routerConfig: r.router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.scheduleChangeAccept), findsOneWidget);
      expect(find.text(AppStrings.scheduleChangeGoToThread), findsNothing);
      expect(r.landed, isEmpty);
    },
  );

  testWidgets('연계됐지만 활성 협상이 없는 Default 상태는 라우팅하지 않고 기본 안내를 보여준다', (
    tester,
  ) async {
    final r = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(sessionEvents: [], linkedRequestId: 'req_1'),
        child: MaterialApp.router(routerConfig: r.router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.scheduleChangeGuideDefault), findsOneWidget);
    expect(find.text(AppStrings.scheduleChangeGoToThread), findsNothing);
    expect(r.landed, isEmpty);
  });

  testWidgets(
    'highlightScheduleResponse 의도로 진입 + 연계됨 → 탭 없이 자동으로 요청 상세로 넘어간다 (P1-3)',
    (tester) async {
      final r = buildRouter(highlightScheduleResponse: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(
            sessionEvents: [proposalFromStudent()],
            linkedRequestId: 'req_1',
          ),
          child: MaterialApp.router(routerConfig: r.router),
        ),
      );
      await tester.pumpAndSettle();

      expect(r.landed, ['request']);
    },
  );
}
