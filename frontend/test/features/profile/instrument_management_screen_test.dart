import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/profile/presentation/screens/instrument_management_screen.dart';

/// Widget smoke test (HARD-GATE) for InstrumentManagementScreen.
///
/// Asserts the screen renders without runtime crashes that `flutter analyze`
/// cannot detect, and that the instrument row uses SwipeActionTile instead of
/// a trailing IconButton (issue #659 — swipe consistency C3).
void main() {
  testWidgets('InstrumentManagementScreen renders without crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const InstrumentManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(AppStrings.profileInstrumentTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'InstrumentManagementScreen instrument row uses SwipeActionTile (no trailing delete IconButton)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const InstrumentManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // At least one instrument row must be wrapped in SwipeActionTile.
      expect(find.byType(SwipeActionTile), findsWidgets);

      // No trailing delete IconButton inside the list — delete moved to swipe.
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );
}
