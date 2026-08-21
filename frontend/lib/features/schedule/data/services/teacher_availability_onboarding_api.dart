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
//
// #1293 — the save path is data-mode gated: mock mode persists through the
// (mock-gated) availability repository instead of issuing real HTTP. The
// provider that picks an implementation lives in
// `presentation/providers/teacher_availability_providers.dart` so this data
// layer stays free of presentation imports.

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/mappers/time_slot_mapper.dart';
import '../../domain/repositories/teacher_availability_repository.dart';

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

/// Onboarding availability save contract — implemented per data mode.
abstract class TeacherAvailabilityApi {
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots);
}

/// Thin HTTP wrapper around the onboarding dual-write endpoint.
class RemoteTeacherAvailabilityApi implements TeacherAvailabilityApi {
  final ApiClient _apiClient;

  RemoteTeacherAvailabilityApi(this._apiClient);

  /// Calls `POST /teacher/availability/onboarding` with the supplied
  /// availability slots. BE owns the dual-write to `TeacherAvailability`
  /// (SSOT) and `TeacherSettings.available_slots` (legacy mirror) — FE
  /// makes a single call.
  ///
  /// BE expects `day_of_week` in 0..6 (Mon=0, Sun=6); domain entity uses
  /// 1..7 (Mon=1, Sun=7), so we shift by -1 here.
  @override
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots) async {
    final body = {
      'slots':
          slots
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

/// Mock-mode implementation (#1293): persists through the availability
/// repository (mock-gated upstream) so the onboarding gate and read-side
/// providers see the new slots — and never touches HTTP.
///
/// The legacy `TeacherSettings.available_slots` mirror is intentionally not
/// written here: mock repositories are in-memory demo data and the mirror is
/// being phased out (reader unification, #607 Job 3).
class LocalTeacherAvailabilityApi implements TeacherAvailabilityApi {
  final TeacherAvailabilityRepository _repository;
  final String Function() _teacherIdResolver;

  LocalTeacherAvailabilityApi({
    required TeacherAvailabilityRepository repository,
    required String Function() teacherIdResolver,
  }) : _repository = repository,
       _teacherIdResolver = teacherIdResolver;

  @override
  Future<OnboardingDualWriteResult> postOnboarding(List<TimeSlot> slots) async {
    final teacherId = _teacherIdResolver();
    final existing = await _repository.getAvailability(teacherId);
    final base =
        existing ??
        TeacherAvailability(
          id: 'availability-$teacherId',
          teacherId: teacherId,
          weeklySchedules: const [],
          createdAt: DateTime.now(),
        );

    final now = DateTime.now();
    final added = [
      // Index suffix keeps ids unique when the submitted list carries the
      // same dayOfWeek more than once (re-submission merges existing slots).
      for (final (i, slot) in slots.indexed)
        slot.toWeeklySchedule(
          id: 'onboarding-${now.millisecondsSinceEpoch}-${slot.dayOfWeek}-$i',
          createdAt: now,
        ),
    ];

    await _repository.saveAvailability(
      base.copyWith(weeklySchedules: [...base.weeklySchedules, ...added]),
    );

    return OnboardingDualWriteResult(
      scheduleSlotCount: slots.length,
      settingsSlotCount: slots.length,
    );
  }
}
