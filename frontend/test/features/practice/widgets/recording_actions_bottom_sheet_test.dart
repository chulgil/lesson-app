// Widget smoke test (HARD-GATE) for RecordingActionsBottomSheet.
//
// Asserts the sheet renders without RenderBox / BoxConstraints crashes that
// flutter analyze cannot detect, and that the destructive [삭제] action
// returns RecordingActionResult.delete.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/practice/presentation/widgets/section_detail/recording_actions_bottom_sheet.dart';

void main() {
  testWidgets('renders all three actions when canSetRepresentative is true', (
    tester,
  ) async {
    RecordingActionResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await RecordingActionsBottomSheet.show(
                        context,
                        canSetRepresentative: true,
                      );
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

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.recordingActionsSheetTitle), findsOneWidget);
    expect(find.text(AppStrings.practiceSetRepresentative), findsOneWidget);
    expect(find.text(AppStrings.practiceShareExternal), findsOneWidget);
    expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);

    await tester.tap(find.text(AppStrings.swipeActionDelete));
    await tester.pumpAndSettle();
    expect(result, RecordingActionResult.delete);
  });

  testWidgets('hides 대표설정 action when canSetRepresentative is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed:
                        () => RecordingActionsBottomSheet.show(
                          context,
                          canSetRepresentative: false,
                        ),
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
    expect(find.text(AppStrings.practiceSetRepresentative), findsNothing);
    expect(find.text(AppStrings.practiceShareExternal), findsOneWidget);
    expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);
  });
}
