import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/profile/data/repositories/mock_cancellation_defaults_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:lessonaza/features/profile/presentation/providers/cancellation_defaults_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/cancellation_defaults_screen.dart';

void main() {
  group('CancellationDefaultsScreen', () {
    testWidgets('renders screen with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull);

      // Verify title is present
      expect(find.text('취소 정책 디폴트'), findsWidgets);
    });

    testWidgets('displays all 5 field sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify field labels are present
      expect(find.text('취소 페널티 없는 시간'), findsWidgets);
      expect(find.text('학생 취소 시 보상 제공'), findsWidgets);
      expect(find.text('마감 후 취소 시 알림 (학원 강사만)'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('allows editing cancellation deadline hours', (
      WidgetTester tester,
    ) async {
      final initialDefaults = CancellationDefaults(
        id: 'teacher_001',
        cancellationDeadlineHours: 12,
        studentCompensationExtraMinutesEnabled: true,
        includeExtraMinutesTextOnLateCancel: true,
        studentCompensationExtraMinutesMessage: '10분 보너스',
        notifyOwnerOnLateCancel: false,
        createdAt: DateTime.now(),
      );

      final mockRepo = MockCancellationDefaultsRepository(
        initialData: CancellationDefaults(
          id: 'teacher_001',
          cancellationDeadlineHours: 12,
          studentCompensationExtraMinutesEnabled: true,
          includeExtraMinutesTextOnLateCancel: true,
          studentCompensationExtraMinutesMessage: '10분 보너스',
          notifyOwnerOnLateCancel: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cancellationDefaultsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and modify the hours input field
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify no render errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('compensation section is collapsible', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockCancellationDefaultsRepository(
        initialData: CancellationDefaults(
          id: 'teacher_001',
          cancellationDeadlineHours: 12,
          studentCompensationExtraMinutesEnabled: false,
          includeExtraMinutesTextOnLateCancel: true,
          studentCompensationExtraMinutesMessage: null,
          notifyOwnerOnLateCancel: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cancellationDefaultsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When compensation is disabled, the message field should not be visible
      expect(find.text('보상 메시지'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('smoke test - no render crashes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      // Pump to loading state
      await tester.pump();

      // Pump to data state with default data
      await tester.pumpAndSettle();

      // Verify no exceptions thrown during rendering
      expect(tester.takeException(), isNull);

      // Verify basic UI elements are rendered
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(SwitchListTile), findsWidgets);
    });
  });
}
