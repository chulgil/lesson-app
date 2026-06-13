// #415 R4 Phase C2 — LifetimePromoBanner smoke + 분기 테스트.
//
// 카운트다운 라벨, CTA tap → onBuy 콜백, 만료 시 0 보정 확인.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/presentation/widgets/lifetime_promo_banner.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SafeArea(child: child)));

  testWidgets('eyebrow + 타이틀 + D-N + CTA 노출', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      wrap(
        LifetimePromoBanner(
          endsAt: DateTime(2026, 8, 1),
          now: DateTime(2026, 5, 24),
          onBuy: () => tapped++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.paywallLifetimePromoEyebrow), findsOneWidget);
    expect(find.text(AppStrings.paywallLifetimePromoTitle), findsOneWidget);
    expect(find.text(AppStrings.paywallLifetimePromoSubtitle), findsOneWidget);
    // 5/24 → 8/1 = 69 일 차이 (8월 1일 - 5월 24일).
    expect(find.text('D-69 종료'), findsOneWidget);
    expect(find.text(AppStrings.paywallLifetimeBuyCta), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(LifetimePromoBanner.buyButtonKey));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('endsAt 이 과거면 D-0 으로 보정', (tester) async {
    await tester.pumpWidget(
      wrap(
        LifetimePromoBanner(
          endsAt: DateTime(2026, 1, 1),
          now: DateTime(2026, 5, 24),
          onBuy: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('D-0 종료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onDismiss null → X 버튼 미노출 (기본 동작 호환)', (tester) async {
    await tester.pumpWidget(
      wrap(
        LifetimePromoBanner(
          endsAt: DateTime(2026, 8, 1),
          now: DateTime(2026, 5, 24),
          onBuy: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LifetimePromoBanner.dismissButtonKey), findsNothing);
  });

  testWidgets('onDismiss 제공 시 X 버튼 노출 + tap → 콜백 실행', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      wrap(
        LifetimePromoBanner(
          endsAt: DateTime(2026, 8, 1),
          now: DateTime(2026, 5, 24),
          onBuy: () {},
          onDismiss: () => dismissed++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LifetimePromoBanner.dismissButtonKey), findsOneWidget);
    await tester.tap(find.byKey(LifetimePromoBanner.dismissButtonKey));
    await tester.pump();
    expect(dismissed, 1);
  });
}
