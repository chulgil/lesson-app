import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/proposal_issued_action_bar.dart';

/// audit C2-F02 — 수강권 발급 후 첫 레슨 CTA widget smoke test.
///
/// 회귀 방지: ProposalDetailScreen 의 confirmed status 분기에서 사용되는
/// 액션바가 좁은 viewport·기본 viewport 모두에서 크래시 없이 렌더되고
/// onTap 콜백이 정확히 1회 호출됨을 보장한다.
void main() {
  group('ProposalIssuedActionBar', () {
    Future<void> pumpBar(WidgetTester tester, {required VoidCallback onTap}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ProposalIssuedActionBar(
              subscriptionId: 'sub-1',
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('renders hint, icon, and CTA label without exception', (
      tester,
    ) async {
      await pumpBar(tester, onTap: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.proposalDetailIssuedHint), findsOneWidget);
      expect(
        find.text(AppStrings.proposalDetailViewSubscriptionAction),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.event_available), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('invokes onTap exactly once when CTA is tapped', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpBar(tester, onTap: () => tapCount++);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(
          ElevatedButton,
          AppStrings.proposalDetailViewSubscriptionAction,
        ),
      );
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('renders inside a narrow mobile viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpBar(tester, onTap: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
