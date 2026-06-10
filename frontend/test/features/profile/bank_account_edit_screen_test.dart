import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/presentation/screens/bank_account_edit_screen.dart';

/// Widget smoke test (HARD-GATE) for BankAccountEditScreen.
///
/// Asserts the screen renders without runtime crashes, and the trailing
/// delete IconButton inside `_BankAccountCard` has been removed in favor of
/// SwipeActionTile (issue #659 — swipe consistency C4).
void main() {
  testWidgets('BankAccountEditScreen renders without crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BankAccountEditScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.profileBankAccountTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'BankAccountEditScreen account card has no trailing delete IconButton',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const BankAccountEditScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // If any account row exists, it should NOT show a trailing delete icon.
      // The icon is moved into SwipeActionTile actions, which are hidden
      // until the user swipes.
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // SwipeActionTile must NOT cause a render crash even if account list
      // is empty or only the default exists (in which case no SwipeActionTile
      // is rendered for the default-only entry).
      expect(tester.takeException(), isNull);
    },
  );
}
