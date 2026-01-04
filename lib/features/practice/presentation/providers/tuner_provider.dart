import 'dart:async';

import 'package:flutter/foundation.dart';
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
      debugPrint('Tuner: disposing');
      _noteSubscription?.cancel();
      _engine?.dispose();
      _engine = null;
    });

    return initialState;
  }

  /// Create and configure the tuner engine.
  void _createEngine(TunerEngineType type, [double? referenceFrequency]) {
    debugPrint('Tuner: Creating engine type: $type');

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

    debugPrint('Tuner: _initAsync started');

    // Load saved settings from Hive
    try {
      final savedSettings = await _storageService.loadSettings();
      state = state.copyWith(settings: savedSettings);
      debugPrint('Tuner: Loaded settings - refFreq: ${savedSettings.referenceFrequency}');
    } catch (e) {
      debugPrint('Tuner: Failed to load settings: $e');
    }

    final success = await _engine!.init();

    if (success) {
      _engine!.referenceFrequency = state.settings.referenceFrequency;
      state = state.copyWith(isInitialized: true);
      debugPrint('Tuner: _initAsync completed successfully');
    } else {
      state = state.copyWith(error: 'Failed to initialize tuner');
      debugPrint('Tuner: _initAsync failed');
    }
  }

  /// Save current settings to persistent storage.
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(state.settings);
      debugPrint('Tuner: Settings saved');
    } catch (e) {
      debugPrint('Tuner: Failed to save settings: $e');
    }
  }

  void _onPitchDetected(TunerNote? note) {
    if (note == null) {
      state = state.copyWith(
        currentNote: null,
        status: TuningStatus.idle,
        clearNote: true,
      );
    } else {
      // Use difficulty-aware status for consistency with isPerfect
      final status = note.statusForDifficulty(state.settings.difficulty);
      state = state.copyWith(
        currentNote: note,
        status: status,
      );
    }
  }

  void _onError(String message) {
    debugPrint('Tuner error: $message');
    state = state.copyWith(error: message);
  }

  /// Start listening for pitch.
  Future<void> start() async {
    if (state.isListening) return;

    debugPrint('Tuner: start called');
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

    debugPrint('Tuner: stop called');
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
    debugPrint('Tuner: setReferenceFrequency $clamped');

    state = state.copyWith(
      settings: state.settings.copyWith(referenceFrequency: clamped),
    );

    _engine?.referenceFrequency = clamped;
    _saveSettings();
  }

  /// Update transposition setting.
  void setTransposition(Transposition transposition) {
    debugPrint('Tuner: setTransposition $transposition');
    state = state.copyWith(
      settings: state.settings.copyWith(transposition: transposition),
    );
    _saveSettings();
  }

  /// Update enharmonic display mode.
  void setEnharmonicMode(EnharmonicMode mode) {
    debugPrint('Tuner: setEnharmonicMode $mode');
    state = state.copyWith(
      settings: state.settings.copyWith(enharmonicMode: mode),
    );
    _saveSettings();
  }

  /// Update difficulty level.
  void setDifficulty(TunerDifficulty difficulty) {
    debugPrint('Tuner: setDifficulty $difficulty');
    state = state.copyWith(
      settings: state.settings.copyWith(difficulty: difficulty),
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
    debugPrint('Tuner: updateSettings');
    state = state.copyWith(settings: settings);
    _engine?.referenceFrequency = settings.referenceFrequency;
    _saveSettings();
  }

  /// Switch between tuner engines.
  Future<void> switchEngine(TunerEngineType type) async {
    if (_currentEngineType == type) return;

    debugPrint('Tuner: Switching engine from $_currentEngineType to $type');

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
}

/// Provider for current note display name.
@riverpod
String? currentNoteName(CurrentNoteNameRef ref) {
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
String tunerInfoDisplay(TunerInfoDisplayRef ref) {
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
