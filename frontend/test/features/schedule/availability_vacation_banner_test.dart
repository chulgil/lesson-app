import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/availability/availability_vacation_banner.dart';

/// #431 §4 — availability 화면 휴가 구간 시각화 배너 smoke.
class _StubVacationRepository implements VacationRepository {
  _StubVacationRepository(this._periods);

  final List<VacationPeriod> _periods;

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async => _periods;

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
  Future<List<VacationPeriod>> registerVacationBatch({
    required List<VacationSegment> segments,
    String? reason,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async => throw UnimplementedError();

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async =>
      throw UnimplementedError();
}

VacationPeriod _period({
  DateTime? cancelledAt,
  String? reason,
  DateTime? startDate,
  DateTime? endDate,
}) => VacationPeriod(
  id: 'v1',
  teacherId: 't1',
  startDate: startDate ?? DateTime(2026, 7, 15),
  endDate: endDate ?? DateTime(2026, 8, 31),
  reason: reason,
  defaultDisposition: VacationDisposition.rollForward,
  cancelledAt: cancelledAt,
  createdAt: DateTime(2026, 6, 1),
);

Future<void> _pump(WidgetTester tester, List<VacationPeriod> periods) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vacationRepositoryProvider.overrideWithValue(
          _StubVacationRepository(periods),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AvailabilityVacationBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AvailabilityVacationBanner', () {
    testWidgets('shows banner with active vacation range (휴가 label)', (
      tester,
    ) async {
      // Must span today: a vacation that already started and has not ended
      // (#fix2 — future-start vacations are "scheduled", not active).
      // C4 (audit §4.10): multi-day vacation uses 휴가 suffix.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(const Duration(days: 2));
      final end = today.add(const Duration(days: 5));
      await _pump(tester, [
        _period(reason: '여름방학', startDate: start, endDate: end),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationBannerTitle), findsOneWidget);
      final range = '${start.month}/${start.day} ~ ${end.month}/${end.day}';
      expect(
        find.text(AppStrings.vacationBannerRangeLabel(range)),
        findsOneWidget,
      );
      expect(find.text('여름방학'), findsOneWidget);
    });

    // C2 (audit §4.8) — trailing close icon offers the cancel action.
    testWidgets('shows cancel close icon for active vacation', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await _pump(tester, [
        _period(
          startDate: today.subtract(const Duration(days: 1)),
          endDate: today.add(const Duration(days: 3)),
        ),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    // C4 (audit §4.10) — 1-day vacation uses 휴무 label + event_busy icon.
    testWidgets('1-day vacation uses 휴무 label and event_busy icon', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await _pump(tester, [_period(startDate: today, endDate: today)]);
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          AppStrings.vacationBannerOneDayLabel('${today.month}/${today.day}'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    // C4 (audit §4.10) — multi-day vacation uses beach_access icon.
    testWidgets('multi-day vacation uses beach_access icon', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await _pump(tester, [
        _period(startDate: today, endDate: today.add(const Duration(days: 4))),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.beach_access), findsOneWidget);
    });

    // Regression (#fix2): a vacation that starts in the future is "scheduled",
    // not active — the banner must stay hidden until it begins.
    testWidgets('hides when vacation starts in the future', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await _pump(tester, [
        _period(
          startDate: today.add(const Duration(days: 10)),
          endDate: today.add(const Duration(days: 20)),
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationBannerTitle), findsNothing);
    });

    testWidgets('hides when no active vacation', (tester) async {
      await _pump(tester, [_period(cancelledAt: DateTime(2026, 6, 2))]);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationBannerTitle), findsNothing);
    });

    // Regression (#bug4): a vacation whose end date has already passed must
    // not be shown as active, even when it was never cancelled.
    testWidgets('hides when vacation has already ended', (tester) async {
      final past = DateTime.now().subtract(const Duration(days: 10));
      await _pump(tester, [
        _period(
          startDate: past.subtract(const Duration(days: 5)),
          endDate: past,
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationBannerTitle), findsNothing);
    });

    // Regression (#bug4): a vacation ending today (date-only) stays active.
    testWidgets('shows when vacation ends today', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await _pump(tester, [
        _period(
          startDate: today.subtract(const Duration(days: 3)),
          endDate: today,
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationBannerTitle), findsOneWidget);
    });
  });
}
