import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/widgets/quick_record/quick_record_button.dart';

void main() {
  group('QuickRecordButton', () {
    testWidgets('renders without layout errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: QuickRecordButton(onPressed: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.quickRecordButton), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: QuickRecordButton(onPressed: () => tapCount++)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(QuickRecordButton));
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
    });

    testWidgets('does not invoke onPressed when disabled', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuickRecordButton(
                onPressed: () => tapCount++,
                isEnabled: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(QuickRecordButton));
      await tester.pumpAndSettle();

      expect(tapCount, equals(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'survives Row/Align compact layout without BoxConstraints crash',
      (tester) async {
        // Regression: theme minimumSize=Size(∞, h) inside compact layouts.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [QuickRecordButton(onPressed: () {})],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
