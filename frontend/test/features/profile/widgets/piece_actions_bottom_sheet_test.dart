// Widget smoke test (HARD-GATE) for PieceActionsBottomSheet.
//
// Asserts the sheet renders without RenderBox / BoxConstraints crashes that
// flutter analyze cannot detect, and that each action returns the right
// PieceActionResult.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/presentation/widgets/piece_actions_bottom_sheet.dart';

void main() {
  testWidgets('renders all three actions (편집/배정/삭제)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => PieceActionsBottomSheet.show(context),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.pieceActionsSheetTitle), findsOneWidget);
    expect(find.text(AppStrings.pieceActionsEdit), findsOneWidget);
    expect(find.text(AppStrings.pieceActionsAssign), findsOneWidget);
    expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);
  });

  testWidgets('tapping 삭제 returns PieceActionResult.delete', (tester) async {
    PieceActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await PieceActionsBottomSheet.show(context);
                    },
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.swipeActionDelete));
    await tester.pumpAndSettle();

    expect(result, PieceActionResult.delete);
  });

  testWidgets('tapping 편집 returns PieceActionResult.edit', (tester) async {
    PieceActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await PieceActionsBottomSheet.show(context);
                    },
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.pieceActionsEdit));
    await tester.pumpAndSettle();

    expect(result, PieceActionResult.edit);
  });

  testWidgets('tapping 배정 returns PieceActionResult.assign', (tester) async {
    PieceActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await PieceActionsBottomSheet.show(context);
                    },
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.pieceActionsAssign));
    await tester.pumpAndSettle();

    expect(result, PieceActionResult.assign);
  });
}
