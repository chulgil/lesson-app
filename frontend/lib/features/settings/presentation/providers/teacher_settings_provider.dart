import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_repository_provider.dart';

/// Teacher settings provider (for current logged-in teacher)
final teacherSettingsProvider =
    FutureProvider<TeacherSettings>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getTeacherSettings();
});

/// Teacher settings provider by teacherId (for viewing other teacher's settings)
final teacherSettingsByIdProvider =
    FutureProvider.family<TeacherSettings, String>((ref, teacherId) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getTeacherSettingsById(teacherId);
});

/// Teacher instruments provider (derived from settings)
final teacherInstrumentsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.instruments),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Default lesson duration provider (derived from settings)
final defaultLessonDurationProvider = Provider<AsyncValue<int>>((ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.defaultLessonDuration),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Available time slots provider (derived from settings)
final availableTimeSlotsProvider =
    Provider<AsyncValue<List<TimeSlot>>>((ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.when(
    data: (settings) => AsyncValue.data(settings.availableSlots),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Teacher settings notifier for CRUD operations
class TeacherSettingsNotifier extends AsyncNotifier<TeacherSettings> {
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

    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateInstruments([
        ...current.instruments,
        instrument,
      ]);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove an instrument from the list
  Future<void> removeInstrument(String instrument) async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateInstruments(
        current.instruments.where((i) => i != instrument).toList(),
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reorder instruments
  Future<void> reorderInstruments(List<String> instruments) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateInstruments(instruments);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) async {
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

final teacherSettingsNotifierProvider =
    AsyncNotifierProvider<TeacherSettingsNotifier, TeacherSettings>(
  TeacherSettingsNotifier.new,
);
