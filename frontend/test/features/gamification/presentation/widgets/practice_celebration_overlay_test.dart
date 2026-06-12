import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_celebration_overlay.dart';

Future<void> _pump(
  WidgetTester tester, {
  int minutes = 12,
  int streak = 3,
  required VoidCallback onDismiss,
  Duration total = const Duration(milliseconds: 1500),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PracticeCelebrationOverlay(
          practiceMinutes: minutes,
          streakDays: streak,
          onDismiss: onDismiss,
          totalDuration: total,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders minutes / streak / sparkle text', (tester) async {
    await _pump(tester, onDismiss: () {});
    expect(find.byKey(const ValueKey('celebration_minutes')), findsOneWidget);
    expect(find.text('12분 했어요!'), findsOneWidget);
    expect(find.byKey(const ValueKey('celebration_streak')), findsOneWidget);
    expect(find.text('🔥 3일 연속'), findsOneWidget);
    expect(find.text('✨'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // 명시적으로 timer 회수
    await tester.pumpAndSettle();
  });

  testWidgets('invokes onDismiss after totalDuration (1500ms default)', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(tester, onDismiss: () => dismissed++);
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });

  testWidgets('does not invoke onDismiss before totalDuration elapses', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(
      tester,
      onDismiss: () => dismissed++,
      total: const Duration(milliseconds: 1000),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });

  testWidgets('onDismiss fires exactly once even with custom totalDuration', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(
      tester,
      onDismiss: () => dismissed++,
      total: const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    expect(dismissed, 1);
  });

  testWidgets('renders on narrow viewport without exception', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    await _pump(tester, minutes: 999, streak: 999, onDismiss: () {});
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
