import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_repository_provider.dart';

part 'teacher_settings_provider.g.dart';

/// Teacher settings provider (for current logged-in teacher)
@Riverpod(keepAlive: true)
Future<TeacherSettings> teacherSettings(TeacherSettingsRef ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getTeacherSettings();
}

/// Teacher settings provider by teacherId (for viewing other teacher's settings)
@Riverpod(keepAlive: true)
Future<TeacherSettings> teacherSettingsById(
  TeacherSettingsByIdRef ref,
  String teacherId,
) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getTeacherSettingsById(teacherId);
}

/// Teacher instruments provider (derived from settings)
@Riverpod(keepAlive: true)
AsyncValue<List<String>> teacherInstruments(TeacherInstrumentsRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.instruments),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

/// Default lesson duration provider (derived from settings)
@Riverpod(keepAlive: true)
AsyncValue<int> defaultLessonDuration(DefaultLessonDurationRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.defaultLessonDuration),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

/// Available time slots provider (derived from settings)
@Riverpod(keepAlive: true)
AsyncValue<List<TimeSlot>> availableTimeSlots(AvailableTimeSlotsRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.availableSlots),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
}

/// Teacher settings notifier for CRUD operations
@Riverpod(keepAlive: true)
class TeacherSettingsNotifier extends _$TeacherSettingsNotifier {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<TeacherSettings> build() async {
    return _repository.getTeacherSettings();
  }

  /// Refresh the read-side [teacherSettingsProvider] after a successful
  /// mutation. The notifier and the FutureProvider are separate instances,
  /// so home/quest screens watching [teacherSettingsProvider] would keep a
  /// stale value (e.g. first-availability interstitial loops) unless we
  /// invalidate the read side here. (#5 D-G3 — settings/profile SSOT)
  void _refreshReadSide() {
    ref.invalidate(teacherSettingsProvider);
  }

  /// Add an instrument to the list
  Future<void> addInstrument(String instrument) async {
    final current = state.value;
    if (current == null) return;

    if (current.instruments.contains(instrument)) return;

    final instruments = [...current.instruments, instrument];
    state = AsyncValue.data(current.copyWith(instruments: instruments));
    try {
      final updated = await _repository.updateInstruments(instruments);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Remove an instrument from the list
  Future<void> removeInstrument(String instrument) async {
    final current = state.value;
    if (current == null) return;

    final instruments = current.instruments
        .where((i) => i != instrument)
        .toList();
    state = AsyncValue.data(current.copyWith(instruments: instruments));
    try {
      final updated = await _repository.updateInstruments(instruments);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Reorder instruments
  Future<void> reorderInstruments(List<String> instruments) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(instruments: instruments));
    }
    try {
      final updated = await _repository.updateInstruments(instruments);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      if (current != null) {
        state = AsyncValue.data(current);
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update default lesson duration
  Future<void> updateDefaultDuration(int duration) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateDefaultDuration(duration);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a custom lesson duration
  Future<void> addCustomDuration(int duration) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.addCustomDuration(duration);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove a custom lesson duration
  Future<void> removeCustomDuration(int duration) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.removeCustomDuration(duration);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle duration active/disabled state
  Future<void> toggleDuration(int duration, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.toggleDuration(duration, isActive);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update a time slot
  Future<void> updateTimeSlot(TimeSlot slot) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateTimeSlot(slot);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle time slot active status
  Future<void> toggleTimeSlot(String slotId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.toggleTimeSlot(slotId, isActive);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove a time slot from operating hours.
  Future<void> removeTimeSlot(String slotId) async {
    final current = state.value;
    if (current == null) return;

    final slots = current.availableSlots
        .where((slot) => slot.id != slotId)
        .toList();
    state = AsyncValue.data(current.copyWith(availableSlots: slots));
    try {
      final updated = await _repository.updateAvailableSlots(slots);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Replace the entire available slots list at once.
  ///
  /// Used by the first-availability onboarding quest (#422) to commit
  /// multiple new slots derived from the simple multi-day chip UI.
  Future<void> replaceAvailableSlots(List<TimeSlot> slots) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(availableSlots: slots));
    try {
      final updated = await _repository.updateAvailableSlots(slots);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Refresh settings
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getTeacherSettings());
    _refreshReadSide();
  }

  /// Update break time between lessons
  Future<void> updateBreakTime(int minutes) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateBreakTime(minutes);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update minimum booking hours
  Future<void> updateMinBookingHours(int hours) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateMinBookingHours(hours);
      state = AsyncValue.data(updated);
      _refreshReadSide();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update booking guidance message
  Future<void> updateBookingGuidanceMessage(String? message) async {
    final current = state.value;
    if (current == null) return;

    final effectiveMessage = (message != null && message.isEmpty)
        ? null
        : message;
    state = AsyncValue.data(
      current.copyWith(bookingGuidanceMessage: effectiveMessage),
    );
    try {
      await _repository.updateBookingGuidanceMessage(effectiveMessage);
      _refreshReadSide();
    } catch (e, st) {
      // Roll back to the last known-good value; do not surface an error state
      // that would replace the rolled-back data and blank the screen.
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update trial lesson free setting
  Future<void> updateTrialLessonFree(bool value) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncValue.data(current.copyWith(trialLessonFree: value));
    try {
      await _repository.updateTrialLessonFree(value);
      _refreshReadSide();
    } catch (e, st) {
      // Roll back to the last known-good value; do not overwrite it with an
      // error state that would blank the settings screen.
      state = AsyncValue.data(current); // Rollback
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update lesson price table
  Future<void> updatePriceTable(
    Map<String, Map<String, int>> priceTable,
  ) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncValue.data(current.copyWith(lessonPriceTable: priceTable));
    try {
      await _repository.updatePriceTable(priceTable);
      _refreshReadSide();
    } catch (e, st) {
      // Roll back to the last known-good value; do not overwrite it with an
      // error state that would blank the settings screen.
      state = AsyncValue.data(current); // Rollback
      Error.throwWithStackTrace(e, st);
    }
  }
}
