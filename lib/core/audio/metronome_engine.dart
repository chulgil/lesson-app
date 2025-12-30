import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:metronome/metronome.dart' as pkg;
import '../../models/metronome_settings.dart';
import 'metronome_engine_interface.dart';

/// High-precision metronome engine using the metronome package.
///
/// Uses platform-native audio scheduling for sample-accurate timing.
/// Supports different sounds for strong/medium/weak beats.
class MetronomeEngine implements MetronomeEngineInterface {
  MetronomeEngine();

  pkg.Metronome? _metronome;
  StreamSubscription<int>? _tickSubscription;

  // Timer-based beat tracking (fallback when tickStream doesn't work)
  Timer? _beatTimer;
  Stopwatch? _stopwatch;
  int _expectedTicks = 0;
  bool _useNativeTick = true; // Try native tickStream first

  MetronomeSettings _settings = const MetronomeSettings();
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _initialized = false;

  @override
  BeatCallback? onBeat;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get currentBeat => _currentBeat;

  @override
  MetronomeSettings get settings => _settings;

  /// Get audio paths based on accent pattern.
  /// - uniform: same file for all beats (no accent difference)
  /// - firstBeatOnly/strongMediumWeak: strong for accent, medium for main
  (String mainPath, String accentPath) _getAudioPaths(MetronomeSettings settings) {
    final mainPath = settings.sound.getAssetPath(BeatType.medium);

    // For uniform pattern, use same sound for all beats
    if (settings.accentPattern == AccentPattern.uniform) {
      debugPrint('MetronomeEngine: Uniform pattern - using same sound for all beats');
      return (mainPath, mainPath);
    }

    // For accent patterns, use strong sound for first beat
    final accentPath = settings.sound.getAssetPath(BeatType.strong);
    debugPrint('MetronomeEngine: Accent pattern - main: $mainPath, accent: $accentPath');
    return (mainPath, accentPath);
  }

  @override
  Future<void> init() async {
    if (_initialized) return;

    final stopwatch = Stopwatch()..start();
    debugPrint('MetronomeEngine: init started');

    try {
      _metronome = pkg.Metronome();
      debugPrint('MetronomeEngine: Metronome() created at ${stopwatch.elapsedMilliseconds}ms');

      // Get audio paths based on accent pattern
      final (mainPath, accentPath) = _getAudioPaths(_settings);

      debugPrint('MetronomeEngine: calling _metronome.init() at ${stopwatch.elapsedMilliseconds}ms');
      await _metronome!.init(
        mainPath,
        accentedPath: accentPath,
        bpm: _settings.bpm,
        volume: 100,
        enableTickCallback: true,
        timeSignature: _mapTimeSignature(_settings.timeSignature),
        sampleRate: 44100,
      );
      debugPrint('MetronomeEngine: _metronome.init() done at ${stopwatch.elapsedMilliseconds}ms');

      // Listen for tick events
      _tickSubscription = _metronome!.tickStream.listen(_onTick);

      _initialized = true;
      debugPrint('MetronomeEngine: Metronome package initialized in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('MetronomeEngine: Init failed: $e');
    }
  }

  void _onTick(int tick) {
    // Native tickStream is working - use it and disable timer fallback
    if (_useNativeTick) {
      debugPrint('MetronomeEngine: Native tickStream working, disabling timer fallback');
      _useNativeTick = false; // Mark that native tick works
      _stopBeatTimer(); // Stop any running timer
    }

    // metronome package tick is 0-indexed within time signature
    _currentBeat = tick + 1;

    final isAccent =
        _currentBeat == 1 && _settings.accentPattern != AccentPattern.uniform;

    debugPrint('MetronomeEngine: _onTick beat=$_currentBeat isAccent=$isAccent');

    // Notify listeners
    onBeat?.call(_currentBeat, isAccent);
  }

  /// Timer-based beat tracking with drift correction.
  void _onTimerTick() {
    if (!_isPlaying) return;

    _expectedTicks++;
    _currentBeat = ((_currentBeat) % _mapTimeSignature(_settings.timeSignature)) + 1;

    final isAccent =
        _currentBeat == 1 && _settings.accentPattern != AccentPattern.uniform;

    // Notify listeners
    onBeat?.call(_currentBeat, isAccent);

    // Drift correction for next tick
    if (_stopwatch != null) {
      final expectedMs = _expectedTicks * _msPerBeat;
      final actualMs = _stopwatch!.elapsedMilliseconds;
      final drift = actualMs - expectedMs;

      // Adjust next interval to compensate for drift
      final nextInterval = _msPerBeat - drift;
      if (nextInterval > 0) {
        _beatTimer?.cancel();
        _beatTimer = Timer(Duration(milliseconds: nextInterval.round()), _onTimerTick);
      } else {
        // We're behind, fire immediately
        _beatTimer?.cancel();
        Timer.run(_onTimerTick);
      }
    }
  }

  double get _msPerBeat => 60000.0 / _settings.bpm;

  void _startBeatTimer() {
    _stopBeatTimer();

    _stopwatch = Stopwatch()..start();
    _expectedTicks = 0;
    _currentBeat = 0;

    // First beat fires immediately
    _beatTimer = Timer(Duration(milliseconds: _msPerBeat.round()), _onTimerTick);
    debugPrint('MetronomeEngine: Timer-based beat tracking started');
  }

  void _stopBeatTimer() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _stopwatch?.stop();
    _stopwatch = null;
    _expectedTicks = 0;
  }

  int _mapTimeSignature(TimeSignature ts) {
    return switch (ts) {
      TimeSignature.twoFour => 2,
      TimeSignature.threeFour => 3,
      TimeSignature.fourFour => 4,
      TimeSignature.sixEight => 6,
    };
  }

  @override
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    debugPrint('MetronomeEngine: updateSettings called');

    final soundChanged = _settings.sound != newSettings.sound;
    final bpmChanged = _settings.bpm != newSettings.bpm;
    final timeSignatureChanged =
        _settings.timeSignature != newSettings.timeSignature;
    final accentPatternChanged =
        _settings.accentPattern != newSettings.accentPattern;

    _settings = newSettings;

    if (!_initialized || _metronome == null) {
      debugPrint('MetronomeEngine: Not initialized, skipping engine update');
      return;
    }

    try {
      // Update metronome settings without stopping
      // The metronome package handles live updates
      if (bpmChanged) {
        debugPrint('MetronomeEngine: Setting BPM to ${newSettings.bpm}');
        await _metronome!.setBPM(newSettings.bpm);
      }

      if (timeSignatureChanged) {
        debugPrint('MetronomeEngine: Setting time signature');
        await _metronome!.setTimeSignature(
          _mapTimeSignature(newSettings.timeSignature),
        );
      }

      // Update audio files when sound OR accent pattern changes
      if (soundChanged || accentPatternChanged) {
        debugPrint('MetronomeEngine: Setting audio files (sound: $soundChanged, accent: $accentPatternChanged)');
        final (mainPath, accentPath) = _getAudioPaths(newSettings);
        await _metronome!.setAudioFile(
          mainPath: mainPath,
          accentedPath: accentPath,
        );
      }
    } catch (e) {
      debugPrint('MetronomeEngine: updateSettings error: $e');
    }
  }

  @override
  Future<void> start() async {
    if (_isPlaying) return;
    if (!_initialized) {
      await init();
    }

    _isPlaying = true;
    _currentBeat = 0;

    // Start timer-based beat tracking as fallback
    // If native tickStream works, the timer will be stopped in _onTick
    _useNativeTick = true;
    _startBeatTimer();

    // Don't await - play() can be slow on some devices
    _metronome?.play();
    debugPrint('MetronomeEngine: Started at ${_settings.bpm} BPM');
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _stopBeatTimer();
    // Don't await - pause() can be slow on some devices
    _metronome?.pause();
    _currentBeat = 0;
    debugPrint('MetronomeEngine: Stopped');
  }

  @override
  Future<void> toggle() async {
    if (_isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_initialized && _metronome != null) {
      await _metronome!.setBPM(clampedBpm);
    }
  }

  @override
  Future<void> incrementBpm(int delta) async {
    await setBpm(_settings.bpm + delta);
  }

  @override
  Future<void> dispose() async {
    await stop();
    _stopBeatTimer();
    await _tickSubscription?.cancel();
    _tickSubscription = null;

    if (_initialized && _metronome != null) {
      await _metronome!.destroy();
      _metronome = null;
      _initialized = false;
    }
    debugPrint('MetronomeEngine: Disposed');
  }
}
