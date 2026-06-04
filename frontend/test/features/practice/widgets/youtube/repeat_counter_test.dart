import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/repeat_counter.dart';

void main() {
  group('RepeatCounter — §4.6', () {
    testWidgets('renders 0/5 at start without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RepeatCounter(completed: 0, target: 5)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders 3/5 and progress bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RepeatCounter(completed: 3, target: 5)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders inside narrow column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: RepeatCounter(completed: 7, target: 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
