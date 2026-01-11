import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/audio/metronome_engine_interface.dart';
import '../../../../core/audio/soloud_metronome_engine.dart';
import '../../../../models/metronome_settings.dart';
import '../../../../services/metronome_storage_service.dart';

part 'metronome_provider.g.dart';

/// State for the metronome.
@immutable
class MetronomeState {
  const MetronomeState({
    this.settings = const MetronomeSettings(),
    this.isPlaying = false,
    this.currentBeat = 0,
    this.isAccent = false,
    this.isLoading = false,
    this.isReady = false,
  });

  final MetronomeSettings settings;
  final bool isPlaying;
  final int currentBeat;
  final bool isAccent;
  final bool isLoading; // True while toggling play/stop
  final bool isReady; // True when engine is initialized

  MetronomeState copyWith({
    MetronomeSettings? settings,
    bool? isPlaying,
    int? currentBeat,
    bool? isAccent,
    bool? isLoading,
    bool? isReady,
  }) {
    return MetronomeState(
      settings: settings ?? this.settings,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBeat: currentBeat ?? this.currentBeat,
      isAccent: isAccent ?? this.isAccent,
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
    );
  }
}

/// Metronome state management with Riverpod.
///
/// Uses flutter_soloud (C++ SoLoud via FFI) for low-latency native audio
/// on all platforms (iOS, Android, Mac, Windows, Linux, Web).
@Riverpod(keepAlive: true)
class Metronome extends _$Metronome {
  MetronomeEngineInterface? _engine;
  final MetronomeStorageService _storage = MetronomeStorageService();
  bool _initialized = false;
  bool _engineReady = false;

  @override
  MetronomeState build() {
    // Use SoLoud-based engine for low-latency audio on all platforms
    debugPrint('Metronome: Using SoLoud engine for low-latency audio');
    _engine = SoLoudMetronomeEngine();

    _engine!.onBeat = _onBeat;

    // Initialize engine and load saved settings
    _initAsync();

    ref.onDispose(() {
      _engine?.dispose();
      _engine = null;
    });

    return const MetronomeState();
  }

  Future<void> _initAsync() async {
    if (_initialized) return;
    _initialized = true;

    final stopwatch = Stopwatch()..start();
    debugPrint('Metronome: _initAsync started');

    // Load saved settings (in parallel with engine init for speed)
    final settingsFuture = _storage.loadSettings();

    debugPrint('Metronome: Starting engine.init() at ${stopwatch.elapsedMilliseconds}ms');
    await _engine!.init();
    debugPrint('Metronome: engine.init() done at ${stopwatch.elapsedMilliseconds}ms');

    final savedSettings = await settingsFuture;
    debugPrint('Metronome: settings loaded at ${stopwatch.elapsedMilliseconds}ms');

    await _engine!.updateSettings(savedSettings);
    debugPrint('Metronome: updateSettings done at ${stopwatch.elapsedMilliseconds}ms');

    _engineReady = true;
    state = state.copyWith(settings: savedSettings, isReady: true);
    debugPrint('Metronome: _initAsync completed in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Wait for engine to be ready before starting
  Future<void> _ensureReady() async {
    if (_engineReady) return;
    // Wait for initialization to complete (max 2 seconds)
    for (var i = 0; i < 40; i++) {
      if (_engineReady) return;
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Pre-warm the engine to reduce first-play latency.
  /// Call this when metronome screen opens.
  Future<void> warmUp() async {
    debugPrint('Metronome: warmUp called');
    await _ensureReady();
  }

  Future<void> _saveSettings() async {
    await _storage.saveSettings(state.settings);
  }

  void _onBeat(int beatNumber, bool isAccent) {
    state = state.copyWith(
      currentBeat: beatNumber,
      isAccent: isAccent,
    );
  }

  /// Start the metronome - immediate response, no waiting.
  void start() {
    if (state.isPlaying) return; // Already playing

    debugPrint('Metronome: start called');
    state = state.copyWith(isPlaying: true);

    // Start engine without blocking - it will catch up
    _engine?.start();
  }

  /// Stop the metronome - immediate response, no waiting.
  void stop() {
    if (!state.isPlaying) return; // Already stopped

    debugPrint('Metronome: stop called');
    state = state.copyWith(
      isPlaying: false,
      currentBeat: 0,
      isAccent: false,
    );

    // Stop engine without blocking
    _engine?.stop();
  }

  /// Toggle play/stop - immediate response.
  void toggle() {
    debugPrint('Metronome: toggle called, isPlaying: ${state.isPlaying}');
    if (state.isPlaying) {
      stop();
    } else {
      start();
    }
  }

  /// Set BPM (40-208 range).
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    debugPrint('Metronome: setBpm called with $bpm -> $clampedBpm');

    // Update state first to ensure UI responds immediately
    state = state.copyWith(
      settings: state.settings.copyWith(bpm: clampedBpm),
    );

    // Then update engine (non-blocking for UI)
    try {
      await _engine?.setBpm(clampedBpm);
    } catch (e) {
      debugPrint('Metronome: setBpm engine error: $e');
    }

    _saveSettings();
  }

  /// Increment BPM by given amount.
  Future<void> incrementBpm(int delta) async {
    debugPrint('Metronome: incrementBpm called with delta $delta');
    await setBpm(state.settings.bpm + delta);
  }

  /// Play a single tap sound (for tap tempo feedback).
  Future<void> playTapSound() async {
    await _engine?.playTapSound();
  }

  /// Set time signature.
  Future<void> setTimeSignature(TimeSignature timeSignature) async {
    debugPrint('Metronome: setTimeSignature called: $timeSignature');
    final newSettings = state.settings.copyWith(timeSignature: timeSignature);

    // Update state first for immediate UI response
    state = state.copyWith(settings: newSettings);

    // Then update engine (non-blocking for UI)
    try {
      await _engine?.updateSettings(newSettings);
    } catch (e) {
      debugPrint('Metronome: setTimeSignature engine error: $e');
    }

    _saveSettings();
  }

  /// Set metronome sound.
  Future<void> setSound(MetronomeSound sound) async {
    debugPrint('Metronome: setSound called: $sound');
    final newSettings = state.settings.copyWith(sound: sound);

    // Update state first for immediate UI response
    state = state.copyWith(settings: newSettings);

    // Then update engine (non-blocking for UI)
    try {
      await _engine?.updateSettings(newSettings);
    } catch (e) {
      debugPrint('Metronome: setSound engine error: $e');
    }

    _saveSettings();
  }

  /// Toggle visual flash.
  void toggleVisualFlash() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        visualFlash: !state.settings.visualFlash,
      ),
    );
    _saveSettings();
  }

  /// Toggle vibration.
  void toggleVibration() {
    state = state.copyWith(
      settings: state.settings.copyWith(
        vibration: !state.settings.vibration,
      ),
    );
    _saveSettings();
  }

  /// Set accent pattern.
  /// Note: metronome package only supports 2-level (main/accent), not 3-level (strong/medium/weak).
  /// - firstBeatOnly: first beat = accent, others = main
  /// - uniform: all beats = main (no accent)
  /// - strongMediumWeak: same as firstBeatOnly (3-level not supported by package)
  Future<void> setAccentPattern(AccentPattern pattern) async {
    debugPrint('Metronome: setAccentPattern called: $pattern');
    final newSettings = state.settings.copyWith(accentPattern: pattern);

    // Update state first for immediate UI response
    state = state.copyWith(settings: newSettings);

    // Then update engine (non-blocking for UI)
    try {
      await _engine?.updateSettings(newSettings);
    } catch (e) {
      debugPrint('Metronome: setAccentPattern engine error: $e');
    }

    _saveSettings();
  }

  /// Update all settings at once.
  Future<void> updateSettings(MetronomeSettings settings) async {
    debugPrint('Metronome: updateSettings called');

    // Update state first for immediate UI response
    state = state.copyWith(settings: settings);

    // Then update engine (non-blocking for UI)
    try {
      await _engine?.updateSettings(settings);
    } catch (e) {
      debugPrint('Metronome: updateSettings engine error: $e');
    }

    await _saveSettings();
  }
}
