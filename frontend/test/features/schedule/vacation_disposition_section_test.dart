import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

/// Disposition section smoke tests — H-001 spec §4.1 step 3.
class _StubRepo implements VacationRepository {
  @override
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  }) async => VacationImpactPreview(
    startDate: startDate,
    endDate: endDate,
    impactedLessonCount: 0,
    impactedStudentCount: 0,
  );

  @override
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async => VacationPeriod(
    id: 'stub',
    teacherId: 'stub-teacher',
    startDate: startDate,
    endDate: endDate,
    reason: reason,
    defaultDisposition: defaultDisposition,
    createdAt: DateTime.now(),
  );

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async => [];

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Disposition section smoke — H-001 §4.1 step 3', () {
    Widget _wrap() => ProviderScope(
      overrides: [
        vacationRepositoryProvider.overrideWithValue(_StubRepo()),
        vacationListProvider.overrideWith((_) async => <VacationPeriod>[]),
      ],
      child: const MaterialApp(home: TeacherVacationModeScreen()),
    );

    testWidgets('renders three options with the recommended badge', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('어떻게 처리할까요?'), findsOneWidget);
      expect(find.text('보강 크레딧 적립'), findsOneWidget);
      expect(find.text('무료 처리'), findsOneWidget);
      expect(find.text('다음 회차로 이월'), findsOneWidget);
      expect(find.text('권장'), findsOneWidget);
    });

    testWidgets('tapping an option updates the form state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vacationRepositoryProvider.overrideWithValue(_StubRepo()),
          vacationListProvider.overrideWith((_) async => <VacationPeriod>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Default disposition = rollForward.
      expect(
        container.read(vacationFormProvider).disposition,
        VacationDisposition.rollForward,
      );

      // Tap the "보강 크레딧 적립" row.
      await tester.tap(find.text('보강 크레딧 적립'));
      await tester.pumpAndSettle();
      expect(
        container.read(vacationFormProvider).disposition,
        VacationDisposition.makeupCredit,
      );

      // Tap the "무료 처리" row.
      await tester.tap(find.text('무료 처리'));
      await tester.pumpAndSettle();
      expect(
        container.read(vacationFormProvider).disposition,
        VacationDisposition.freeCancel,
      );
    });
  });
}
