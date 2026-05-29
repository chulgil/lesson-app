// #415 R4 Phase B — FreeLimitSheet smoke + 분기 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/domain/services/billing_guard.dart';
import 'package:lessonaza/features/billing/presentation/widgets/free_limit_sheet.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SafeArea(child: child)));

  group('FreeLimitSheet — freeLimitReached', () {
    testWidgets('Free 한도 문구 + Pro/Trial/Later 세 버튼 노출', (tester) async {
      var buy = 0, trial = 0, later = 0;

      await tester.pumpWidget(
        wrap(
          FreeLimitSheet(
            reason: LimitReason.freeLimitReached,
            trialAvailable: true,
            onBuyPro: () => buy++,
            onStartTrial: () => trial++,
            onLater: () => later++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallFreeLimitTitle), findsOneWidget);
      expect(find.text(AppStrings.paywallFreeLimitSubtitle), findsOneWidget);
      expect(find.text(AppStrings.paywallProBuyCta), findsOneWidget);
      expect(find.text(AppStrings.paywallTrialStartCta), findsOneWidget);
      expect(find.text(AppStrings.paywallLaterCta), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(FreeLimitSheet.buyProButtonKey));
      await tester.tap(find.byKey(FreeLimitSheet.startTrialButtonKey));
      await tester.tap(find.byKey(FreeLimitSheet.laterButtonKey));
      await tester.pump();

      expect(buy, 1);
      expect(trial, 1);
      expect(later, 1);
    });

    testWidgets('trialUsed 이면 Trial 카드 숨김', (tester) async {
      await tester.pumpWidget(
        wrap(
          FreeLimitSheet(
            reason: LimitReason.freeLimitReached,
            trialAvailable: false,
            onBuyPro: () {},
            onStartTrial: () {},
            onLater: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(FreeLimitSheet.startTrialButtonKey), findsNothing);
      expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsOneWidget);
      expect(find.byKey(FreeLimitSheet.laterButtonKey), findsOneWidget);
    });
  });

  group('FreeLimitSheet — planExpired', () {
    testWidgets('만료 문구 + Trial 카드 강제 숨김', (tester) async {
      await tester.pumpWidget(
        wrap(
          FreeLimitSheet(
            // 만료는 trialAvailable=true 라도 trial 카드 노출 안 함.
            reason: LimitReason.planExpired,
            trialAvailable: true,
            onBuyPro: () {},
            onStartTrial: () {},
            onLater: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallPlanExpiredTitle), findsOneWidget);
      expect(find.text(AppStrings.paywallPlanExpiredSubtitle), findsOneWidget);
      expect(find.byKey(FreeLimitSheet.startTrialButtonKey), findsNothing);
      expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsOneWidget);
    });
  });

  group('FreeLimitSheet — 좁은 제약', () {
    testWidgets('좁은 폭 컨테이너에서 BoxConstraints 크래시 없음', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 280,
            child: FreeLimitSheet(
              reason: LimitReason.freeLimitReached,
              trialAvailable: true,
              onBuyPro: () {},
              onStartTrial: () {},
              onLater: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
