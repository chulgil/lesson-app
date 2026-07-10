import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/presentation/screens/bank_account_edit_screen.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';

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

  testWidgets(
    'edit flow: swipe -> edit -> change holder -> save reflects in list',
    (tester) async {
      // Tall surface so the edit sheet form renders without overflow.
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const BankAccountEditScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Default mock teacher has one default account (holder '김선생').
      expect(find.text('김선생'), findsOneWidget);

      // 우->좌 swipe reveals the management actions (편집·삭제).
      await tester.drag(find.byType(SwipeActionTile), const Offset(-320, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.swipeActionEdit));
      await tester.pumpAndSettle();

      // Edit sheet opens with fields prefilled — change the account holder.
      final holderField = find.widgetWithText(TextFormField, '김선생');
      expect(holderField, findsOneWidget);
      await tester.enterText(holderField, '홍길동');

      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // List reflects the updated holder; the old value is gone.
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김선생'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
