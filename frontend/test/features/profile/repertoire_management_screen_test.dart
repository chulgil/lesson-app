// Interaction-driving smoke test for RepertoireManagementScreen.
//
// Contract (ux-rules.md HARD-GATE §731):
//   Drive the screen's primary interactions — open the add-piece dialog,
//   enter a title, tap Save — then expect(tester.takeException(), isNull).
//
// Why this screen:
//   RepertoireManagementScreen shows showDialog(PieceDialog) when the user
//   taps the add (+) action.  PieceDialog owns 5 TextEditingControllers in
//   its State.  If any controller were disposed before the dialog's exit
//   animation completes (the #730 controller-dispose crash class), the race
//   surfaces in pumpAndSettle() as a "used after being disposed" exception.
//   pump-only never opens the dialog, so it cannot catch this class of crash.
//
// Provider wiring: pieceRepositoryProvider → MockPieceRepository (no auth).
//   studentsNotifierProvider is referenced only in _assignPieceToStudents;
//   that path is not exercised here, so no override is required.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_piece_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/piece_repository_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/repertoire_management_screen.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      pieceRepositoryProvider.overrideWithValue(MockPieceRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const RepertoireManagementScreen(),
    ),
  );
}

void main() {
  group('RepertoireManagementScreen — interaction smoke (HARD-GATE §731)', () {
    testWidgets('renders AppBar title without crash', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(AppStrings.profileRepertoireTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'tap add action → PieceDialog opens → tap cancel → no exception',
      (tester) async {
        // This exercises PieceDialog's TextEditingController lifecycle:
        // 5 controllers are created in initState and disposed in dispose().
        // If dispose() races with exit animation, pumpAndSettle() surfaces it.
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Tap the '+' add action in the AppBar (DetailAppBarAction.add).
        final addIcon = find.byIcon(Icons.add);
        expect(addIcon, findsOneWidget);
        await tester.tap(addIcon);
        await tester.pumpAndSettle();

        // Dialog title should be visible.
        expect(
          find.text(AppStrings.profileRepertoirePieceAddTitle),
          findsOneWidget,
        );

        // Tap Cancel → triggers exit animation.
        await tester.tap(find.text(AppStrings.cancel));

        // Drive the animation to completion — controller-dispose race surfaces here.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('tap add → enter title → tap save → no exception', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter a piece title (required field) in the first TextFormField.
      await tester.enterText(find.byType(TextFormField).first, '바흐 파르티타');

      // Tap Save button.
      await tester.tap(find.text(AppStrings.save));

      // pumpAndSettle drives mock addPiece() + dialog exit animation.
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
