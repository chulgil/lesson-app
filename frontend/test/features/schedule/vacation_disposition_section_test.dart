import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

/// Disposition section smoke tests — H-001 spec §4.1 step 3.
///
/// The disposition section only renders once the impact preview has loaded
/// (progressive disclosure — UI complexity audit rank 5), so every test sets
/// a valid draft range first and lets the auto-load settle before asserting.
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
  Future<List<VacationPeriod>> registerVacationBatch({
    required List<VacationSegment> segments,
    String? reason,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async => throw UnimplementedError();

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async {
    throw UnimplementedError();
  }
}

void main() {
  // Future date so hasValidDraft (no past start) always holds.
  final base = DateTime.now().add(const Duration(days: 10));

  group('Disposition section smoke — H-001 §4.1 step 3', () {
    /// Pumps the screen, sets a valid draft range on the notifier (triggers
    /// the impact auto-load), and settles — the disposition section only
    /// appears once that impact preview has resolved.
    Future<ProviderContainer> pumpWithValidDraft(WidgetTester tester) async {
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
      final notifier = container.read(vacationFormProvider.notifier);
      notifier.setDraftStart(base);
      notifier.setDraftEnd(base.add(const Duration(days: 2)));
      await tester.pumpAndSettle();
      return container;
    }

    /// Scrolls the given text into view before asserting it renders — the
    /// disposition section can sit below the fold once the (also auto-loaded)
    /// impact section is stacked above it.
    Future<void> expectVisible(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(text), findsOneWidget);
    }

    testWidgets('renders three options with the recommended badge', (
      tester,
    ) async {
      await pumpWithValidDraft(tester);
      expect(tester.takeException(), isNull);
      await expectVisible(tester, '어떻게 처리할까요?');
      await expectVisible(tester, '보강 크레딧 적립');
      await expectVisible(tester, '무료 처리');
      await expectVisible(tester, '다음 회차로 이월');
      await expectVisible(tester, '권장');
    });

    // #784 — student-perspective hints visible
    testWidgets('student-perspective hints are rendered for each option', (
      tester,
    ) async {
      await pumpWithValidDraft(tester);
      expect(tester.takeException(), isNull);
      await expectVisible(tester, '보강 1회를 적립해 나중에 사용해요 (환불 아님)');
      await expectVisible(tester, '수강권 차감 없이 휴강 처리해요 (환불 아님)');
      await expectVisible(tester, '다음 회차로 밀리고, 수강권 유효기간이 자동 연장돼요');
      // Recommended badge explanation.
      await expectVisible(tester, '학생에게 유연성이 가장 높은 방식이에요');
    });

    // #784 — narrow 320px layout regression
    testWidgets('renders without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithValidDraft(tester);
      // Scroll the disposition section into view so its narrow-width layout
      // is actually built and laid out under the 320px constraint.
      await expectVisible(tester, '어떻게 처리할까요?');
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an option updates the form state', (tester) async {
      final container = await pumpWithValidDraft(tester);
      // Default disposition = rollForward.
      expect(
        container.read(vacationFormProvider).draftDisposition,
        VacationDisposition.rollForward,
      );

      // Tap the "보강 크레딧 적립" row.
      await tester.scrollUntilVisible(
        find.text('보강 크레딧 적립'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('보강 크레딧 적립'));
      await tester.pumpAndSettle();
      expect(
        container.read(vacationFormProvider).draftDisposition,
        VacationDisposition.makeupCredit,
      );

      // Tap the "무료 처리" row.
      await tester.scrollUntilVisible(
        find.text('무료 처리'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('무료 처리'));
      await tester.pumpAndSettle();
      expect(
        container.read(vacationFormProvider).draftDisposition,
        VacationDisposition.freeCancel,
      );
    });
  });
}
