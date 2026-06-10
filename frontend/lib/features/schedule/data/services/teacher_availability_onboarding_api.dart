// Onboarding dual-write API for teacher availability (#607 Job 2).
//
// Issue #606 (#641, 4f0bd3f0) introduced
// `POST /api/v1/teacher/availability/onboarding` which writes both
// `TeacherAvailability` (SSOT) and `TeacherSettings.available_slots`
// (legacy mirror). This API client invokes that endpoint so the
// onboarding screen no longer relies on the FE-side
// `replaceAvailableSlots` settings path (which writes only the legacy
// mirror).
//
// Reader unification (Job 3) lives in a follow-up PR; this layer only
// owns the dual-write call.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/network/api_client.dart';

part 'teacher_availability_onboarding_api.g.dart';

/// Result returned by the BE dual-write endpoint — counts only.
class OnboardingDualWriteResult {
  final int scheduleSlotCount;
  final int settingsSlotCount;

  const OnboardingDualWriteResult({
    required this.scheduleSlotCount,
    required this.settingsSlotCount,
  });

  factory OnboardingDualWriteResult.fromJson(Map<String, dynamic> json) {
    return OnboardingDualWriteResult(
      scheduleSlotCount: (json['schedule_slot_count'] as num?)?.toInt() ?? 0,
      settingsSlotCount: (json['settings_slot_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Thin HTTP wrapper around the onboarding dual-write endpoint.
class TeacherAvailabilityApi {
  final ApiClient _apiClient;

  TeacherAvailabilityApi(this._apiClient);

  /// Calls `POST /teacher/availability/onboarding` with the supplied
  /// availability slots. BE owns the dual-write to `TeacherAvailability`
  /// (SSOT) and `TeacherSettings.available_slots` (legacy mirror) — FE
  /// makes a single call.
  ///
  /// BE expects `day_of_week` in 0..6 (Mon=0, Sun=6); domain entity uses
  /// 1..7 (Mon=1, Sun=7), so we shift by -1 here.
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots) async {
    final body = {
      'slots': slots
          .map(
            (s) => {
              'day_of_week': s.dayOfWeek - 1,
              'start_time': s.startTime.toString(),
              'end_time': s.endTime.toString(),
            },
          )
          .toList(),
    };

    final response = await _apiClient.post(
      '/teacher/availability/onboarding',
      data: body,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return OnboardingDualWriteResult.fromJson(data);
    }
    return const OnboardingDualWriteResult(
      scheduleSlotCount: 0,
      settingsSlotCount: 0,
    );
  }
}

/// Singleton provider so tests can override with a fake.
@Riverpod(keepAlive: true)
TeacherAvailabilityApi teacherAvailabilityApi(TeacherAvailabilityApiRef ref) {
  final apiClient = ref.read(apiClientProvider);
  return TeacherAvailabilityApi(apiClient);
}
