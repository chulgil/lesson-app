// Dual-write transition test for the first availability onboarding flow
// (#607 Job 2).
//
// Verifies that pressing "적용" on FirstAvailabilitySetupScreen routes
// the save through `teacherAvailabilityApiProvider.postOnboarding(...)`
// (the BE dual-write endpoint introduced in #606 / 4f0bd3f0) rather
// than the legacy FE-side `replaceAvailableSlots` settings notifier
// path.
//
// Test technique: spy fake API + a pre-warmed teacherSettingsProvider.
// We do NOT verify the navigation (context.go) because the screen is
// pumped without a router; the legacy widget smoke test already covers
// rendering.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/first_availability_setup_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/data/services/teacher_availability_onboarding_api.dart';
import 'package:lessonaza/features/settings/settings_facade.dart';

class _SpyOnboardingApi implements TeacherAvailabilityApi {
  int callCount = 0;
  List<TimeSlot>? lastSlots;

  @override
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots) async {
    callCount++;
    lastSlots = slots;
    return OnboardingDualWriteResult(
      scheduleSlotCount: slots.length,
      settingsSlotCount: slots.length,
    );
  }
}

TeacherSettings _emptyTeacherSettings() {
  return TeacherSettings(
    id: 'teacher-1',
    instruments: const ['violin'],
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets(
    'Apply CTA calls teacherAvailabilityApiProvider.postOnboarding (#607 Job 2)',
    (tester) async {
      final spy = _SpyOnboardingApi();

      // Use a wider viewport so the apply button is in the laid-out tree
      // (the default 800x600 test surface still contains it, but we set
      // an explicit physical size to be deterministic).
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherAvailabilityApiProvider.overrideWithValue(spy),
            teacherSettingsProvider.overrideWith(
              (ref) async => _emptyTeacherSettings(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const FirstAvailabilitySetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the apply CTA — defaults select Mon-Fri (5 days).
      await tester.tap(find.text(AppStrings.firstAvailabilityApplyAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dual-write endpoint was hit exactly once.
      expect(spy.callCount, 1);
      // Five default weekday slots were sent.
      expect(spy.lastSlots, isNotNull);
      expect(spy.lastSlots!.length, 5);
      // No runtime crashes.
      expect(tester.takeException(), isNull);
    },
  );
}
