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
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Remove an instrument from the list
  Future<void> removeInstrument(String instrument) async {
    final current = state.value;
    if (current == null) return;

    final instruments =
        current.instruments.where((i) => i != instrument).toList();
    state = AsyncValue.data(current.copyWith(instruments: instruments));
    try {
      final updated = await _repository.updateInstruments(instruments);
      state = AsyncValue.data(updated);
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh settings
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getTeacherSettings());
  }

  /// Update break time between lessons
  Future<void> updateBreakTime(int minutes) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateBreakTime(minutes);
      state = AsyncValue.data(updated);
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update booking guidance message
  Future<void> updateBookingGuidanceMessage(String? message) async {
    final current = state.value;
    if (current == null) return;

    final effectiveMessage =
        (message != null && message.isEmpty) ? null : message;
    state = AsyncValue.data(
      current.copyWith(bookingGuidanceMessage: effectiveMessage),
    );
    try {
      await _repository.updateBookingGuidanceMessage(effectiveMessage);
    } catch (e, st) {
      state = AsyncValue.data(current);
      state = AsyncValue.error(e, st);
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
    } catch (e, st) {
      state = AsyncValue.data(current); // Rollback
      state = AsyncValue.error(e, st);
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
    } catch (e, st) {
      state = AsyncValue.data(current); // Rollback
      state = AsyncValue.error(e, st);
    }
  }
}
