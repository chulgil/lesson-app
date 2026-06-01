import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/widgets/verification_badge_chip.dart';

/// #430 후속 — 선생님 인증 배지 칩 위젯 스모크 테스트.
///
/// `VerificationBadge` enum 3가지 케이스가 모두 크래시 없이 렌더되고
/// 라벨/아이콘이 의도한 값으로 표시되는지 확인한다.
void main() {
  group('VerificationBadgeChip', () {
    Future<void> pumpChip(WidgetTester tester, VerificationBadge badge) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: VerificationBadgeChip(badge: badge)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('phoneVerified renders without exception and shows label', (
      tester,
    ) async {
      await pumpChip(tester, VerificationBadge.phoneVerified);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.verificationBadgePhoneLabel), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    });

    testWidgets('certified renders without exception and shows label', (
      tester,
    ) async {
      await pumpChip(tester, VerificationBadge.certified);

      expect(tester.takeException(), isNull);
      expect(
        find.text(AppStrings.verificationBadgeCertifiedLabel),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('premium renders without exception and shows label', (
      tester,
    ) async {
      await pumpChip(tester, VerificationBadge.premium);

      expect(tester.takeException(), isNull);
      expect(
        find.text(AppStrings.verificationBadgePremiumLabel),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders inside a tight horizontal context without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  VerificationBadgeChip(badge: VerificationBadge.phoneVerified),
                ],
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
