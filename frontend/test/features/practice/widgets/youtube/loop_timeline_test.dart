import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/loop_timeline.dart';

void main() {
  group('LoopTimeline — §4.2, §4.5', () {
    testWidgets('renders without exceptions with full duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopTimeline(
              totalDurationSeconds: 180,
              currentPositionSeconds: 50,
              startSeconds: 42,
              endSeconds: 75,
              onStartChanged: (_) {},
              onEndChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0:42'), findsWidgets);
      expect(find.text('1:15'), findsWidgets);
    });

    testWidgets('renders inside narrow column (regression)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: LoopTimeline(
                totalDurationSeconds: 90,
                currentPositionSeconds: 0,
                startSeconds: 10,
                endSeconds: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders when no callbacks are provided (read-only)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopTimeline(
              totalDurationSeconds: 60,
              currentPositionSeconds: 30,
              startSeconds: 0,
              endSeconds: 60,
              editable: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders memo dots without exceptions (#510)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopTimeline(
              totalDurationSeconds: 180,
              currentPositionSeconds: 50,
              startSeconds: 0,
              endSeconds: 180,
              memoSeconds: const [15, 60, 120],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
