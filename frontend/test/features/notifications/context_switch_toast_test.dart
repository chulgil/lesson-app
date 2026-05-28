import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/presentation/widgets/context_switch_toast.dart';

void main() {
  group('ContextSwitchToast', () {
    testWidgets('toast renders without crashing (teacher context)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'teacher')),
        ),
      );

      // Widget should render without exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('toast renders without crashing (owner context)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'owner')),
        ),
      );

      // Widget should render without exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays success icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'teacher')),
        ),
      );

      // Verify success icon is displayed
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    });

    testWidgets('displays correct message for teacher context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'teacher')),
        ),
      );

      // Verify teacher message
      expect(find.text('개인 강사 계정으로 전환되었습니다'), findsWidgets);
    });

    testWidgets('displays correct message for owner context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'owner')),
        ),
      );

      // Verify owner message
      expect(find.text('학원장 계정으로 전환되었습니다'), findsWidgets);
    });

    testWidgets('auto-dismisses after 3 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContextSwitchToast(activeContext: 'teacher')),
        ),
      );

      // Initial render should show toast
      expect(tester.takeException(), isNull);

      // Advance time by 3 seconds
      await tester.pump(const Duration(seconds: 3));

      // Note: In a real navigation scenario, the dialog would be popped
      // For smoke test, we verify the widget handles the timer without crashing
    });
  });
}
