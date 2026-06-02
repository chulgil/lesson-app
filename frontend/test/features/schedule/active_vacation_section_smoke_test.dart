import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

void main() {
  group('Active vacation section smoke — H-001 FE Phase 3', () {
    testWidgets('renders nothing when list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vacationListProvider.overrideWith((_) async => <VacationPeriod>[]),
          ],
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('등록된 휴가'), findsNothing);
    });

    testWidgets('renders active vacation card with date range', (tester) async {
      final period = VacationPeriod(
        id: 'p-1',
        teacherId: 't-1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        reason: '여름방학',
        defaultDisposition: VacationDisposition.rollForward,
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vacationListProvider.overrideWith((_) async => [period]),
          ],
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('등록된 휴가'), findsOneWidget);
      expect(find.text('8/1 ~ 8/5'), findsOneWidget);
      expect(find.text('여름방학'), findsOneWidget);
      expect(find.text('휴가 취소'), findsOneWidget);
    });

    testWidgets('renders nothing on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vacationListProvider.overrideWith(
              (_) async => throw Exception('boom'),
            ),
          ],
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('등록된 휴가'), findsNothing);
    });
  });
}
