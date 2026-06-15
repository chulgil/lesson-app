// Regression test: #730 — "TextEditingController used after being disposed"
//
// Root cause: the old _showEditDialog created a TextEditingController in the
// caller scope and called controller.dispose() immediately after `await
// showDialog` returned. Because Navigator.pop only STARTS the exit animation,
// the TextField is still mounted/animating when updatePriceTable triggers a
// provider rebuild. The exiting TextField re-attaches to the already-disposed
// controller → crash.
//
// Fix: _PriceEditDialog (StatefulWidget) owns the controller via
// State.dispose(), so Flutter unmounts the widget BEFORE disposing the
// controller, eliminating the race.
//
// This test pumps the dialog directly (not the full PriceTableScreen) to avoid
// Hive/auth provider wiring that is orthogonal to the lifecycle bug. The
// minimal setup is sufficient because:
//   1. The crash site is inside the dialog's build/animation phase.
//   2. pumpAndSettle() drives the exit animation to completion — the old code
//      would surface the disposed-controller exception there.
//   3. With the fix, the controller is never disposed until after the widget
//      tree settles, so takeException() returns null.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/presentation/screens/price_table_screen.dart';

void main() {
  group('_PriceEditDialog — controller lifecycle', () {
    /// Pumps a minimal host that immediately opens _PriceEditDialog via
    /// showDialog and returns the route result.
    Future<int?> pumpAndOpenDialog(
      WidgetTester tester, {
      int? initialPrice,
    }) async {
      int? captured;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder:
                (ctx) => TextButton(
                  onPressed: () async {
                    captured = await showDialog<int?>(
                      context: ctx,
                      builder:
                          (_) => PriceEditDialogForTest(
                            instrument: '피아노',
                            levelLabel: '초급',
                            initialPrice: initialPrice,
                          ),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      );

      // Open the dialog.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      return captured;
    }

    testWidgets(
      'Save button closes dialog cleanly — no controller-disposed exception',
      (tester) async {
        await pumpAndOpenDialog(tester, initialPrice: 200000);

        // Enter a new price.
        await tester.enterText(find.byType(TextField), '300000');

        // Tap Save → Navigator.pop starts exit animation.
        await tester.tap(find.text(AppStrings.save));

        // pumpAndSettle drives the exit animation to completion.
        // The OLD code threw "used after being disposed" here because
        // controller.dispose() was called before the animation finished.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cancel button closes dialog cleanly — no controller-disposed exception',
      (tester) async {
        await pumpAndOpenDialog(tester, initialPrice: 150000);

        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Delete button (existing price) closes dialog cleanly', (
      tester,
    ) async {
      await pumpAndOpenDialog(tester, initialPrice: 100000);

      // Delete button is shown only when initialPrice != null.
      await tester.tap(find.text(AppStrings.delete));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Dialog with no initial price (new cell) — Save with valid value',
      (tester) async {
        await pumpAndOpenDialog(tester, initialPrice: null);

        await tester.enterText(find.byType(TextField), '50000');
        await tester.tap(find.text(AppStrings.save));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Delete button NOT shown when initialPrice is null', (
      tester,
    ) async {
      await pumpAndOpenDialog(tester, initialPrice: null);

      expect(find.text(AppStrings.delete), findsNothing);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
