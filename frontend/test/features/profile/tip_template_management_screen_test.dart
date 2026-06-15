// Interaction-driving smoke test for TipTemplateManagementScreen.
//
// Contract (ux-rules.md HARD-GATE §731):
//   pump-only is not enough — drive the screen's primary interactions
//   (open each dialog/bottomSheet, tap primary actions, pumpAndSettle),
//   then expect(tester.takeException(), isNull).
//
// Why this screen:
//   TipTemplateManagementScreen shows showDialog() for add/edit/delete flows.
//   The add dialog creates a TextEditingController in _PieceDialogState; if it
//   were disposed before the exit animation settles (the #730 pattern), the
//   exiting TextField would re-attach to the disposed controller — crash.
//   Driving the dialog open + tapping Cancel exercises that lifecycle path.
//
// Provider wiring: tipTemplateRepositoryProvider → MockTipTemplateRepository
//   (no auth/network needed; mock is self-contained with seed data).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_tip_template_repository.dart';
import 'package:lessonaza/features/lessons/presentation/providers/tip_template_providers.dart';
import 'package:lessonaza/features/profile/presentation/screens/tip_template_management_screen.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      tipTemplateRepositoryProvider.overrideWithValue(
        MockTipTemplateRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const TipTemplateManagementScreen(),
    ),
  );
}

void main() {
  group('TipTemplateManagementScreen — interaction smoke (HARD-GATE §731)', () {
    testWidgets('renders without crash and shows TabBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(AppStrings.profileTipTemplateTitle), findsOneWidget);
      expect(find.text('전체'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap add action → dialog opens → cancel → no exception', (
      tester,
    ) async {
      // This path exercises the TextEditingController lifecycle:
      // initState creates controllers, Navigator.pop starts exit animation,
      // pumpAndSettle drives the animation to completion.
      // If dispose() races with a still-mounted TextField, exception surfaces here.
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap the '+' action in NotebookDetailAppBar (DetailAppBarAction.add).
      // The icon is Icons.add — find by icon widget.
      final addIcon = find.byIcon(Icons.add);
      expect(addIcon, findsOneWidget);
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      // Dialog should be visible.
      expect(
        find.text(AppStrings.profileTipTemplateAddDialogTitle),
        findsOneWidget,
      );

      // Tap Cancel to close the dialog → triggers exit animation.
      await tester.tap(find.text(AppStrings.cancel));

      // Drive the exit animation to completion — this is where controller-
      // dispose race conditions surface (the #730 crash class).
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('tap add → enter content → tap add confirm → no exception', (
      tester,
    ) async {
      // Drive the full happy path: open dialog, enter text, tap add.
      // The dialog's confirm button is AppStrings.add ('추가'), not '저장'.
      // MockTipTemplateRepository.addTemplate is async but synchronous
      // in mock — pumpAndSettle() settles the whole round-trip.
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.profileTipTemplateAddDialogTitle),
        findsOneWidget,
      );

      // Enter content into the first TextField (content hint).
      await tester.enterText(
        find.byType(TextField).first,
        '활 압력을 줄이고 가볍게 연주하세요',
      );

      // The confirm button in _showAddTemplateDialog is FilledButton(child: Text(AppStrings.add)).
      // AppStrings.add == '추가'. There are multiple '추가' texts on screen
      // (TabBar tabs don't apply here), so target the FilledButton specifically.
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.add));

      // pumpAndSettle drives addTemplate() async + dialog exit animation.
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
