import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice_journal/presentation/widgets/stamp_press_sheet.dart';

void main() {
  group('showStampPressSheet', () {
    testWidgets(
      'opens sheet, taps CTA, calls onPressed, closes without error',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed:
                          () => showStampPressSheet(
                            context,
                            onPressed: () => tapped = true,
                          ),
                      child: const Text('open'),
                    ),
                  ),
            ),
          ),
        );

        // Open the sheet
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // CTA button should be visible
        expect(find.text(AppStrings.journalStampPressCta), findsOneWidget);

        // Tap the CTA
        await tester.tap(find.text(AppStrings.journalStampPressCta));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('sheet closes after tapping CTA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed:
                        () => showStampPressSheet(context, onPressed: () {}),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.journalStampPressCta), findsOneWidget);

      await tester.tap(find.text(AppStrings.journalStampPressCta));
      await tester.pumpAndSettle();

      // Sheet should be gone
      expect(find.text(AppStrings.journalStampPressCta), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
