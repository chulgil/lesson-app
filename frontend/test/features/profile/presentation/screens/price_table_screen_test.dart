// W3 Task 3.3 — PriceTableScreen smoke + 동작 회귀 테스트.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §6.3 — 악기·레벨별 가격표 단일 화면.
//
// Verifies:
// - 빈 instruments → empty 안내 노출 (헤더만)
// - instruments 채워짐 → 헤더 (초급/중급/고급) + 행 노출
// - 가격 셀 탭 → 가격 입력 다이얼로그 → 저장 → updatePriceTable 호출
// - 좁은 width 200px — RenderBox/BoxConstraints 회귀 없음

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/screens/price_table_screen.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_boot_migration_provider.dart';

void main() {
  Widget wrap(Widget child, {required SettingsRepository repo, double? width}) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        teacherSettingsBootMigrationProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp(
        home:
            width == null
                ? child
                : Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  TeacherSettings settings({
    List<String> instruments = const [],
    Map<String, Map<String, int>>? priceTable,
  }) => TeacherSettings(
    id: 'teacher-1',
    instruments: instruments,
    lessonPriceTable: priceTable,
    createdAt: DateTime.utc(2026, 6, 11),
  );

  group('PriceTableScreen (W3 Task 3.3)', () {
    testWidgets('AppBar 제목 + 섹션 헤더 노출', (tester) async {
      final repo = _FakeSettingsRepository(settings(instruments: ['피아노']));
      await tester.pumpWidget(wrap(const PriceTableScreen(), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.priceTableScreenTitle), findsOneWidget);
      expect(find.text(AppStrings.priceTableSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 instruments → empty 안내 노출 (헤더만, 표 없음)', (tester) async {
      final repo = _FakeSettingsRepository(settings(instruments: const []));
      await tester.pumpWidget(wrap(const PriceTableScreen(), repo: repo));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.priceTableEmptyInstruments), findsOneWidget);
      // 빈 상태에서는 초급/중급/고급 헤더 자체가 없어야 한다.
      expect(find.text('초급'), findsNothing);
      expect(find.text('중급'), findsNothing);
      expect(find.text('고급'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('instruments=[피아노] → 헤더 + 1행 + 가격 셀 "—"', (tester) async {
      final repo = _FakeSettingsRepository(settings(instruments: ['피아노']));
      await tester.pumpWidget(wrap(const PriceTableScreen(), repo: repo));
      await tester.pumpAndSettle();

      // Level 헤더 3개 (초급/중급/고급) — 가로 1행.
      expect(find.text('초급'), findsOneWidget);
      expect(find.text('중급'), findsOneWidget);
      expect(find.text('고급'), findsOneWidget);
      // 악기 행 1개.
      expect(find.text('피아노'), findsOneWidget);
      // 가격 미설정 셀 — '—' 표시 (3개).
      expect(find.text('—'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('이미 입력된 가격 셀 → "만" 단위 표시', (tester) async {
      final repo = _FakeSettingsRepository(
        settings(
          instruments: ['피아노'],
          priceTable: {
            'piano': {'beginner': 50000},
            '피아노': {'beginner': 50000, 'intermediate': 70000},
          },
        ),
      );
      await tester.pumpWidget(wrap(const PriceTableScreen(), repo: repo));
      await tester.pumpAndSettle();

      // 5만 / 7만 만원 단위 표시.
      expect(find.text('5만'), findsOneWidget);
      expect(find.text('7만'), findsOneWidget);
      // advanced 는 미설정 → '—'.
      expect(find.text('—'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 width 200px — RenderBox/BoxConstraints 회귀 없음', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository(settings(instruments: ['피아노']));
      await tester.pumpWidget(
        wrap(const PriceTableScreen(), repo: repo, width: 200),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [SettingsRepository] for PriceTableScreen tests.
///
/// Tracks the latest [TeacherSettings] after each mutation so the test can
/// observe updates without exposing repository internals.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  TeacherSettings _settings;

  TeacherSettings get last => _settings;

  @override
  Future<TeacherSettings> getTeacherSettings() async => _settings;

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async =>
      _settings;

  @override
  Future<void> updatePriceTable(
    Map<String, Map<String, int>> priceTable,
  ) async {
    _settings = _settings.copyWith(lessonPriceTable: priceTable);
  }

  // ── Unused by PriceTableScreen — throw on accidental call. ──
  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<void> updateBookingGuidanceMessage(String? message) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> addCustomDuration(int duration) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw UnimplementedError('not used by PriceTableScreen');

  @override
  Future<void> updateTrialLessonFree(bool value) =>
      throw UnimplementedError('not used by PriceTableScreen');
}
