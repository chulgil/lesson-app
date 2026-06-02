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

    testWidgets('renders both CTAs (parent + invite code)', (tester) async {
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
