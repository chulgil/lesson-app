// #930 / #118 — Kakao & Apple login buttons must be visually disabled
// (non-interactive) with a "준비중" badge until SDK integration.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/screens/login_screen.dart';

void main() {
  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataModeProvider.overrideWith(() => DataMode())],
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('#118 Kakao/Apple 버튼은 탭해도 Snackbar가 표시되지 않는다', (tester) async {
    await pumpLoginScreen(tester);

    await tester.tap(find.text('Kakao로 시작'));
    await tester.pumpAndSettle();
    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'NO-OP snackbar가 제거되었으므로 표시되면 안 됨',
    );

    await tester.tap(find.text('Apple 계정으로 시작'));
    await tester.pumpAndSettle();
    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'NO-OP snackbar가 제거되었으므로 표시되면 안 됨',
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('#118 준비중 배지가 Kakao·Apple 버튼에 표시된다', (tester) async {
    await pumpLoginScreen(tester);

    // Two "준비중" badges should appear (one per disabled button)
    expect(
      find.text(AppStrings.authComingSoonBadge),
      findsNWidgets(2),
      reason: 'Kakao, Apple 버튼 각각 배지가 있어야 함',
    );
    expect(tester.takeException(), isNull);
  });
}
