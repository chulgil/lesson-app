import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/audio/mock_tuner_engine.dart';
import '../../../../core/audio/record_tuner_engine.dart';
import '../../../../core/audio/tuner_engine.dart';
import '../../../../services/tuner_storage_service.dart';
import '../../domain/entities/tuner_settings.dart';
import '../../domain/entities/tuner_types.dart';

part 'tuner_provider.g.dart';

/// Engine type for tuner.
enum TunerEngineType {
  /// Mock engine for development/testing
  mock,

  /// Real pitch detection engine using record package (all platforms)
  record,
}

/// State for the tuner.
@immutable
class TunerProviderState {
  const TunerProviderState({
    this.settings = const TunerSettings(),
    this.isListening = false,
    this.currentNote,
    this.status = TuningStatus.idle,
    this.isInitialized = false,
    this.error,
    this.engineType = TunerEngineType.record,
  });

  /// Current tuner settings.
  final TunerSettings settings;

  /// Whether the tuner is actively listening.
  final bool isListening;

  /// Currently detected note (null if none).
  final TunerNote? currentNote;

  /// Current tuning status.
  final TuningStatus status;

  /// Whether the engine is initialized.
  final bool isInitialized;

  /// Error message if any.
  final String? error;

  /// Current engine type.
  final TunerEngineType engineType;

  /// Cent deviation of current note (0 if no note).
  double get centDeviation => currentNote?.centDeviation ?? 0;

  /// Whether tuning is perfect (based on difficulty setting).
  bool get isPerfect =>
      currentNote != null &&
      currentNote!.centDeviation.abs() <= settings.difficulty.perfectCent;

  /// Whether tuning is good but not perfect (based on difficulty setting).
  bool get isGood =>
      currentNote != null &&
      !isPerfect &&
      currentNote!.centDeviation.abs() <= settings.difficulty.goodCent;

  TunerProviderState copyWith({
    TunerSettings? settings,
    bool? isListening,
    TunerNote? currentNote,
    TuningStatus? status,
    bool? isInitialized,
    String? error,
    TunerEngineType? engineType,
    bool clearNote = false,
    bool clearError = false,
  }) {
    return TunerProviderState(
      settings: settings ?? this.settings,
      isListening: isListening ?? this.isListening,
      currentNote: clearNote ? null : (currentNote ?? this.currentNote),
      status: status ?? this.status,
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
      engineType: engineType ?? this.engineType,
    );
  }
}

/// Tuner state management with Riverpod.
///
/// Provides pitch detection using the device microphone.
/// Supports both MockTunerEngine (for development) and PitchTunerEngine (real detection).
@Riverpod(keepAlive: true)
class Tuner extends _$Tuner {
  TunerEngine? _engine;
  StreamSubscription<TunerNote?>? _noteSubscription;
  bool _initialized = false;
  TunerEngineType _currentEngineType = TunerEngineType.record;
  final _storageService = TunerStorageService();

  // Same-note continuity tracking
  NoteName? _lastDetectedNoteName;
  DateTime? _lastNoteTime;

  // App lifecycle tracking - was listening before app paused?
  bool _wasListeningBeforePause = false;

  @override
  TunerProviderState build() {
    // Use RecordTunerEngine for all platforms (uses record package)
    const defaultType = TunerEngineType.record;
    _currentEngineType = defaultType;

    // Create initial state first
    final initialState = TunerProviderState(engineType: defaultType);

    // Create engine with default settings (state not yet available in build)
    _createEngine(defaultType, initialState.settings.referenceFrequency);

    // Initialize engine and load settings after build completes
    Future.microtask(_initAsync);

    ref.onDispose(() {
      _noteSubscription?.cancel();
      _engine?.dispose();
      _engine = null;
    });

    return initialState;
  }

  /// Create and configure the tuner engine.
  void _createEngine(TunerEngineType type, [double? referenceFrequency]) {
    // Use provided frequency or fall back to current state settings
    final refFreq = referenceFrequency ?? state.settings.referenceFrequency;

    _engine = switch (type) {
      TunerEngineType.mock => MockTunerEngine(
          simulationMode: MockSimulationMode.tuningApproach,
        ),
      TunerEngineType.record => RecordTunerEngine(
          referenceFrequency: refFreq,
        ),
    };

    _engine!.onPitchDetected = _onPitchDetected;
    _engine!.onError = _onError;

    // Subscribe to note stream
    _noteSubscription = _engine!.noteStream.listen(_onPitchDetected);
  }

  Future<void> _initAsync() async {
    if (_initialized) return;
    _initialized = true;

    // Load saved settings from Hive
    try {
      final savedSettings = await _storageService.loadSettings();
      state = state.copyWith(settings: savedSettings);
    } catch (e) {
      // Failed to load settings, use defaults
    }

    final success = await _engine!.init();

    if (success) {
      _engine!.referenceFrequency = state.settings.referenceFrequency;
      state = state.copyWith(isInitialized: true);
    } else {
      state = state.copyWith(error: 'Failed to initialize tuner');
    }
  }

  /// Save current settings to persistent storage.
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(state.settings);
    } catch (e) {
      // Failed to save settings
    }
  }

  void _onPitchDetected(TunerNote? note) {
    // Get grace period from difficulty setting
    final gracePeriodMs = state.settings.difficulty.gracePeriodMs;

    if (note == null) {
      // Don't immediately clear - check if we're within grace period
      // This allows brief gaps in sound while maintaining continuity for same note
      if (gracePeriodMs > 0 && _lastDetectedNoteName != null && _lastNoteTime != null) {
        final elapsed = DateTime.now().difference(_lastNoteTime!).inMilliseconds;
        if (elapsed < gracePeriodMs) {
          // Within grace period - keep current state (don't reset)
          // The currentNote stays as is, allowing isPerfect to remain true
          return;
        }
      }

      // Grace period expired or no previous note - reset
      _lastDetectedNoteName = null;
      _lastNoteTime = null;
      state = state.copyWith(
        currentNote: null,
        status: TuningStatus.idle,
        clearNote: true,
      );
    } else {
      // Check if this is the same note (continuity) or a new note
      final isSameNote = _lastDetectedNoteName == note.name;
      final elapsed = _lastNoteTime != null
          ? DateTime.now().difference(_lastNoteTime!).inMilliseconds
          : gracePeriodMs + 1; // If no previous time, treat as expired
      final wasWithinGrace = gracePeriodMs > 0 && elapsed < gracePeriodMs;

      // If same note but grace period expired, this is a fresh start
      // Briefly reset to trigger animation restart
      if (isSameNote && !wasWithinGrace && _lastNoteTime != null) {
        // Reset state to trigger animation restart
        state = state.copyWith(
          currentNote: null,
          status: TuningStatus.idle,
          clearNote: true,
        );
      }

      // Update tracking
      _lastDetectedNoteName = note.name;
      _lastNoteTime = DateTime.now();

      // Use difficulty-aware status for consistency with isPerfect
      final status = note.statusForDifficulty(state.settings.difficulty);
      state = state.copyWith(
        currentNote: note,
        status: status,
      );
    }
  }

  void _onError(String message) {
    state = state.copyWith(error: message);
  }

  /// Start listening for pitch.
  Future<void> start() async {
    if (state.isListening) return;

    state = state.copyWith(
      isListening: true,
      status: TuningStatus.listening,
      clearError: true,
    );

    await _engine?.start();
  }

  /// Stop listening.
  Future<void> stop() async {
    if (!state.isListening) return;

    state = state.copyWith(
      isListening: false,
      status: TuningStatus.idle,
      clearNote: true,
    );

    await _engine?.stop();
  }

  /// Toggle listening state.
  Future<void> toggle() async {
    if (state.isListening) {
      await stop();
    } else {
      await start();
    }
  }

  /// Update reference frequency (430-450Hz).
  void setReferenceFrequency(double frequency) {
    final clamped = TunerSettings.clampFrequency(frequency);

    state = state.copyWith(
      settings: state.settings.copyWith(referenceFrequency: clamped),
    );

    _engine?.referenceFrequency = clamped;
    _saveSettings();
  }

  /// Update transposition setting.
  void setTransposition(Transposition transposition) {
    state = state.copyWith(
      settings: state.settings.copyWith(transposition: transposition),
    );
    _saveSettings();
  }

  /// Update enharmonic display mode.
  void setEnharmonicMode(EnharmonicMode mode) {
    state = state.copyWith(
      settings: state.settings.copyWith(enharmonicMode: mode),
    );
    _saveSettings();
  }

  /// Update difficulty level.
  void setDifficulty(TunerDifficulty difficulty) {
    state = state.copyWith(
      settings: state.settings.copyWith(difficulty: difficulty),
    );
    _saveSettings();
  }

  /// Update clef type for staff notation.
  void setClefType(ClefType clefType) {
    state = state.copyWith(
      settings: state.settings.copyWith(clefType: clefType),
    );
    _saveSettings();
  }

  /// Toggle auto-switch clef (for instruments like cello that use both clefs).
  void toggleAutoSwitchClef() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        autoSwitchClef: !state.settings.autoSwitchClef,
      ),
    );
    _saveSettings();
  }

  /// Toggle combo counter visibility.
  void toggleShowCombo() {
    state = state.copyWith(
      settings: state.settings.copyWith(showCombo: !state.settings.showCombo),
    );
    _saveSettings();
  }

  /// Toggle vibration feedback.
  void toggleVibrationFeedback() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        vibrationFeedback: !state.settings.vibrationFeedback,
      ),
    );
    _saveSettings();
  }

  /// Update all settings at once.
  void updateSettings(TunerSettings settings) {
    state = state.copyWith(settings: settings);
    _engine?.referenceFrequency = settings.referenceFrequency;
    _saveSettings();
  }

  /// Switch between tuner engines.
  Future<void> switchEngine(TunerEngineType type) async {
    if (_currentEngineType == type) return;

    // Stop current engine
    final wasListening = state.isListening;
    if (wasListening) {
      await stop();
    }

    // Dispose current engine
    _noteSubscription?.cancel();
    _engine?.dispose();
    _initialized = false;

    // Create new engine
    _currentEngineType = type;
    _createEngine(type);

    // Update state
    state = state.copyWith(
      engineType: type,
      isInitialized: false,
    );

    // Restart if was listening
    if (wasListening) {
      await start();
    }
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Warm up the tuner engine by starting the microphone stream without processing.
  ///
  /// This should be called when the practice tools modal opens.
  /// It pre-configures the audio session and starts the microphone,
  /// so that enabling processing later (on tuner tab) is instantaneous
  /// and doesn't interfere with metronome playback.
  Future<void> warmUp() async {
    if (_engine == null) {
      await _initAsync();
    }

    await _engine?.warmUp();
  }

  /// Enable pitch processing (instant, no audio session reconfiguration).
  ///
  /// Call this when switching to the tuner tab.
  /// Requires [warmUp] to have been called first.
  void enableProcessing() {
    _engine?.enableProcessing();

    state = state.copyWith(
      isListening: true,
      status: TuningStatus.listening,
      clearError: true,
    );
  }

  /// Disable pitch processing but keep the microphone stream active.
  ///
  /// Call this when switching away from the tuner tab.
  /// The stream stays active so re-enabling is instant.
  void disableProcessing() {
    _engine?.disableProcessing();

    // Reset continuity tracking
    _lastDetectedNoteName = null;
    _lastNoteTime = null;

    state = state.copyWith(
      isListening: false,
      status: TuningStatus.idle,
      clearNote: true,
    );
  }

  /// Stop the tuner completely (including the microphone stream).
  ///
  /// Call this when the practice tools modal closes.
  Future<void> stopCompletely() async {
    _wasListeningBeforePause = false;
    await stop();
  }

  /// Called when app goes to background (paused).
  /// Disables processing but keeps stream active for quick resume.
  Future<void> onAppPaused() async {
    if (state.isListening) {
      _wasListeningBeforePause = true;
      disableProcessing();
    } else {
      _wasListeningBeforePause = false;
    }
  }

  /// Called when app returns to foreground (resumed).
  /// Re-enables processing if it was active before pause.
  Future<void> onAppResumed() async {
    if (_wasListeningBeforePause) {
      _wasListeningBeforePause = false;
      enableProcessing();
    }
  }
}

/// Provider for current note display name.
@riverpod
String? currentNoteName(Ref ref) {
  final tunerState = ref.watch(tunerProvider);
  final note = tunerState.currentNote;
  if (note == null) return null;

  final settings = tunerState.settings;

  // Get display name based on enharmonic mode
  final displayName = switch (settings.enharmonicMode) {
    EnharmonicMode.sharpOnly => note.name.sharpName,
    EnharmonicMode.flatOnly => note.name.flatName,
    EnharmonicMode.both => note.name.enharmonicName,
  };

  // Apply transposition display if not concert pitch
  if (settings.transposition != Transposition.c) {
    final transposed = settings.transposition.transpose(note.name);
    final transposedName = settings.enharmonicMode == EnharmonicMode.flatOnly
        ? transposed.flatName
        : transposed.sharpName;
    return '$displayName ($transposedName${note.octave})';
  }

  return '$displayName${note.octave}';
}

/// Provider for tuner info display string (e.g., "A4 · 442Hz · +5¢").
@riverpod
String tunerInfoDisplay(Ref ref) {
  final tunerState = ref.watch(tunerProvider);
  final note = tunerState.currentNote;
  final settings = tunerState.settings;

  if (note == null) {
    return 'A4 = ${settings.referenceFrequency.toStringAsFixed(0)}Hz';
  }

  final noteName = ref.watch(currentNoteNameProvider) ?? '';
  final hz = note.frequency.toStringAsFixed(1);
  final cent = note.centDisplayString;

  return '$noteName · ${hz}Hz · $cent¢';
}
