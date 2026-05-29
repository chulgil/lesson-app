// #415 R4 Phase C2 — FeatureLockedSheet smoke + tier 분기 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/presentation/widgets/feature_locked_sheet.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SafeArea(child: child)));

  testWidgets('Pro tier: Pro 안내 + 업그레이드/나중에 2버튼', (tester) async {
    var upgrade = 0, later = 0;

    await tester.pumpWidget(
      wrap(
        FeatureLockedSheet(
          tier: LockedFeatureTier.pro,
          onUpgrade: () => upgrade++,
          onLater: () => later++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.featureLockedProTitle), findsOneWidget);
    expect(find.text(AppStrings.featureLockedProSubtitle), findsOneWidget);
    expect(find.text(AppStrings.paywallProBuyCta), findsOneWidget);
    expect(find.text(AppStrings.paywallLaterCta), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(FeatureLockedSheet.upgradeButtonKey));
    await tester.tap(find.byKey(FeatureLockedSheet.laterButtonKey));
    await tester.pump();

    expect(upgrade, 1);
    expect(later, 1);
  });

  testWidgets('Studio tier: Studio 안내 + Studio CTA', (tester) async {
    await tester.pumpWidget(
      wrap(
        FeatureLockedSheet(
          tier: LockedFeatureTier.studio,
          onUpgrade: () {},
          onLater: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.featureLockedStudioTitle), findsOneWidget);
    expect(find.text(AppStrings.featureLockedStudioSubtitle), findsOneWidget);
    expect(find.text(AppStrings.billingStudioUpgradeCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('featureName 지정 시 본문에 prefix 로 합쳐 노출', (tester) async {
    await tester.pumpWidget(
      wrap(
        FeatureLockedSheet(
          tier: LockedFeatureTier.pro,
          onUpgrade: () {},
          onLater: () {},
          featureName: 'AI 피치 비교',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('AI 피치 비교 — ${AppStrings.featureLockedProSubtitle}'),
      findsOneWidget,
    );
  });
}
