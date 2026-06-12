// W3 Task 3.4 — SubscriptionTemplateListScreen 체험 레슨 섹션 회귀.
// HARD-GATE: design-principles.md (widget-smoke-test) + ux-rules (NO-OP 금지).
// spec §6.3 (PLAN O1) — 시험 레슨 정책을 별도 화면 신설하지 않고
//   SubscriptionTemplateListScreen 내부 섹션으로 통합.
//
// Verifies:
// - 섹션 헤더 (체험 레슨) + Switch 노출 (OFF 초기)
// - Switch 탭 → updateTrialLessonFree(true) 호출 + 메시지 "무료" 로 전환
// - trialLessonFree=true 초기 → ON + "무료" 메시지
// - 빈 템플릿 리스트 → empty state 여전히 노출 (회귀)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_boot_migration_provider.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_template_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_template_list_screen.dart';

void main() {
  Widget wrap({
    required SettingsRepository settingsRepo,
    required SubscriptionTemplateRepository templateRepo,
  }) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        teacherSettingsBootMigrationProvider.overrideWith((ref) async => true),
        subscriptionTemplateRepositoryProvider.overrideWithValue(templateRepo),
      ],
      child: const MaterialApp(
        home: SubscriptionTemplateListScreen(teacherId: 'teacher-1'),
      ),
    );
  }

  TeacherSettings baseSettings({bool trialLessonFree = false}) =>
      TeacherSettings(
        id: 'teacher-1',
        instruments: const ['피아노'],
        trialLessonFree: trialLessonFree,
        createdAt: DateTime.utc(2026, 6, 11),
      );

  group('SubscriptionTemplateListScreen 체험 레슨 섹션 (W3 Task 3.4)', () {
    testWidgets('체험 레슨 섹션 헤더 + Switch OFF 초기 상태', (tester) async {
      final settingsRepo = _FakeSettingsRepository(baseSettings());
      final templateRepo = _FakeTemplateRepository(const []);
      await tester.pumpWidget(
        wrap(settingsRepo: settingsRepo, templateRepo: templateRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileTrialLessonSection), findsOneWidget);
      // 초기 OFF — 유료 메시지.
      expect(find.text(AppStrings.profileTrialLessonFreeOff), findsOneWidget);
      // Switch 위젯 노출.
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Switch 탭 → updateTrialLessonFree(true) 호출', (tester) async {
      final settingsRepo = _FakeSettingsRepository(baseSettings());
      final templateRepo = _FakeTemplateRepository(const []);
      await tester.pumpWidget(
        wrap(settingsRepo: settingsRepo, templateRepo: templateRepo),
      );
      await tester.pumpAndSettle();

      expect(settingsRepo.last.trialLessonFree, isFalse);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(settingsRepo.last.trialLessonFree, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trialLessonFree=true 초기 → "무료" 메시지 노출', (tester) async {
      final settingsRepo = _FakeSettingsRepository(
        baseSettings(trialLessonFree: true),
      );
      final templateRepo = _FakeTemplateRepository(const []);
      await tester.pumpWidget(
        wrap(settingsRepo: settingsRepo, templateRepo: templateRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileTrialLessonFreeOn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 템플릿 리스트 → empty state 여전히 노출 (회귀)', (tester) async {
      final settingsRepo = _FakeSettingsRepository(baseSettings());
      final templateRepo = _FakeTemplateRepository(const []);
      await tester.pumpWidget(
        wrap(settingsRepo: settingsRepo, templateRepo: templateRepo),
      );
      await tester.pumpAndSettle();

      // 빈 상태 안내 (등록된 수강권 없음) — 회귀 검증.
      expect(
        find.text(AppStrings.noSubscriptionsRegisteredTitle),
        findsOneWidget,
      );
      // 체험 레슨 섹션은 비어 있어도 노출 (위치 안정성).
      expect(find.text(AppStrings.profileTrialLessonSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [SettingsRepository] for trial section tests.
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
  Future<void> updateTrialLessonFree(bool value) async {
    _settings = _settings.copyWith(trialLessonFree: value);
  }

  // ── Unused — throw on accidental call. ──
  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) =>
      throw UnimplementedError('unused');

  @override
  Future<void> updateBookingGuidanceMessage(String? message) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> addCustomDuration(int duration) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError('unused');

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw UnimplementedError('unused');

  @override
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) =>
      throw UnimplementedError('unused');
}

/// In-memory [SubscriptionTemplateRepository] — only `getByTeacher` exercised.
class _FakeTemplateRepository implements SubscriptionTemplateRepository {
  _FakeTemplateRepository(this._templates);

  final List<SubscriptionTemplate> _templates;

  @override
  Future<List<SubscriptionTemplate>> getByTeacher(String teacherId) async =>
      _templates;

  @override
  Future<List<SubscriptionTemplate>> getByAcademy(String academyId) =>
      throw UnimplementedError('unused');

  @override
  Future<SubscriptionTemplate?> getById(String id) =>
      throw UnimplementedError('unused');

  @override
  Future<List<SubscriptionTemplate>> getActiveByTeacher(String teacherId) =>
      throw UnimplementedError('unused');

  @override
  Future<List<SubscriptionTemplate>> getActiveByAcademy(String academyId) =>
      throw UnimplementedError('unused');

  @override
  Future<List<SubscriptionTemplate>> getAutoProposalTemplates(
    String teacherId,
  ) => throw UnimplementedError('unused');

  @override
  Future<SubscriptionTemplate> create(SubscriptionTemplate template) =>
      throw UnimplementedError('unused');

  @override
  Future<SubscriptionTemplate> update(SubscriptionTemplate template) =>
      throw UnimplementedError('unused');

  @override
  Future<void> delete(String id) => throw UnimplementedError('unused');

  @override
  Future<SubscriptionTemplate> toggleActive(String id) =>
      throw UnimplementedError('unused');

  @override
  Future<void> reorder(List<String> orderedIds) =>
      throw UnimplementedError('unused');
}
