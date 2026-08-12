// #749 (UI 복잡도 감사 2026-08-11) — 교사 대시보드가 analytics 로 가는 진입점을
// "이번 달" StatCard 와 하단 "통계 더보기" 링크 2곳에 중복 노출했다(동일 목적지 +
// 동일 Pro 가드). UX 규칙(같은 행동 → 하나의 CTA)에 따라 하단 링크를 제거하고
// StatCard 탭스루를 유일한 진입점으로 남겼다 — 이 테스트는 그 진입점이 여전히
// analytics 로 이동하고, Pro 가드가 그대로 유지되는지 검증한다.
//
// 전체 DashboardTab 은 다수 provider 를 요구해 격리 테스트가 어렵다
// (bell_badge_test.dart 참조) — DashboardTab._buildStatsRow 가 실제로 구성하는
// StatCard + guardProFeatureNavigation 호출을 그대로 재현해 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/widgets/stat_card.dart';
import 'package:lessonaza/features/billing/billing_facade.dart';

class _FakeBillingRepository implements AppBillingRepository {
  _FakeBillingRepository(this._snapshot);
  final AppBillingSnapshot _snapshot;

  @override
  Future<AppBillingSnapshot> fetchSnapshot() async => _snapshot;

  @override
  Future<TrialActivationResult> startTrial() =>
      throw UnimplementedError('not used in this test');

  @override
  Future<IapValidationResult> validatePurchase({
    required String platform,
    required String receipt,
    required String productId,
  }) => throw UnimplementedError('not used in this test');
}

AppBillingSnapshot _snapshot({
  required BillingPlan plan,
  required BillingStatus status,
}) {
  return AppBillingSnapshot(
    id: 'p',
    userId: 'u',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt: null,
    source: 'test',
    originalTransactionId: null,
    trialUsed: false,
  );
}

/// DashboardTab._buildStatsRow 의 "이번 달" StatCard onTap 로직을 그대로 재현.
Widget _statCardHome() {
  return Consumer(
    builder: (context, ref, _) {
      return Scaffold(
        body: StatCard(
          title: AppStrings.dashboardThisMonth,
          value: AppStrings.usageCountShort(4),
          color: AppColors.ink,
          icon: Icons.check_circle_outline,
          onTap:
              () => guardProFeatureNavigation(
                context: context,
                ref: ref,
                required: TierRequirement.pro,
                featureName: AppStrings.featureLockedMonthlyStats,
                onPass: () => context.push(AppRoutes.analytics),
              ),
        ),
      );
    },
  );
}

/// [AppRoutes.analytics] 로의 push 만 감시하는 spy GoRouter.
GoRouter _spyRouter({required List<String> visited}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => _statCardHome()),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) {
          visited.add(AppRoutes.analytics);
          return const Scaffold(body: Text('analytics'));
        },
      ),
    ],
  );
}

/// 표준 800x600 surface 는 FeatureLockedSheet(BottomSheet) 를 다 못 담아
/// RenderFlex overflow 가 난다 — 모바일 세로 사이즈로 키운다.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('DashboardTab 이번 달 StatCard → analytics (#749 중복 진입점 정리)', () {
    testWidgets('Pro 플랜 → StatCard 탭 시 analytics 로 이동한다', (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBillingRepositoryProvider.overrideWithValue(
              _FakeBillingRepository(
                _snapshot(plan: BillingPlan.pro, status: BillingStatus.active),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: _spyRouter(visited: visited)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();

      expect(visited, [AppRoutes.analytics]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('free 플랜 → StatCard 탭 시 잠금 시트만 뜨고 analytics 로 이동하지 않는다', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBillingRepositoryProvider.overrideWithValue(
              _FakeBillingRepository(
                _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: _spyRouter(visited: visited)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();

      expect(visited, isEmpty);
      expect(find.text(AppStrings.featureLockedProTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
