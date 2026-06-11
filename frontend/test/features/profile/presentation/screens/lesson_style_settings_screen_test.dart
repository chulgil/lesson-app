// W3 Task 3.2 — LessonStyleSettingsScreen smoke + 동작 회귀 테스트.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §6.2 — 수업방식 묶음 3 항목 (레슨 1회 시간 / 사전예약 / 학생 안내).
//
// Verifies:
// - 3 섹션 헤더 노출 (레슨 1회 시간 / 최소 사전 예약 시간 / 학생 안내 메시지)
// - 레슨 1회 시간 라디오 선택 → lessonDurationMinutes 업데이트
// - 학생 안내 메시지 미입력 → effectiveGuidanceMessage 가 defaultGuidanceMessage 로 fallback
// - 좁은 width 200px — RenderBox/BoxConstraints 회귀 없음

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/screens/lesson_style_settings_screen.dart';
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
        home: width == null
            ? child
            : Center(
                child: SizedBox(width: width, child: child),
              ),
      ),
    );
  }

  TeacherSettings defaultSettings() => TeacherSettings(
    id: 'teacher-1',
    instruments: const ['피아노'],
    createdAt: DateTime.utc(2026, 6, 11),
  );

  group('LessonStyleSettingsScreen (W3 Task 3.2)', () {
    testWidgets('3 섹션 헤더 노출 — 레슨 1회 시간/사전예약/학생 안내', (tester) async {
      final repo = _FakeSettingsRepository(defaultSettings());
      await tester.pumpWidget(
        wrap(const LessonStyleSettingsScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.lessonStyleDurationSection), findsOneWidget);
      expect(find.text(AppStrings.lessonStyleBookingSection), findsOneWidget);
      expect(find.text(AppStrings.lessonStyleGuidanceSection), findsOneWidget);
      expect(find.text(AppStrings.lessonStyleScreenTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('레슨 1회 시간 60분 라디오 탭 → lessonDurationMinutes 업데이트', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository(defaultSettings());
      await tester.pumpWidget(
        wrap(const LessonStyleSettingsScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      // 기본값 50분 시작.
      expect(repo.last.lessonDurationMinutes, 50);

      // 60분 라디오 항목 (라벨 텍스트) 탭.
      await tester.tap(find.text('60분').first);
      await tester.pumpAndSettle();

      expect(repo.last.lessonDurationMinutes, 60);
      expect(tester.takeException(), isNull);
    });

    testWidgets('학생 안내 메시지 미입력 → effectiveGuidanceMessage 가 기본 메시지로 fallback', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository(defaultSettings());
      await tester.pumpWidget(
        wrap(const LessonStyleSettingsScreen(), repo: repo),
      );
      await tester.pumpAndSettle();

      // 초기 상태 — bookingGuidanceMessage 가 null.
      expect(repo.last.bookingGuidanceMessage, isNull);
      // effectiveGuidanceMessage 는 entity 의 defaultGuidanceMessage 와 동일.
      expect(
        repo.last.effectiveGuidanceMessage,
        TeacherSettings.defaultGuidanceMessage,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 width 200px — RenderBox/BoxConstraints 회귀 없음', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository(defaultSettings());
      await tester.pumpWidget(
        wrap(const LessonStyleSettingsScreen(), repo: repo, width: 200),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [SettingsRepository] for LessonStyleSettingsScreen tests.
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
  Future<TeacherSettings> updateDefaultDuration(int duration) async {
    _settings = _settings.copyWith(lessonDurationMinutes: duration);
    return _settings;
  }

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) async {
    _settings = _settings.copyWith(minBookingHours: hours);
    return _settings;
  }

  @override
  Future<void> updateBookingGuidanceMessage(String? message) async {
    _settings = _settings.copyWith(bookingGuidanceMessage: message);
  }

  // ── Unused by LessonStyleSettingsScreen — throw on accidental call. ──
  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> addCustomDuration(int duration) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<void> updateTrialLessonFree(bool value) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');

  @override
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) =>
      throw UnimplementedError('not used by LessonStyleSettingsScreen');
}
