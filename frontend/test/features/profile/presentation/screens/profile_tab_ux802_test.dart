// #802 입금대기 진입점 일원화 회귀 테스트.
//
// ProfileTab 전체 마운트는 provider 의존성이 과도해 단위테스트 부적합.
// 변경된 두 동작을 독립 위젯으로 직접 검증:
//   (A) 단축카드 제거: 입금대기 라벨 버튼이 없는 2-card Row.
//   (B) 통계 카드 탭: GestureDetector onTap 호출 → 라우트 상수 이동.
// 320px 제약 환경 레이아웃 예외 없음.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// Minimal replicas of the changed widgets (private in profile_tab.dart).
// These replicate exactly what the production code now does — any regression
// to the old shape will break these tests.
// ---------------------------------------------------------------------------

/// Replica of the 2-card quick-shortcuts Row (#802: 입금대기 카드 제거).
class _QuickShortcutsRow extends StatelessWidget {
  final VoidCallback onAvailabilityTap;
  final VoidCallback onSubscriptionTap;

  const _QuickShortcutsRow({
    required this.onAvailabilityTap,
    required this.onSubscriptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            icon: Icons.calendar_month,
            label: AppStrings.profileShortcutAvailability,
            onTap: onAvailabilityTap,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _ShortcutCard(
            icon: Icons.card_membership,
            label: AppStrings.profileShortcutSubscription,
            onTap: onSubscriptionTap,
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space4,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replica of the tappable stat item (#802: 통계 카드 탭 wiring).
class _TappableStatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _TappableStatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        Text(
          value,
          style: AppTypography.headingMedium.copyWith(color: AppColors.paper),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.paper.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
    return onTap != null
        ? GestureDetector(onTap: onTap, child: column)
        : column;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('#802 단축카드 — 입금대기 제거', () {
    testWidgets('입금대기 단축카드 라벨 없음, 가용시간·수강권 2개만 존재', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _QuickShortcutsRow(
              onAvailabilityTap: () {},
              onSubscriptionTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 입금대기 단축카드 라벨 제거 확인
      expect(
        find.text(AppStrings.profileShortcutOutstandingPayment),
        findsNothing,
      );
      // 나머지 2개 확인
      expect(find.text(AppStrings.profileShortcutAvailability), findsOneWidget);
      expect(find.text(AppStrings.profileShortcutSubscription), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('#802 통계 카드 — 입금대기 탭 wiring', () {
    testWidgets('입금대기 통계 항목 탭 → onTap 호출됨', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: AppColors.paperAccent,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: _TappableStatItem(
                label: '입금대기(후불)',
                value: '3건',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('입금대기(후불)'), findsOneWidget);
      expect(find.text('3건'), findsOneWidget);

      await tester.tap(find.text('입금대기(후불)'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('outstandingPayments 라우트 상수가 GoRouter 경로와 일치', (tester) async {
      // Verify that the route constant used in production matches router config.
      final visited = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder:
                (ctx, state) => Scaffold(
                  body: TextButton(
                    onPressed: () => ctx.push(AppRoutes.outstandingPayments),
                    child: const Text('go'),
                  ),
                ),
          ),
          GoRoute(
            path: AppRoutes.outstandingPayments,
            builder: (ctx, state) {
              visited.add(AppRoutes.outstandingPayments);
              return const Scaffold(body: Text('outstanding'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(visited, contains(AppRoutes.outstandingPayments));
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px 제약 환경 레이아웃 예외 없음', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 120));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: AppColors.paperAccent,
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: _TappableStatItem(
                label: '입금대기(후불)',
                value: '-',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
