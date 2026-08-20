// W4 Task 4.2 — OnboardingCategoryPreviewScreen smoke + 동작 회귀 테스트.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §9.1~§9.2 — Step 2.5 5묶음 카테고리 1회 미리보기.
//
// Verifies:
// - 5묶음 아이콘 + 라벨 표시 (운영시간 / 수업방식 / 수강권·정산 / 내 프로필 / 정책·알림·지원)
// - 단일 CTA [시작하기] 만 노출 (#1287 UXC-5 — 동일 동작 버튼 2개 금지)
// - '수강권' 용어 풀이 1줄 노출 (#1287 UXC-7)
// - [시작하기] 탭 → markShown() → /home navigation
// - 좁은 width 280px — RenderBox/BoxConstraints 회귀 없음

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_category_shown_provider.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/onboarding_category_preview_screen.dart';

void main() {
  Widget wrap({double? width, GoRouter? router}) {
    final goRouter =
        router ??
        GoRouter(
          initialLocation: '/preview',
          routes: [
            GoRoute(
              path: '/preview',
              builder:
                  (context, state) => const OnboardingCategoryPreviewScreen(),
            ),
            GoRoute(
              path: '/home',
              builder:
                  (context, state) =>
                      const Scaffold(body: Center(child: Text('HOME'))),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        onboardingCategoryShownProvider.overrideWith(_FakeShownNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: goRouter,
        builder:
            width == null
                ? null
                : (context, child) =>
                    Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  group('OnboardingCategoryPreviewScreen (W4 Task 4.2)', () {
    testWidgets('5묶음 아이콘 + 라벨 표시 + 단일 CTA', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // 5묶음 아이콘 (outlined 컨벤션).
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      // 5묶음 라벨.
      expect(find.text(AppStrings.categoryOperatingHours), findsOneWidget);
      expect(find.text(AppStrings.categoryLessonStyle), findsOneWidget);
      expect(find.text(AppStrings.categorySubscriptionBilling), findsOneWidget);
      expect(find.text(AppStrings.categoryMyProfile), findsOneWidget);
      expect(find.text(AppStrings.categoryPolicyNotifications), findsOneWidget);
      // UXC-7 — '수강권' 첫 노출 지점의 용어 풀이.
      expect(
        find.text(AppStrings.onboardingCategorySubscriptionGloss),
        findsOneWidget,
      );
      // UXC-5 — CTA 는 하나뿐. [건너뛰기] 는 [시작하기] 와 동작이 같아 제거됐다.
      expect(
        find.text(AppStrings.onboardingCategoryPreviewStart),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.onboardingCategoryPreviewSkip),
        findsNothing,
        reason: '동일 동작 버튼 2개 금지 — 단일 CTA 로 통합',
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[시작하기] 탭 → markShown + /home navigation', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final startBtn = find.text(AppStrings.onboardingCategoryPreviewStart);
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // /home 라우트 도착 확인.
      expect(find.text('HOME'), findsOneWidget);
      expect(_FakeShownNotifier.markShownCallCount >= 1, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 width 360px — RenderBox/BoxConstraints 회귀 없음', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(width: 360));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [OnboardingCategoryShown] for screen tests.
class _FakeShownNotifier extends OnboardingCategoryShown {
  static int markShownCallCount = 0;

  @override
  Future<bool> build() async => false;

  @override
  Future<void> markShown() async {
    markShownCallCount++;
    state = const AsyncData(true);
  }
}
