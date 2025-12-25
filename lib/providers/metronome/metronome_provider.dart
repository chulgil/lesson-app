import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/audio/metronome_engine.dart';
import '../../models/metronome_settings.dart';
import '../../services/metronome_storage_service.dart';

part 'metronome_provider.g.dart';

/// State for the metronome.
@immutable
class MetronomeState {
  const MetronomeState({
    this.settings = const MetronomeSettings(),
    this.isPlaying = false,
    this.currentBeat = 0,
    this.isAccent = false,
  });

  final MetronomeSettings settings;
  final bool isPlaying;
  final int currentBeat;
  final bool isAccent;

  MetronomeState copyWith({
    MetronomeSettings? settings,
    bool? isPlaying,
    int? currentBeat,
    bool? isAccent,
  }) {
    return MetronomeState(
      settings: settings ?? this.settings,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBeat: currentBeat ?? this.currentBeat,
      isAccent: isAccent ?? this.isAccent,
    );
  }
}

/// Metronome state management with Riverpod.
@Riverpod(keepAlive: true)
class Metronome extends _$Metronome {
  MetronomeEngine? _engine;
  final MetronomeStorageService _storage = MetronomeStorageService();
  bool _initialized = false;
  bool _engineReady = false;

  @override
  MetronomeState build() {
    _engine = MetronomeEngine();
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

    // Load saved settings
    final savedSettings = await _storage.loadSettings();
    await _engine!.init();
    await _engine!.updateSettings(savedSettings);
    _engineReady = true;
    state = state.copyWith(settings: savedSettings);
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

  Future<void> _saveSettings() async {
    await _storage.saveSettings(state.settings);
  }

  void _onBeat(int beatNumber, bool isAccent) {
    state = state.copyWith(
      currentBeat: beatNumber,
      isAccent: isAccent,
    );
  }

  /// Start the metronome.
  Future<void> start() async {
    await _ensureReady();
    _engine?.start();
    state = state.copyWith(isPlaying: true);
  }

  /// Stop the metronome.
  void stop() {
    _engine?.stop();
    state = state.copyWith(
      isPlaying: false,
      currentBeat: 0,
      isAccent: false,
    );
  }

  /// Toggle play/stop.
  Future<void> toggle() async {
    if (state.isPlaying) {
      stop();
    } else {
      await start();
    }
  }

  /// Set BPM (40-208 range).
  void setBpm(int bpm) {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    _engine?.setBpm(clampedBpm);
    state = state.copyWith(
      settings: state.settings.copyWith(bpm: clampedBpm),
    );
    _saveSettings();
  }

  /// Increment BPM by given amount.
  void incrementBpm(int delta) {
    setBpm(state.settings.bpm + delta);
  }

  /// Set time signature.
  void setTimeSignature(TimeSignature timeSignature) {
    final newSettings = state.settings.copyWith(timeSignature: timeSignature);
    _engine?.updateSettings(newSettings);
    state = state.copyWith(settings: newSettings);
    _saveSettings();
  }

  /// Set metronome sound.
  void setSound(MetronomeSound sound) {
    final newSettings = state.settings.copyWith(sound: sound);
    _engine?.updateSettings(newSettings);
    state = state.copyWith(settings: newSettings);
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
  void setAccentPattern(AccentPattern pattern) {
    final newSettings = state.settings.copyWith(accentPattern: pattern);
    _engine?.updateSettings(newSettings);
    state = state.copyWith(settings: newSettings);
    _saveSettings();
  }

  /// Update all settings at once.
  Future<void> updateSettings(MetronomeSettings settings) async {
    await _engine?.updateSettings(settings);
    state = state.copyWith(settings: settings);
    await _saveSettings();
  }
}
