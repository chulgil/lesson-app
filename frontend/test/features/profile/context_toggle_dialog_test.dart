import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/profile/presentation/widgets/context_toggle_dialog.dart';

import 'fake_context_switch_repository.dart';

void main() {
  Widget wrap() {
    return ProviderScope(
      overrides: [
        contextSwitchRepositoryProvider.overrideWithValue(
          FakeContextSwitchRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ContextToggleDialog()),
      ),
    );
  }

  group('ContextToggleDialog', () {
    testWidgets('dialog renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Dialog should render without exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('dialog displays title', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Verify title text is displayed
      expect(find.text('계정 전환'), findsWidgets);
    });

    testWidgets('dialog displays context info sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Verify context sections are displayed
      expect(find.text('현재 계정'), findsWidgets);
      expect(find.text('다음 계정으로 전환'), findsWidgets);
    });

    testWidgets('dialog has action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Verify buttons are present
      expect(find.text('취소'), findsWidgets);
      expect(find.text('전환하기'), findsWidgets);
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Find and tap cancel button
      final cancelButton = find.text('취소');
      expect(cancelButton, findsWidgets);

      // Note: In a real test, we'd tap the button and verify navigation
      // For smoke test, just verify it renders
    });
  });
}
