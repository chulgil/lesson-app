import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/profile/presentation/widgets/context_toggle_button.dart';

void main() {
  group('ContextToggleButton', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ContextToggleButton())),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('buildMenuItem returns null when user lacks both roles', (
      WidgetTester tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final result = await ContextToggleButton.buildMenuItem(
        capturedContext,
        <AcademyMember>[],
      );

      expect(result, isNull);
    });
  });
}
