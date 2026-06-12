// W5 Task 5.6 — `GuideReshowScreen` widget smoke + 진입 동작.
//
// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §8.4

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_celebration_provider.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_first_shown_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/guide_reshow_screen.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

/// `resetDismissal()` 호출 여부 spy.
class _SpyCelebration extends QuestCelebration {
  bool resetDismissalCalled = false;

  @override
  Future<QuestCelebrationState> build() async => QuestCelebrationState(
    celebratedAt: DateTime.now(),
    dismissedAt: DateTime.now(),
  );

  @override
  Future<void> markCelebrated() async {}

  @override
  Future<void> onRequiredCompleted() async {}

  @override
  Future<void> resetDismissal() async {
    resetDismissalCalled = true;
  }
}

/// QuestFirstShown Hive 미초기화 가드.
class _FakeQuestFirstShown extends QuestFirstShown {
  @override
  Future<DateTime?> build() async => null;
  @override
  Future<void> markShown() async {}
}

List<Override> _baseOverrides({required QuestCelebration celebrationFake}) => [
  hasAvailableSlotsProvider.overrideWithValue(true),
  hasProfileImageProvider.overrideWithValue(true),
  hasIntroductionProvider.overrideWithValue(true),
  hasInstrumentsProvider.overrideWithValue(true),
  hasPriceTableProvider.overrideWithValue(true),
  hasBankAccountProvider.overrideWithValue(true),
  hasIssuedSubscriptionProvider.overrideWithValue(true),
  hasWrittenLessonNoteProvider.overrideWithValue(true),
  hasAssignedPracticeProvider.overrideWithValue(true),
  homeHasCompletedLessonProvider.overrideWithValue(true),
  homeTeacherPhoneVerifiedProvider.overrideWithValue(false),
  homeStudentsProvider.overrideWith(
    (ref) async => [
      Student(
        id: 's1',
        name: '학생',
        instrument: '피아노',
        createdAt: DateTime.utc(2026, 5, 1),
      ),
    ],
  ),
  questFirstShownProvider.overrideWith(_FakeQuestFirstShown.new),
  questCelebrationProvider.overrideWith(() => celebrationFake),
];

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  final router = GoRouter(
    initialLocation: AppRoutes.guideReshow,
    routes: [
      GoRoute(
        path: AppRoutes.guideReshow,
        builder: (_, __) => const GuideReshowScreen(),
      ),
      // Step 2.5 stub — 진입 라우트만 확인.
      GoRoute(
        path: AppRoutes.onboardingCategoryPreview,
        builder: (_, __) => const Scaffold(body: Text('category-preview-stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('렌더 — AppBar 제목 / 부제 / Step 2.5 재실행 버튼', (tester) async {
    final fake = _SpyCelebration();
    await _pump(tester, _baseOverrides(celebrationFake: fake));

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.categoryGuideReplayLabel), findsOneWidget);
    expect(find.text(AppStrings.categoryGuideReplaySubtitle), findsOneWidget);
    expect(
      find.text(AppStrings.guideReshowCategoryPreviewButton),
      findsOneWidget,
    );
  });

  testWidgets('진입 시 resetDismissal() 자동 호출 (spec §8.4)', (tester) async {
    final fake = _SpyCelebration();
    await _pump(tester, _baseOverrides(celebrationFake: fake));

    expect(fake.resetDismissalCalled, isTrue);
  });

  testWidgets('Step 2.5 재실행 버튼 → /onboarding/category-preview 진입', (
    tester,
  ) async {
    final fake = _SpyCelebration();
    await _pump(tester, _baseOverrides(celebrationFake: fake));

    await tester.tap(find.text(AppStrings.guideReshowCategoryPreviewButton));
    await tester.pumpAndSettle();

    expect(find.text('category-preview-stub'), findsOneWidget);
  });
}
