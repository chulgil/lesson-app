import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/proposal_card_widgets.dart';

/// #773 — 입금 대기 카드의 "입금 계좌 재확인" affordance.
///
/// 결제 후 계좌 카드가 숨겨져 통장 대조가 불가하던 문제를 위해, 대기 상태에서
/// 계좌를 다시 볼 수 있는 링크를 노출한다. renewal 등 계좌 컨텍스트가 없는
/// 화면(콜백 미전달)에서는 링크가 나타나지 않아야 한다.
void main() {
  group('ProposalWaitingCard 입금 계좌 재확인', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required VoidCallback onContactTapped,
      VoidCallback? onReconfirmAccount,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProposalWaitingCard(
                onContactTapped: onContactTapped,
                onReconfirmAccount: onReconfirmAccount,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the re-confirm link and invokes it once', (
      tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        onContactTapped: () {},
        onReconfirmAccount: () => taps++,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.proposalReconfirmAccountCta), findsOneWidget);

      await tester.tap(find.text(AppStrings.proposalReconfirmAccountCta));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('hides the re-confirm link when no callback is given', (
      tester,
    ) async {
      await pumpCard(tester, onContactTapped: () {});
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.proposalReconfirmAccountCta), findsNothing);
    });

    testWidgets('renders without overflow at narrow (375) width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpCard(tester, onContactTapped: () {}, onReconfirmAccount: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
