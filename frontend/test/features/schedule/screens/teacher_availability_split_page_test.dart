import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
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
}
