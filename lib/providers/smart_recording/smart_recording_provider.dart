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

  /// Toggle middle silence skip on/off.
  Future<void> toggleMiddleSilenceSkip() async {
    state = state.copyWith(
      middleSilenceSkipEnabled: !state.middleSilenceSkipEnabled,
    );
    await _saveSettings();
  }

  /// Set the middle silence threshold in seconds.
  Future<void> setMiddleSilenceThreshold(int seconds) async {
    final clamped = seconds.clamp(5, 30);
    state = state.copyWith(middleSilenceThreshold: clamped);
    await _saveSettings();
  }
}

/// Provider for smart recording state during active recording.
/// keepAlive: true to prevent disposal during recording session.
@Riverpod(keepAlive: true)
class SmartRecordingNotifier extends _$SmartRecordingNotifier {
  StreamSubscription<double>? _amplitudeSubscription;
  DateTime? _recordingStartTime;
  Duration _middleSilenceThreshold = SmartRecordingState.defaultMiddleSilenceThreshold;
  bool _middleSilenceSkipEnabled = true;

  @override
  SmartRecordingState build() {
    final settings = ref.watch(smartRecordingSettingsNotifierProvider);
    _middleSilenceThreshold = settings.middleSilenceThresholdDuration;
    _middleSilenceSkipEnabled = settings.middleSilenceSkipEnabled;

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
    debugPrint('SmartRecording: startMonitoring called, isEnabled=${state.isEnabled}');
    if (!state.isEnabled) {
      debugPrint('SmartRecording: Skipping - smart recording is disabled');
      return;
    }

    _amplitudeSubscription?.cancel();
    _recordingStartTime = DateTime.now();

    // Reload settings
    final settings = ref.read(smartRecordingSettingsNotifierProvider);
    _middleSilenceThreshold = settings.middleSilenceThresholdDuration;
    _middleSilenceSkipEnabled = settings.middleSilenceSkipEnabled;

    state = state.resetForNewRecording();

    final recorder = ref.read(audioRecorderServiceProvider);
    _amplitudeSubscription = recorder.normalizedAmplitudeStream.listen(_onAmplitude);

    debugPrint('SmartRecording: Started monitoring (threshold=${state.threshold}, middleSilence=$_middleSilenceThreshold)');
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

    // Calculate trimmed durations with 3-second buffer
    const buffer = Duration(seconds: 3);
    Duration trimmedStart = Duration.zero;
    Duration trimmedEnd = Duration.zero;

    if (state.soundStartTime != null) {
      final silenceAtStart = state.soundStartTime!.difference(_recordingStartTime!);
      trimmedStart = silenceAtStart - buffer;
      if (trimmedStart < Duration.zero) {
        trimmedStart = Duration.zero;
      }
    }

    if (state.soundEndTime != null) {
      final silenceAtEnd = now.difference(state.soundEndTime!);
      trimmedEnd = silenceAtEnd - buffer;
      if (trimmedEnd < Duration.zero) {
        trimmedEnd = Duration.zero;
      }
    }

    // Finalize any ongoing middle silence
    List<SilencePeriod> finalSilencePeriods = List.from(state.silencePeriods);
    if (state.middleSilenceStartTime != null && _middleSilenceSkipEnabled) {
      final silenceDuration = now.difference(state.middleSilenceStartTime!);
      if (silenceDuration >= _middleSilenceThreshold) {
        final startOffset = state.middleSilenceStartTime!.difference(_recordingStartTime!);
        final endOffset = now.difference(_recordingStartTime!);
        finalSilencePeriods.add(SilencePeriod(
          startTime: startOffset + buffer,
          endTime: endOffset - buffer,
        ));
      }
    }

    // Handle edge case: entire recording is silent
    if (state.phase == RecordingPhase.waiting) {
      debugPrint('SmartRecording: Entire recording was silent, no trimming');
      return state.copyWith(
        trimmedStart: Duration.zero,
        trimmedEnd: Duration.zero,
        silencePeriods: const [],
      );
    }

    final result = state.copyWith(
      trimmedStart: trimmedStart,
      trimmedEnd: trimmedEnd,
      silencePeriods: finalSilencePeriods,
    );

    debugPrint('SmartRecording: Stopped monitoring');
    debugPrint('  Recording duration: $recordingDuration');
    debugPrint('  Trimmed start: $trimmedStart');
    debugPrint('  Trimmed end: $trimmedEnd');
    debugPrint('  Middle silence periods: ${finalSilencePeriods.length}');
    for (int i = 0; i < finalSilencePeriods.length; i++) {
      final p = finalSilencePeriods[i];
      debugPrint('    [$i] ${p.startTime} ~ ${p.endTime} (skip ${p.duration})');
    }

    _recordingStartTime = null;
    return result;
  }

  void _onAmplitude(double amplitude) {
    if (_recordingStartTime == null) return;

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
      } else if (state.phase == RecordingPhase.ending) {
        // Sound resumed after silence - check if middle silence should be recorded
        if (state.middleSilenceStartTime != null && _middleSilenceSkipEnabled) {
          final silenceDuration = now.difference(state.middleSilenceStartTime!);
          if (silenceDuration >= _middleSilenceThreshold) {
            // Add silence period (with buffer on each end)
            const buffer = Duration(seconds: 3);
            final startOffset = state.middleSilenceStartTime!.difference(_recordingStartTime!);
            final endOffset = now.difference(_recordingStartTime!);

            // Only add if the skipped portion is positive
            if (endOffset - startOffset > buffer * 2) {
              final newPeriod = SilencePeriod(
                startTime: startOffset + buffer,
                endTime: endOffset - buffer,
              );
              final updatedPeriods = [...state.silencePeriods, newPeriod];
              state = state.copyWith(
                phase: RecordingPhase.recording,
                soundEndTime: now,
                silencePeriods: updatedPeriods,
                clearMiddleSilenceStartTime: true,
              );
              debugPrint('SmartRecording: Added middle silence skip: ${newPeriod.startTime} ~ ${newPeriod.endTime}');
              return;
            }
          }
        }
        // Resume recording without adding silence period
        state = state.copyWith(
          phase: RecordingPhase.recording,
          soundEndTime: now,
          clearMiddleSilenceStartTime: true,
        );
        debugPrint('SmartRecording: Sound resumed at ${now.difference(_recordingStartTime!)}');
      } else {
        // Update last sound time
        state = state.copyWith(soundEndTime: now);
      }
    } else {
      // Silence detected
      if (state.phase == RecordingPhase.recording) {
        // Start tracking potential middle silence
        state = state.copyWith(
          phase: RecordingPhase.ending,
          middleSilenceStartTime: now,
        );
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
