import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/student_signup_blocked_screen.dart';

/// #430 G1 B1 — 학생 직접 가입 차단 화면 스모크 테스트.
///
/// PASS 본인인증 통합 전 임시 안전망. 안내 본문 + 학부모 전환 CTA +
/// 학생 초대코드 CTA 가 모두 표시되고 크래시 없이 렌더된다.
void main() {
  group('StudentSignupBlockedScreen', () {
    Future<void> pumpScreen(WidgetTester tester) {
      return tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StudentSignupBlockedScreen()),
        ),
      );
    }

    testWidgets('renders title body and helper without exception', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.studentSignupBlockedTitle), findsOneWidget);
      expect(find.text(AppStrings.studentSignupBlockedBody), findsOneWidget);
      expect(find.text(AppStrings.studentSignupBlockedHelper), findsOneWidget);
    });

    testWidgets('renders all three CTAs (parent + invite code + no code)', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          FilledButton,
          AppStrings.studentSignupBlockedParentCta,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          OutlinedButton,
          AppStrings.studentSignupBlockedInviteCta,
        ),
        findsOneWidget,
      );
      // UXC-13 — 코드 없는 학생이 초대코드 화면을 거치지 않고 바로 체험을
      // 시작할 수 있어야 한다. 초대코드 화면의 건너뛰기와 같은 문구를 쓴다.
      expect(
        find.widgetWithText(TextButton, AppStrings.inviteCodeSkipButton),
        findsOneWidget,
      );
    });

    testWidgets('no-code CTA opens the age gate before starting', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(TextButton, AppStrings.inviteCodeSkipButton),
      );
      await tester.pumpAndSettle();

      // 만 14세 게이트는 초대코드 화면의 건너뛰기와 동일하게 유지된다.
      expect(find.text(AppStrings.authAgeGateTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside a narrow viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
