import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/profile/presentation/widgets/context_toggle_button.dart';

import 'fake_context_switch_repository.dart';

void main() {
  group('ContextToggleButton', () {
    testWidgets('renders the toggle row when 2+ contexts are available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contextSwitchRepositoryProvider.overrideWithValue(
              FakeContextSwitchRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ContextToggleButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('hides the toggle row for single-context users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contextSwitchRepositoryProvider.overrideWithValue(
              FakeContextSwitchRepository(
                info: const ContextInfo(
                  userId: 'u',
                  activeContext: 'teacher',
                  availableContexts: [
                    AvailableContext(
                      context: 'teacher',
                      academyId: 'a',
                      label: '강사',
                      memberId: 'm',
                    ),
                  ],
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ContextToggleButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsNothing);
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
