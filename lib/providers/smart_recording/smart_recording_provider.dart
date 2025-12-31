import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/smart_recording.dart';
import '../recording/recording_provider.dart';

part 'smart_recording_provider.g.dart';

/// Provider for smart recording settings persistence.
@riverpod
class SmartRecordingSettingsNotifier extends _$SmartRecordingSettingsNotifier {
  static const _boxName = 'smart_recording_settings';
  static const _settingsKey = 'settings';

  @override
  SmartRecordingSettings build() {
    _loadSettings();
    return const SmartRecordingSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get(_settingsKey);
      if (data != null) {
        state = SmartRecordingSettings.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('Failed to load smart recording settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.put(_settingsKey, state.toJson());
    } catch (e) {
      debugPrint('Failed to save smart recording settings: $e');
    }
  }

  /// Toggle smart recording on/off.
  Future<void> toggleEnabled() async {
    state = state.copyWith(smartRecordingEnabled: !state.smartRecordingEnabled);
    await _saveSettings();
  }

  /// Set the trim threshold.
  Future<void> setThreshold(double threshold) async {
    final clampedThreshold = threshold.clamp(
      SmartRecordingState.minThreshold,
      SmartRecordingState.maxThreshold,
    );
    state = state.copyWith(trimThreshold: clampedThreshold);
    await _saveSettings();
  }
}

/// Provider for smart recording state during active recording.
@riverpod
class SmartRecordingNotifier extends _$SmartRecordingNotifier {
  StreamSubscription<double>? _amplitudeSubscription;
  DateTime? _recordingStartTime;

  @override
  SmartRecordingState build() {
    final settings = ref.watch(smartRecordingSettingsNotifierProvider);

    ref.onDispose(() {
      _amplitudeSubscription?.cancel();
    });

    return SmartRecordingState(
      isEnabled: settings.smartRecordingEnabled,
      threshold: settings.trimThreshold,
    );
  }

  /// Start monitoring amplitude for smart recording.
  void startMonitoring() {
    if (!state.isEnabled) return;

    _amplitudeSubscription?.cancel();
    _recordingStartTime = DateTime.now();

    state = state.resetForNewRecording();

    final recorder = ref.read(audioRecorderServiceProvider);
    _amplitudeSubscription = recorder.normalizedAmplitudeStream.listen(_onAmplitude);

    debugPrint('SmartRecording: Started monitoring (threshold=${state.threshold})');
  }

  /// Stop monitoring and calculate trim durations.
  SmartRecordingState stopMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (!state.isEnabled || _recordingStartTime == null) {
      return state;
    }

    final now = DateTime.now();
    final recordingDuration = now.difference(_recordingStartTime!);

    // Calculate trimmed durations
    Duration trimmedStart = Duration.zero;
    Duration trimmedEnd = Duration.zero;

    if (state.soundStartTime != null) {
      trimmedStart = state.soundStartTime!.difference(_recordingStartTime!);
      if (trimmedStart < SmartRecordingState.minSilenceDuration) {
        trimmedStart = Duration.zero;
      }
    }

    if (state.soundEndTime != null) {
      trimmedEnd = now.difference(state.soundEndTime!);
      if (trimmedEnd < SmartRecordingState.minSilenceDuration) {
        trimmedEnd = Duration.zero;
      }
    }

    // Handle edge case: entire recording is silent
    if (state.phase == RecordingPhase.waiting) {
      debugPrint('SmartRecording: Entire recording was silent, no trimming');
      return state.copyWith(
        trimmedStart: Duration.zero,
        trimmedEnd: Duration.zero,
      );
    }

    final result = state.copyWith(
      trimmedStart: trimmedStart,
      trimmedEnd: trimmedEnd,
    );

    debugPrint('SmartRecording: Stopped monitoring');
    debugPrint('  Recording duration: $recordingDuration');
    debugPrint('  Trimmed start: $trimmedStart');
    debugPrint('  Trimmed end: $trimmedEnd');

    _recordingStartTime = null;
    return result;
  }

  void _onAmplitude(double amplitude) {
    final now = DateTime.now();

    // Sound detected
    if (amplitude >= state.threshold) {
      if (state.phase == RecordingPhase.waiting) {
        // First sound detected - mark start
        state = state.copyWith(
          phase: RecordingPhase.recording,
          soundStartTime: now,
          soundEndTime: now,
        );
        debugPrint('SmartRecording: Sound started at ${now.difference(_recordingStartTime!)}');
      } else {
        // Update last sound time
        state = state.copyWith(
          phase: RecordingPhase.recording,
          soundEndTime: now,
        );
      }
    } else {
      // Silence detected
      if (state.phase == RecordingPhase.recording) {
        state = state.copyWith(phase: RecordingPhase.ending);
        debugPrint('SmartRecording: Sound ended at ${now.difference(_recordingStartTime!)}');
      }
    }
  }

  /// Get current recording phase for UI display.
  RecordingPhase get currentPhase => state.phase;

  /// Reset state for new recording.
  void reset() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _recordingStartTime = null;

    final settings = ref.read(smartRecordingSettingsNotifierProvider);
    state = SmartRecordingState(
      isEnabled: settings.smartRecordingEnabled,
      threshold: settings.trimThreshold,
    );
  }
}
