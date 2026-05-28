import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/profile/presentation/widgets/context_toggle_button.dart';

void main() {
  group('ContextToggleButton', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProviderScope(child: ContextToggleButton())),
        ),
      );

      // Widget should render without exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('buildMenuItem returns null when user lacks both roles', (
      WidgetTester tester,
    ) async {
      const mockContext = GlobalObjectKey<NavigatorState>('test');
      final mockMembers = <AcademyMember>[]; // Empty — no roles

      final result = await ContextToggleButton.buildMenuItem(
        mockContext.currentContext ?? (throw StateError('No context')),
        mockMembers,
      );

      // Should return null when roles are missing
      expect(result, isNull);
    });
  });
}
