import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_with_freeze_calculator.dart';
import 'package:lessonaza/features/gamification/presentation/providers/effective_streak_provider.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/providers/child_profile_provider.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/parent_dashboard_tab.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_item.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_item_providers.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_streak_provider.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

ChildProfile _profile({String? linkedStudentId = 'student-1'}) {
  final now = DateTime.now();
  return ChildProfile(
    id: 'child-1',
    parentId: 'parent-1',
    name: '지우',
    birthYear: 2015,
    instrument: 'violin',
    level: 'beginner',
    teacherId: 'teacher-1',
    teacherName: '김선생님',
    linkedStudentId: linkedStudentId,
    profileColorKey: 'blue',
    createdAt: now,
  );
}

PracticeStreak _streak() => PracticeStreak(
  id: 's-1',
  studentId: 'student-1',
  updatedAt: DateTime.now(),
);

Subscription _activeSubscription() {
  final now = DateTime.now();
  return Subscription(
    id: 'sub-1',
    studentId: 'student-1',
    membershipId: 'mem-1',
    type: SubscriptionType.package,
    totalLessons: 8,
    usedLessons: 3,
    amount: 300000,
    status: SubscriptionStatus.active,
    createdAt: now,
  );
}

List<Override> _baseOverrides({
  required ChildProfile profile,
  List<PracticeItem> weeklyItems = const [],
  List<Subscription> subscriptions = const [],
}) {
  const studentId = 'student-1';
  return [
    currentUserIdProvider.overrideWithValue('parent-1'),
    childProfilesProvider('parent-1').overrideWith((_) async => [profile]),
    selectedChildProfileProvider.overrideWith(
      () => _FakeSelectedChildProfile(profile),
    ),
    lessonsByStudentProvider(studentId).overrideWith((_) async => const []),
    practiceStreakProvider(studentId).overrideWith((_) async => _streak()),
    // 표시 숫자 SSOT (#1214). raw 는 요일 칠하기용으로 계속 필요.
    effectiveStreakProvider(studentId).overrideWith(
      (_) async => const StreakWithFreezeResult(
        effectiveCurrentStreak: 3,
        freezeShouldApply: false,
        absenceDate: null,
        streakBroken: false,
        examModeDormant: false,
        freezeBalance: 2,
      ),
    ),
    weeklyPracticeItemsProvider(
      studentId,
    ).overrideWith((_) async => weeklyItems),
    practiceItemsByStudentProvider(
      studentId,
    ).overrideWith((_) async => const []),
    studentSubscriptionsProvider(
      studentId,
    ).overrideWith((_) async => subscriptions),
    activeStudentMembershipsProvider(
      studentId,
    ).overrideWith((_) async => const []),
  ];
}

// ---------------------------------------------------------------------------
// Empty state CTA + navigation helpers (#925)
// ---------------------------------------------------------------------------

/// Minimal GoRouter with sentinel routes for [addChildProfile] and
/// [parentInviteCode] so navigation assertions can use [find.text].
GoRouter _emptyStateRouter() {
  return GoRouter(
    initialLocation: '/parent-dashboard',
    routes: [
      GoRoute(
        path: '/parent-dashboard',
        builder: (_, __) => const Scaffold(body: ParentDashboardTab()),
      ),
      GoRoute(
        path: AppRoutes.addChildProfile,
        builder: (_, __) => const Scaffold(body: Text('add-child-sentinel')),
      ),
      GoRoute(
        path: AppRoutes.parentInviteCode,
        builder: (_, __) => const Scaffold(body: Text('invite-code-sentinel')),
      ),
    ],
  );
}

List<Override> _emptyOverrides() => [
  currentUserIdProvider.overrideWithValue('parent-1'),
  childProfilesProvider('parent-1').overrideWith((_) async => const []),
];

void main() {
  group('ParentDashboardTab — 자녀 실데이터 연결 (#585)', () {
    testWidgets('연결된 자녀 대시보드가 예외 없이 렌더된다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            profile: _profile(),
            weeklyItems: [
              PracticeItem(
                id: 'p-1',
                lessonId: 'l-1',
                studentId: 'student-1',
                teacherId: 'teacher-1',
                type: PracticeType.technique,
                title: '스케일 연습',
                priority: PracticePriority.must,
                resourceIds: const [],
                isCompleted: false,
                createdAt: DateTime.now(),
              ),
            ],
            subscriptions: [_activeSubscription()],
          ),
          child: const MaterialApp(home: Scaffold(body: ParentDashboardTab())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.noUpcomingLessons), findsOneWidget);
      // 잔여 = 8 - 3 = 5회
      expect(find.textContaining('5회'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('미연결 자녀는 섹션마다 미연결 안내를 렌더한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final profile = _profile(linkedStudentId: null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('parent-1'),
            childProfilesProvider(
              'parent-1',
            ).overrideWith((_) async => [profile]),
            selectedChildProfileProvider.overrideWith(
              () => _FakeSelectedChildProfile(profile),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ParentDashboardTab())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.parentHomeNotLinked), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('ParentDashboardTab 빈 상태 CTA (#925)', () {
    testWidgets('자녀 0명일 때 빈 상태 CTA 2개 노출 — 예외 없음', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _emptyOverrides(),
          child: MaterialApp.router(routerConfig: _emptyStateRouter()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.parentHomeNoChildren), findsOneWidget);
      expect(find.text(AppStrings.parentHomeNoChildrenDesc), findsOneWidget);
      expect(find.text(AppStrings.parentHomeAddChild), findsOneWidget);
      expect(find.text(AppStrings.parentHomeInviteCode), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('자녀 추가 CTA 탭 → addChildProfile 라우트로 이동', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _emptyOverrides(),
          child: MaterialApp.router(routerConfig: _emptyStateRouter()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(AppStrings.parentHomeAddChild));
      await tester.pumpAndSettle();

      expect(find.text('add-child-sentinel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('초대코드 입력 CTA 탭 → parentInviteCode 라우트로 이동', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _emptyOverrides(),
          child: MaterialApp.router(routerConfig: _emptyStateRouter()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(AppStrings.parentHomeInviteCode));
      await tester.pumpAndSettle();

      expect(find.text('invite-code-sentinel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Test double for the [selectedChildProfileProvider] notifier.
class _FakeSelectedChildProfile extends SelectedChildProfile {
  _FakeSelectedChildProfile(this._profile);

  final ChildProfile? _profile;

  @override
  ChildProfile? build() => _profile;
}
