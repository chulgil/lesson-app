import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

/// #768 ② — 다구간 휴가: 여러 구간을 쌓아 한 번에 배치 등록한다.
///
/// 데이터 무결성 핵심: 구간별 보상옵션(disposition)이 그대로 배치 호출에 전달되어야
/// BE 가 구간마다 올바르게 차감/연장한다. (구간 추가 버튼은 addSegment 를 호출하는
/// 단순 wiring 이며 그 가드는 단위 테스트에서 직접 검증한다.)
class _SpyVacationRepository implements VacationRepository {
  List<VacationSegment>? lastSegments;
  String? lastReason;
  Map<String, VacationDisposition>? lastPerStudent;
  int batchCount = 0;

  @override
  Future<List<VacationPeriod>> registerVacationBatch({
    required List<VacationSegment> segments,
    String? reason,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async {
    batchCount++;
    lastSegments = segments;
    lastReason = reason;
    lastPerStudent = perStudentDisposition;
    return [
      for (final s in segments)
        VacationPeriod(
          id: 'p-${s.startDate.day}',
          teacherId: 't',
          startDate: s.startDate,
          endDate: s.endDate,
          reason: reason,
          defaultDisposition: s.disposition,
          createdAt: DateTime(2026, 6, 19),
        ),
    ];
  }

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
  }) async => throw UnimplementedError();

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async => [];

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async =>
      throw UnimplementedError();
}

void main() {
  // Future dates so hasValidDraft (no past start) always holds.
  final base = DateTime.now().add(const Duration(days: 10));

  ProviderContainer makeContainer(_SpyVacationRepository spy) =>
      ProviderContainer(
        overrides: [
          vacationRepositoryProvider.overrideWithValue(spy),
          vacationListProvider.overrideWith((_) async => <VacationPeriod>[]),
        ],
      );

  void addSegment(
    VacationForm notifier,
    DateTime start,
    DateTime end,
    VacationDisposition disposition,
  ) {
    notifier.setDraftStart(start);
    notifier.setDraftEnd(end);
    notifier.setDraftDisposition(disposition);
    expect(notifier.addSegment(), isTrue);
  }

  testWidgets(
    'stacks two segments and batch-submits per-segment dispositions',
    (tester) async {
      final spy = _SpyVacationRepository();
      final container = makeContainer(spy);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final notifier = container.read(vacationFormProvider.notifier);
      addSegment(
        notifier,
        base,
        base.add(const Duration(days: 2)),
        VacationDisposition.rollForward,
      );
      addSegment(
        notifier,
        base.add(const Duration(days: 10)),
        base.add(const Duration(days: 12)),
        VacationDisposition.freeCancel,
      );
      await tester.pumpAndSettle();

      // The added-segments list renders with both committed segments.
      expect(
        find.text(AppStrings.vacationAddedSegmentsSection),
        findsOneWidget,
      );
      expect(container.read(vacationFormProvider).segments, hasLength(2));

      // Submit → confirm summary dialog → 등록.
      await tester.scrollUntilVisible(
        find.text(AppStrings.vacationRegisterButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(AppStrings.vacationRegisterButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.vacationSummaryTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.vacationSummaryConfirm));
      await tester.pumpAndSettle();

      // Batch called once; each segment keeps its own disposition.
      expect(spy.batchCount, 1);
      expect(spy.lastSegments, hasLength(2));
      final byDay = {
        for (final s in spy.lastSegments!) s.startDate.day: s.disposition,
      };
      expect(byDay[base.day], VacationDisposition.rollForward);
      expect(
        byDay[base.add(const Duration(days: 10)).day],
        VacationDisposition.freeCancel,
      );
    },
  );

  testWidgets('overlapping draft is rejected by the addSegment guard', (
    tester,
  ) async {
    final spy = _SpyVacationRepository();
    final container = makeContainer(spy);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TeacherVacationModeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final notifier = container.read(vacationFormProvider.notifier);
    addSegment(
      notifier,
      base,
      base.add(const Duration(days: 5)),
      VacationDisposition.rollForward,
    );

    // A draft overlapping the committed segment is flagged and not addable.
    notifier.setDraftStart(base.add(const Duration(days: 3)));
    notifier.setDraftEnd(base.add(const Duration(days: 7)));
    await tester.pumpAndSettle();
    expect(container.read(vacationFormProvider).draftOverlaps, isTrue);
    expect(notifier.addSegment(), isFalse);
    expect(container.read(vacationFormProvider).segments, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow at 375px after adding a segment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spy = _SpyVacationRepository();
    final container = makeContainer(spy);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TeacherVacationModeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    addSegment(
      container.read(vacationFormProvider.notifier),
      base,
      base.add(const Duration(days: 2)),
      VacationDisposition.rollForward,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
