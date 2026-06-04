import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/count_in_overlay.dart';

void main() {
  group('CountInOverlay — §4.4', () {
    testWidgets('counts 3→2→1 then fires onCompleted', (tester) async {
      var completed = false;
      final ticks = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountInOverlay(
              beatDurationMs: 50,
              onTick: ticks.add,
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );
      // First frame should show 3.
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      // Advance through the 3 beats.
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));

      expect(completed, isTrue);
      expect(ticks, [3, 2, 1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside narrow container without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CountInOverlay(beatDurationMs: 1000, onCompleted: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
