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
      // The section only shows *active* vacations (isActiveOn) — must span today
      // (#fix2: future-start vacations are scheduled, not active).
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(const Duration(days: 1));
      final end = today.add(const Duration(days: 4));
      final period = VacationPeriod(
        id: 'p-1',
        teacherId: 't-1',
        startDate: start,
        endDate: end,
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
      expect(
        find.text('${start.month}/${start.day} ~ ${end.month}/${end.day}'),
        findsOneWidget,
      );
      expect(find.text('여름방학'), findsOneWidget);
      expect(find.text('휴가 취소'), findsOneWidget);
    });

    testWidgets('hides section when vacation starts in the future',
        (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final period = VacationPeriod(
        id: 'p-2',
        teacherId: 't-1',
        startDate: today.add(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 15)),
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
      expect(find.text('등록된 휴가'), findsNothing);
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
