import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/widgets/quest_celebration_card.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_celebration_provider.dart';

/// Hive 미초기화 환경 fake — Job 7 §8.3 / W5 §8.2 (1회성 보장).
class _FakeQuestCelebration extends QuestCelebration {
  bool markCelebratedCalled = false;

  @override
  Future<QuestCelebrationState> build() async => QuestCelebrationState(
    // 갓 졸업한 상태 — visible == true, 카드 렌더 가능.
    celebratedAt: DateTime.now(),
    dismissedAt: null,
  );

  @override
  Future<void> markCelebrated() async {
    markCelebratedCalled = true;
  }
}

/// Action 버튼이 호출한 라우트 path 를 기록하는 spy.
class _RouterSpy {
  final List<String> pushedRoutes = [];
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeQuestCelebration fake,
  VoidCallback? onDismissed,
  _RouterSpy? routerSpy,
}) async {
  final spy = routerSpy ?? _RouterSpy();
  // GoRouter — context.push 호출 시 spy 에 기록 후 즉시 pop (stub Navigator).
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder:
            (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: QuestCelebrationCard(onDismissed: onDismissed),
              ),
            ),
      ),
      GoRoute(
        path: '/lessons',
        builder: (_, _) {
          spy.pushedRoutes.add('/lessons');
          return const Scaffold(body: Text('lessons-stub'));
        },
      ),
      GoRoute(
        path: '/practice/stats',
        builder: (_, _) {
          spy.pushedRoutes.add('/practice/stats');
          return const Scaffold(body: Text('stats-stub'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [questCelebrationProvider.overrideWith(() => fake)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('렌더 — 제목 / 본문 / 두 액션 / 닫기 버튼', (tester) async {
    await _pump(tester, fake: _FakeQuestCelebration());

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questCelebrationTitle), findsOneWidget);
    expect(find.text(AppStrings.questCelebrationBody), findsOneWidget);
    expect(find.text(AppStrings.questCelebrationActionLessons), findsOneWidget);
    expect(find.text(AppStrings.questCelebrationActionStats), findsOneWidget);
    expect(find.byTooltip(AppStrings.questCelebrationDismiss), findsOneWidget);
  });

  testWidgets('닫기 버튼 → markCelebrated 호출 + onDismissed 콜백', (tester) async {
    final fake = _FakeQuestCelebration();
    var dismissedCalled = false;
    await _pump(tester, fake: fake, onDismissed: () => dismissedCalled = true);

    await tester.tap(find.byTooltip(AppStrings.questCelebrationDismiss));
    await tester.pumpAndSettle();

    expect(fake.markCelebratedCalled, isTrue);
    expect(dismissedCalled, isTrue);
  });

  testWidgets('"오늘의 레슨 보기" → markCelebrated + /lessons push', (tester) async {
    final fake = _FakeQuestCelebration();
    final spy = _RouterSpy();
    await _pump(tester, fake: fake, routerSpy: spy);

    await tester.tap(find.text(AppStrings.questCelebrationActionLessons));
    await tester.pumpAndSettle();

    expect(fake.markCelebratedCalled, isTrue);
    expect(spy.pushedRoutes, contains('/lessons'));
  });

  testWidgets('"주간 통계" → markCelebrated + /practice/stats push', (
    tester,
  ) async {
    final fake = _FakeQuestCelebration();
    final spy = _RouterSpy();
    await _pump(tester, fake: fake, routerSpy: spy);

    await tester.tap(find.text(AppStrings.questCelebrationActionStats));
    await tester.pumpAndSettle();

    expect(fake.markCelebratedCalled, isTrue);
    expect(spy.pushedRoutes, contains('/practice/stats'));
  });
}
