// Skip-navigation test for the inline onboarding step 4 (#P1-7,
// teacher-journey audit 2026-08-11).
//
// FirstAvailabilitySetupScreen is now reached in-flow right after
// ProfileSetupScreen (profile_setup_screen.dart), instead of only via the
// dashboard's NextMissionSpotlight. The "나중에 설정" AppBar action must land
// the teacher on /home without creating any WeeklySchedule slots — the home
// spotlight/quest board picks up the reminder from there (unchanged).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/first_availability_setup_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/data/services/teacher_availability_onboarding_api.dart';
import 'package:lessonaza/features/settings/settings_facade.dart';

class _SpyOnboardingApi implements TeacherAvailabilityApi {
  int callCount = 0;

  @override
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots) async {
    callCount++;
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

GoRouter _router() {
  return GoRouter(
    initialLocation: '/onboarding/first-availability',
    routes: [
      GoRoute(
        path: '/onboarding/first-availability',
        builder: (_, __) => const FirstAvailabilitySetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Center(child: Text('HOME'))),
      ),
    ],
  );
}

void main() {
  testWidgets('"나중에 설정" 탭 → /home 이동, WeeklySchedule 슬롯 0건 생성 (#P1-7)', (
    tester,
  ) async {
    final spy = _SpyOnboardingApi();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityApiProvider.overrideWithValue(spy),
          teacherSettingsProvider.overrideWith(
            (ref) async => _emptyTeacherSettings(),
          ),
        ],
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();

    final skipButton = find.text(AppStrings.firstAvailabilitySkipAction);
    expect(skipButton, findsOneWidget);

    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(spy.callCount, 0, reason: '스킵은 가용시간을 저장하지 않고 바로 홈으로 이동해야 한다');
    expect(tester.takeException(), isNull);
  });
}
