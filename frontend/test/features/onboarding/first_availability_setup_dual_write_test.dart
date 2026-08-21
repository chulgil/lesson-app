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
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/schedule_facade.dart'
    show
        teacherAvailabilityApiProvider,
        teacherAvailabilityProvider,
        teacherAvailabilityRepositoryProvider;
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
      // One slot is created per selected day — Mon(1)..Fri(5).
      expect(
        spy.lastSlots!.map((s) => s.dayOfWeek).toSet(),
        {1, 2, 3, 4, 5},
        reason: '선택된 요일 각각에 슬롯이 1개씩 생성되어야 한다',
      );
      // No runtime crashes.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('요일 선택을 바꾸면 변경된 요일 집합만큼만 슬롯이 생성된다 (#P1-7)', (tester) async {
    final spy = _SpyOnboardingApi();

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

    // Default selection is Mon-Fri. Deselect Tue/Wed, select Sat →
    // {Mon, Thu, Fri, Sat} = {1, 4, 5, 6}.
    await tester.tap(find.text(AppStrings.firstAvailabilityDayTue));
    await tester.tap(find.text(AppStrings.firstAvailabilityDayWed));
    await tester.tap(find.text(AppStrings.firstAvailabilityDaySat));
    await tester.pump();

    await tester.tap(find.text(AppStrings.firstAvailabilityApplyAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(spy.callCount, 1);
    expect(spy.lastSlots, isNotNull);
    expect(
      spy.lastSlots!.map((s) => s.dayOfWeek).toSet(),
      {1, 4, 5, 6},
      reason: '요일 선택을 바꾸면 그 집합대로만 슬롯이 생성되어야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  // 리뷰 0821 — mock 경로에서 저장 후 availability snapshot 이 stale 하면
  // 온보딩 게이트가 루프를 돌 수 있다. 제출이 teacherAvailabilityProvider 를
  // invalidate 해 재조회를 유발하는지 검증한다.
  testWidgets('제출 후 teacherAvailabilityProvider 를 invalidate 해 재조회한다', (
    tester,
  ) async {
    final spy = _SpyOnboardingApi();
    final countingRepo = _CountingAvailabilityRepository();

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityApiProvider.overrideWithValue(spy),
          teacherAvailabilityRepositoryProvider.overrideWithValue(countingRepo),
          teacherSettingsProvider.overrideWith(
            (ref) async => _emptyTeacherSettings(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Stack(
            children: [FirstAvailabilitySetupScreen(), _AvailabilityProbe()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = countingRepo.getAvailabilityCalls;
    expect(before, greaterThan(0), reason: 'probe must warm the provider');

    await tester.tap(find.text(AppStrings.firstAvailabilityApplyAction));
    // celebration sheet 애니메이션이 계속 돌아 pumpAndSettle 은 타임아웃 —
    // 기존 테스트와 같은 고정 pump 로 대체.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(spy.callCount, 1);
    expect(
      countingRepo.getAvailabilityCalls,
      greaterThan(before),
      reason: '제출 후 invalidate 로 availability 재조회가 일어나야 한다',
    );
  });
}

class _CountingAvailabilityRepository implements TeacherAvailabilityRepository {
  int getAvailabilityCalls = 0;

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    getAvailabilityCalls++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps teacherAvailabilityProvider alive so invalidate triggers a re-fetch.
class _AvailabilityProbe extends ConsumerWidget {
  const _AvailabilityProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(teacherAvailabilityProvider('teacher-1'));
    return const SizedBox.shrink();
  }
}
