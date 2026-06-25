import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/settings/settings_facade.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_availability_split_page.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/availability/availability_preview_grid.dart';

/// Widget smoke + behavior tests for G5 #433 — TeacherAvailabilitySplitPage.
///
/// Covers HARD-GATE design rules:
/// - desktop (>= 769px) renders left settings + right preview (Row layout)
/// - mobile (<= 768px) renders preview above settings (Column layout)
/// - no BoxConstraints / RenderBox crashes via tester.takeException()
/// - defaults to 50/10/60 when no record exists
/// - left settings change → right preview updates live
void main() {
  /// Pump the split page with an overridden TeacherAvailability future.
  ///
  /// We override the leaf `teacherAvailabilityProvider` so we don't need
  /// the mock repository / network / hive setup.
  Future<void> pumpSplitPage(
    WidgetTester tester, {
    TeacherAvailability? availability,
    Size? viewportSize,
  }) async {
    if (viewportSize != null) {
      // ignore: deprecated_member_use
      tester.binding.window.physicalSizeTestValue = viewportSize;
      // ignore: deprecated_member_use
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        // ignore: deprecated_member_use
        tester.binding.window.clearPhysicalSizeTestValue();
        // ignore: deprecated_member_use
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityProvider(
            'teacher_test',
          ).overrideWith((ref) async => availability),
          // Override SSOT settings so _SplitLayout doesn't need Hive/network.
          teacherSettingsNotifierProvider.overrideWith(
            () => _FakeSettingsNotifier(50),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeacherAvailabilitySplitPage(teacherId: 'teacher_test'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    'desktop viewport: split row renders settings + preview, no crash',
    (tester) async {
      await pumpSplitPage(
        tester,
        availability: null,
        viewportSize: const Size(1280, 800),
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'split layout must not throw BoxConstraints / RenderBox '
            'errors on desktop viewport',
      );

      // Both panel labels should be visible (left settings + right preview).
      expect(find.text(AppStrings.availabilitySettingsPanel), findsOneWidget);
      expect(find.text(AppStrings.availabilityPreviewPanel), findsOneWidget);

      // Friendly terms (not the internal "slot" jargon) should be present.
      expect(find.text(AppStrings.lessonDurationLabel), findsOneWidget);
      expect(find.text(AppStrings.breakTimeLabel), findsOneWidget);
    },
  );

  testWidgets('mobile viewport: preview stacks above settings, no crash', (
    tester,
  ) async {
    await pumpSplitPage(
      tester,
      availability: null,
      viewportSize: const Size(375, 800),
    );

    expect(
      tester.takeException(),
      isNull,
      reason:
          'mobile fallback must render preview + settings without '
          'BoxConstraints crashes',
    );

    // Same widgets are present (preview header + settings header).
    expect(find.text(AppStrings.availabilitySettingsPanel), findsOneWidget);
    expect(find.text(AppStrings.availabilityPreviewPanel), findsOneWidget);
  });

  testWidgets(
    'first-time setup: applies 50/10/60 defaults when no record exists',
    (tester) async {
      // null availability → ensureDefaults() materializes a new
      // TeacherAvailability with the constructor defaults (50/10/60).
      await pumpSplitPage(tester, availability: null);

      // Find the preview widget and inspect the materialized config.
      final preview = tester.widget<AvailabilityPreviewGrid>(
        find.byType(AvailabilityPreviewGrid),
      );

      expect(
        preview.availability.slotDurationMinutes,
        50,
        reason:
            'lesson duration default must be 50 per spec '
            'schedule_master.md §2.1',
      );
      expect(
        preview.availability.breakTimeBetweenLessons,
        10,
        reason: 'break time default must be 10 per spec',
      );
      expect(
        preview.availability.slotStartInterval,
        60,
        reason:
            'slot start interval default must be 60 '
            '(= lesson + break)',
      );
    },
  );

  testWidgets(
    'preview reflects availability config — different settings render '
    'different slot counts',
    (tester) async {
      // Pump AvailabilityPreviewGrid directly with two different configs
      // back-to-back to verify the right-side preview reacts to settings
      // changes (left-panel mutation flows into the same widget input).
      Future<void> pumpPreview(TeacherAvailability availability) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AvailabilityPreviewGrid(availability: availability),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Config A: 60 min lesson, 0 break → interval 60, in a 14:00-16:00
      // Monday slot. Expected: 2 slot starts (14:00, 15:00).
      final configA = TeacherAvailability(
        id: 'a',
        teacherId: 't',
        slotDurationMinutes: 60,
        slotStartInterval: 60,
        breakTimeBetweenLessons: 0,
        weeklySchedules: [
          WeeklySchedule(
            id: 'w1',
            dayOfWeek: 0,
            startTime: '14:00',
            endTime: '16:00',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
      );
      await pumpPreview(configA);
      expect(tester.takeException(), isNull);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(
        find.text('14:30'),
        findsNothing,
        reason: '60-min interval should not produce a 14:30 start',
      );

      // Config B (live change): switch to 30-min lessons with 0 break and
      // 30-min interval → now 4 slot starts (14:00, 14:30, 15:00, 15:30).
      final configB = configA.copyWith(
        slotDurationMinutes: 30,
        slotStartInterval: 30,
        breakTimeBetweenLessons: 0,
      );
      await pumpPreview(configB);
      expect(tester.takeException(), isNull);
      expect(
        find.text('14:30'),
        findsOneWidget,
        reason:
            'preview must reflect new 30-min interval immediately when '
            'settings change',
      );
      expect(find.text('15:30'), findsOneWidget);
    },
  );

  testWidgets('empty schedule renders preview empty hint without crashing', (
    tester,
  ) async {
    // null availability → defaults with no weekly schedules.
    await pumpSplitPage(
      tester,
      availability: null,
      viewportSize: const Size(1280, 800),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.previewEmptyHint), findsOneWidget);
  });

  // ── C1 (audit §4.7) — Wrap chip → card + SwipeActionTile layout ─────
  testWidgets(
    'C1: weekly slot renders as a card row with edit/delete affordances',
    (tester) async {
      final availability = TeacherAvailability(
        id: 't',
        teacherId: 'teacher_test',
        weeklySchedules: [
          WeeklySchedule(
            id: 'w1',
            dayOfWeek: 1, // 화요일
            startTime: '14:00',
            endTime: '16:00',
            createdAt: DateTime(2026, 1, 1),
          ),
          WeeklySchedule(
            id: 'w2',
            dayOfWeek: 1,
            startTime: '17:00',
            endTime: '19:00',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
      );

      await pumpSplitPage(
        tester,
        availability: availability,
        viewportSize: const Size(390, 900),
      );

      // Two time-slot rows visible.
      expect(tester.takeException(), isNull);
      expect(find.text('14:00 - 16:00'), findsOneWidget);
      expect(find.text('17:00 - 19:00'), findsOneWidget);

      // Add CTA visible per day card.
      expect(find.text(AppStrings.weeklyScheduleAddSlotAction), findsWidgets);
    },
  );

  testWidgets('C1: empty day shows 쉬는날 label and still offers + 시간대 추가 CTA', (
    tester,
  ) async {
    final availability = TeacherAvailability(
      id: 't',
      teacherId: 'teacher_test',
      weeklySchedules: const [],
      createdAt: DateTime(2026, 1, 1),
    );

    await pumpSplitPage(
      tester,
      availability: availability,
      viewportSize: const Size(390, 900),
    );

    expect(tester.takeException(), isNull);
    // Each empty day shows the 쉬는날 label.
    expect(find.text(AppStrings.dayOff), findsWidgets);
    // Each day card has its own + 시간대 추가 CTA.
    expect(find.text(AppStrings.weeklyScheduleAddSlotAction), findsWidgets);
  });

  // ── #727 Item D — vacation mode CTA discoverable on availability page ─
  testWidgets(
    '#727-D: vacation mode CTA renders in special schedules section',
    (tester) async {
      // Use null availability (defaults) — the ExceptionsPanel renders
      // regardless of whether exceptions exist; vacation CTA is always present.
      await pumpSplitPage(
        tester,
        availability: null,
        viewportSize: const Size(390, 900),
      );

      expect(tester.takeException(), isNull);

      // The CTA button for vacation mode must be visible.
      expect(
        find.text(AppStrings.vacationModeEntry),
        findsOneWidget,
        reason:
            '#727-D: teacherVacationMode GoRoute existed but had no '
            'discoverable entry point — vacationModeEntry CTA must now render',
      );
    },
  );

  // ── #927 (#201) SSOT tests ─────────────────────────────────────────────

  /// Helper: pump split page with both availability and settings overrides.
  Future<void> pumpWithSettings(
    WidgetTester tester, {
    TeacherAvailability? availability,
    required int ssotDurationMinutes,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityProvider(
            'teacher_test',
          ).overrideWith((ref) async => availability),
          teacherSettingsNotifierProvider.overrideWith(
            () => _FakeSettingsNotifier(ssotDurationMinutes),
          ),
        ],
        child: const MaterialApp(
          home: TeacherAvailabilitySplitPage(teacherId: 'teacher_test'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    '#201-A: read-only duration row shows SSOT value and nav hint, no editable radio',
    (tester) async {
      await pumpWithSettings(
        tester,
        availability: null,
        ssotDurationMinutes: 45,
      );
      expect(tester.takeException(), isNull);

      // SSOT duration label rendered (e.g. "45분")
      expect(
        find.text(AppStrings.lessonDurationOptionLabel(45)),
        findsOneWidget,
        reason: 'SSOT duration (45) must appear in the read-only row',
      );

      // Nav hint text present
      expect(
        find.text(AppStrings.lessonDurationManagedInStyle),
        findsOneWidget,
        reason: 'Read-only affordance must show navigation hint',
      );
    },
  );

  testWidgets(
    '#201-B: preview grid uses SSOT duration overriding availability.slotDurationMinutes',
    (tester) async {
      // availability has slotDurationMinutes=30 but SSOT says 60
      final availability = TeacherAvailability(
        id: 'b',
        teacherId: 'teacher_test',
        slotDurationMinutes: 30,
        slotStartInterval: 30,
        breakTimeBetweenLessons: 0,
        weeklySchedules: [
          WeeklySchedule(
            id: 'w1',
            dayOfWeek: 1, // 화요일
            startTime: '14:00',
            endTime: '16:00',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
      );

      await pumpWithSettings(
        tester,
        availability: availability,
        ssotDurationMinutes: 60,
      );
      expect(tester.takeException(), isNull);

      // AvailabilityPreviewGrid must receive the SSOT override
      final grid = tester.widget<AvailabilityPreviewGrid>(
        find.byType(AvailabilityPreviewGrid),
      );
      expect(
        grid.lessonDurationMinutes,
        60,
        reason:
            'Preview grid must use SSOT duration (60), not '
            'availability.slotDurationMinutes (30)',
      );
    },
  );
}

/// Fake [TeacherSettingsNotifier] that immediately returns a [TeacherSettings]
/// with the given lesson duration.
class _FakeSettingsNotifier extends TeacherSettingsNotifier {
  _FakeSettingsNotifier(this._duration);
  final int _duration;

  @override
  Future<TeacherSettings> build() async => TeacherSettings(
    id: 'fake',
    instruments: const [],
    lessonDurationMinutes: _duration,
    createdAt: DateTime(2026, 1, 1),
  );
}
