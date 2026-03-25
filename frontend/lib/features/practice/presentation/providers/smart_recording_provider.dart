import 'dart:async';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/smart_recording.dart';
import './recording_provider.dart';

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
      // Failed to load settings, use defaults
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.put(_settingsKey, state.toJson());
    } catch (e) {
      // Failed to save settings
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

  /// Minimum duration of continuous sound to consider it a real sound (debounce).
  static const _soundDebounce = Duration(milliseconds: 500);

  /// Tracks when sound tentatively started during ending phase.
  DateTime? _tentativeSoundStart;

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
    if (!state.isEnabled) {
      return;
    }

    _amplitudeSubscription?.cancel();
    _recordingStartTime = DateTime.now();

    // Reload settings
    final settings = ref.read(smartRecordingSettingsNotifierProvider);
    _middleSilenceThreshold = settings.middleSilenceThresholdDuration;
    _middleSilenceSkipEnabled = settings.middleSilenceSkipEnabled;

    state = state.resetForNewRecording();
    _tentativeSoundStart = null;

    final recorder = ref.read(audioRecorderServiceProvider);
    _amplitudeSubscription = recorder.normalizedAmplitudeStream.listen(_onAmplitude);
  }

  /// Stop monitoring and calculate trim durations.
  SmartRecordingState stopMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (!state.isEnabled || _recordingStartTime == null) {
      return state;
    }

    final now = DateTime.now();

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
    // Use 1.5s buffer on each side = 3s total silence kept
    const middleSilenceBuffer = Duration(milliseconds: 1500);
    List<SilencePeriod> finalSilencePeriods = List.from(state.silencePeriods);
    if (state.middleSilenceStartTime != null && _middleSilenceSkipEnabled) {
      final silenceDuration = now.difference(state.middleSilenceStartTime!);
      if (silenceDuration >= _middleSilenceThreshold) {
        final startOffset = state.middleSilenceStartTime!.difference(_recordingStartTime!);
        final endOffset = now.difference(_recordingStartTime!);
        // Only add if the skipped portion is positive
        if (endOffset - startOffset > middleSilenceBuffer * 2) {
          finalSilencePeriods.add(SilencePeriod(
            startTime: startOffset + middleSilenceBuffer,
            endTime: endOffset - middleSilenceBuffer,
          ));
        }
      }
    }

    // Handle edge case: entire recording is silent
    if (state.phase == RecordingPhase.waiting) {
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
      } else if (state.phase == RecordingPhase.ending) {
        // Sound detected during ending phase - use debounce to avoid noise spikes
        if (_tentativeSoundStart == null) {
          // Start tracking tentative sound
          _tentativeSoundStart = now;
        } else if (now.difference(_tentativeSoundStart!) >= _soundDebounce) {
          // Sound has been continuous for debounce duration, consider it real
          // Check if middle silence should be recorded
          if (state.middleSilenceStartTime != null && _middleSilenceSkipEnabled) {
            final silenceDuration = _tentativeSoundStart!.difference(state.middleSilenceStartTime!);
            if (silenceDuration >= _middleSilenceThreshold) {
              // Add silence period (with buffer on each end)
              // Use 1.5s buffer on each side = 3s total silence kept
              const buffer = Duration(milliseconds: 1500);
              final startOffset = state.middleSilenceStartTime!.difference(_recordingStartTime!);
              final endOffset = _tentativeSoundStart!.difference(_recordingStartTime!);

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
                _tentativeSoundStart = null;
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
          _tentativeSoundStart = null;
        }
        // Keep updating soundEndTime during tentative sound
        state = state.copyWith(soundEndTime: now);
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
        _tentativeSoundStart = null;
      } else if (state.phase == RecordingPhase.ending) {
        // Reset tentative sound if silence detected again
        _tentativeSoundStart = null;
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
    _tentativeSoundStart = null;

    final settings = ref.read(smartRecordingSettingsNotifierProvider);
    state = SmartRecordingState(
      isEnabled: settings.smartRecordingEnabled,
      threshold: settings.trimThreshold,
    );
  }
}
