import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/loop_controls.dart';

void main() {
  group('LoopControls — §4.2', () {
    testWidgets('renders 5 speed chips + repeat toggle without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopControls(
              repeatEnabled: true,
              onRepeatChanged: (_) {},
              speed: 1.0,
              onSpeedChanged: (_) {},
              onReset: () {},
              countInEnabled: false,
              onCountInChanged: (_) {},
              countInSoundEnabled: true,
              onCountInSoundChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0.25x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);
    });

    testWidgets('count-in description shows only when count-in enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoopControls(
              repeatEnabled: true,
              onRepeatChanged: (_) {},
              speed: 0.75,
              onSpeedChanged: (_) {},
              onReset: () {},
              countInEnabled: true,
              onCountInChanged: (_) {},
              countInSoundEnabled: false,
              onCountInSoundChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3-2-1 후 재생'), findsOneWidget);
    });

    testWidgets('narrow column does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LoopControls(
                repeatEnabled: false,
                onRepeatChanged: (_) {},
                speed: 1.0,
                onSpeedChanged: (_) {},
                onReset: () {},
                countInEnabled: false,
                onCountInChanged: (_) {},
                countInSoundEnabled: true,
                onCountInSoundChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
