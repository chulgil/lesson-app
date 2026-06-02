import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

/// Per-student disposition tests — H-001 spec §4.2.
class _StubRepo implements VacationRepository {
  Map<String, VacationDisposition>? lastPerStudent;

  @override
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  }) async => VacationImpactPreview(
    startDate: startDate,
    endDate: endDate,
    impactedLessonCount: 2,
    impactedStudentCount: 2,
    impactedStudents: const [
      VacationImpactedStudent(
        studentId: 'sA',
        studentName: '민수',
        lessonCount: 1,
      ),
      VacationImpactedStudent(
        studentId: 'sB',
        studentName: '서연',
        lessonCount: 1,
      ),
    ],
  );

  @override
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async {
    lastPerStudent = perStudentDisposition;
    return VacationPeriod(
      id: 'stub',
      teacherId: 'stub-teacher',
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      defaultDisposition: defaultDisposition,
      createdAt: DateTime.now(),
    );
  }

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
  group('Per-student disposition — H-001 §4.2', () {
    test('form state setStudentOverride writes/clears entries', () {
      final container = ProviderContainer(
        overrides: [vacationRepositoryProvider.overrideWithValue(_StubRepo())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vacationFormProvider.notifier);

      // Initially empty.
      expect(container.read(vacationFormProvider).perStudentOverrides, isEmpty);

      // Set override for student A.
      notifier.setStudentOverride('sA', VacationDisposition.makeupCredit);
      expect(container.read(vacationFormProvider).perStudentOverrides, {
        'sA': VacationDisposition.makeupCredit,
      });

      // Set override for student B.
      notifier.setStudentOverride('sB', VacationDisposition.freeCancel);
      expect(container.read(vacationFormProvider).perStudentOverrides, {
        'sA': VacationDisposition.makeupCredit,
        'sB': VacationDisposition.freeCancel,
      });

      // Clear student A (pass null).
      notifier.setStudentOverride('sA', null);
      expect(container.read(vacationFormProvider).perStudentOverrides, {
        'sB': VacationDisposition.freeCancel,
      });
    });

    test('submit forwards perStudentOverrides to repository', () async {
      final repo = _StubRepo();
      final container = ProviderContainer(
        overrides: [vacationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vacationFormProvider.notifier);
      notifier.setStartDate(DateTime(2026, 8, 1));
      notifier.setEndDate(DateTime(2026, 8, 5));
      notifier.setStudentOverride('sA', VacationDisposition.makeupCredit);

      final period = await notifier.submit();
      expect(period, isNotNull);
      expect(repo.lastPerStudent, {'sA': VacationDisposition.makeupCredit});
    });

    test('submit sends null when overrides map is empty', () async {
      final repo = _StubRepo();
      final container = ProviderContainer(
        overrides: [vacationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vacationFormProvider.notifier);
      notifier.setStartDate(DateTime(2026, 8, 1));
      notifier.setEndDate(DateTime(2026, 8, 5));

      await notifier.submit();
      expect(repo.lastPerStudent, isNull);
    });

    testWidgets('row shows "다른 처리: ..." badge when override exists', (
      tester,
    ) async {
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
      // Set date range so impact preview can be loaded.
      final notifier = container.read(vacationFormProvider.notifier);
      notifier.setStartDate(DateTime(2026, 8, 1));
      notifier.setEndDate(DateTime(2026, 8, 5));
      await notifier.loadImpact();

      // Apply an override before pumping again.
      notifier.setStudentOverride('sA', VacationDisposition.makeupCredit);
      await tester.pumpAndSettle();

      expect(find.text('민수'), findsOneWidget);
      expect(find.text('다른 처리: 보강 크레딧 적립'), findsOneWidget);
    });
  });
}
