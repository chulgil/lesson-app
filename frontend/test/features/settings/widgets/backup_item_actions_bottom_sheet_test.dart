// Widget smoke test (HARD-GATE) for BackupItemActionsBottomSheet.
//
// Asserts the sheet renders without RenderBox / BoxConstraints crashes that
// flutter analyze cannot detect, and that each action returns the right
// BackupItemActionResult.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/settings/presentation/widgets/backup_item_actions_bottom_sheet.dart';

void main() {
  testWidgets('renders all three actions (복원/공유/삭제)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => BackupItemActionsBottomSheet.show(context),
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
    expect(find.text(AppStrings.backupActionsSheetTitle), findsOneWidget);
    expect(find.text(AppStrings.backupActionsRestore), findsOneWidget);
    expect(find.text(AppStrings.backupActionsShare), findsOneWidget);
    expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);
  });

  testWidgets('tapping 삭제 returns BackupItemActionResult.delete', (
    tester,
  ) async {
    BackupItemActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await BackupItemActionsBottomSheet.show(context);
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

    expect(result, BackupItemActionResult.delete);
  });

  testWidgets('tapping 복원 returns BackupItemActionResult.restore', (
    tester,
  ) async {
    BackupItemActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await BackupItemActionsBottomSheet.show(context);
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
    await tester.tap(find.text(AppStrings.backupActionsRestore));
    await tester.pumpAndSettle();

    expect(result, BackupItemActionResult.restore);
  });

  testWidgets('tapping 공유 returns BackupItemActionResult.share', (
    tester,
  ) async {
    BackupItemActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await BackupItemActionsBottomSheet.show(context);
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
    await tester.tap(find.text(AppStrings.backupActionsShare));
    await tester.pumpAndSettle();

    expect(result, BackupItemActionResult.share);
  });
}
