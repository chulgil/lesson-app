import 'dart:async';
import 'dart:isolate';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../models/metronome_settings.dart';
import 'metronome_engine_interface.dart';

/// Timing isolate entry point - runs high-precision timer independent of main thread.
/// Uses recursive microtask scheduling for precise timing while allowing message handling.
@pragma('vm:entry-point')
void _timingIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Stopwatch? stopwatch;
  int expectedTicks = 0;
  double intervalMs = 500.0;
  bool running = false;

  void scheduleNextCheck() {
    if (!running || stopwatch == null) return;

    final elapsedUs = stopwatch!.elapsedMicroseconds;
    final expectedTimeUs = ((expectedTicks + 1) * intervalMs * 1000).toInt();

    if (elapsedUs >= expectedTimeUs) {
      expectedTicks++;
      mainSendPort.send('tick');
    }

    // Calculate time until next beat
    final nextBeatUs = ((expectedTicks + 1) * intervalMs * 1000).toInt();
    final remainingUs = nextBeatUs - stopwatch!.elapsedMicroseconds;

    if (remainingUs > 5000) {
      // More than 5ms away - use Timer for efficiency
      Timer(Duration(microseconds: (remainingUs - 2000).clamp(100, 50000)), scheduleNextCheck);
    } else if (remainingUs > 500) {
      // 0.5-5ms away - use short timer
      Timer(Duration(microseconds: 100), scheduleNextCheck);
    } else {
      // Very close or past - use immediate scheduling
      Timer.run(scheduleNextCheck);
    }
  }

  void startTiming() {
    running = true;
    // Start at tick 1 (tick 0 is played immediately by main thread)
    expectedTicks = 1;
    stopwatch = Stopwatch()..start();
    // Don't send first tick - it's handled by main thread for instant response
    // Start the timing loop for subsequent ticks
    scheduleNextCheck();
  }

  void stopTiming() {
    running = false;
    stopwatch?.stop();
    stopwatch = null;
    expectedTicks = 0;
  }

  receivePort.listen((message) {
    if (message is String) {
      if (message == 'start') {
        startTiming();
      } else if (message == 'stop') {
        stopTiming();
      } else if (message == 'dispose') {
        stopTiming();
        receivePort.close();
        Isolate.exit();
      }
    } else if (message is double) {
      // Update interval
      intervalMs = message;
      // Reset timing when BPM changes (if running)
      if (running && stopwatch != null) {
        expectedTicks = 0;
        stopwatch!.reset();
        stopwatch!.start();
      }
    }
  });
}

/// SoLoud-based metronome engine with Isolate timing for precise playback.
///
/// Uses flutter_soloud (C++ SoLoud engine via FFI) for audio playback
/// and a separate Isolate for timing to avoid main thread interference.
class SoLoudMetronomeEngine implements MetronomeEngineInterface {
  SoLoudMetronomeEngine();

  final SoLoud _soloud = SoLoud.instance;

  // Sound sources for each beat type
  AudioSource? _strongSource;
  AudioSource? _mediumSource;
  AudioSource? _weakSource;

  // Isolate for timing
  Isolate? _timingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _receivePort;
  StreamSubscription? _tickSubscription;

  MetronomeSettings _settings = const MetronomeSettings();
  int _currentBeat = 0;
  int _currentSubdivision = 0; // 0-based index within beat
  int _tickCount = 0; // Total tick count within measure
  bool _isPlaying = false;
  bool _initialized = false;
  bool _soundsLoaded = false;
  bool _isolateReady = false;

  @override
  BeatCallback? onBeat;

  /// Callback for subdivision ticks (for UI visualization).
  void Function(int subdivisionIndex, bool isMainBeat)? onSubdivision;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get currentBeat => _currentBeat;

  @override
  MetronomeSettings get settings => _settings;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize SoLoud engine
      if (!_soloud.isInitialized) {
        await _soloud.init();
      }

      // Initialize timing isolate
      await _initIsolate();

      await _loadSounds();

      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initIsolate() async {
    if (_isolateReady) return;

    _receivePort = ReceivePort();
    _timingIsolate = await Isolate.spawn(
      _timingIsolateEntry,
      _receivePort!.sendPort,
    );

    // Wait for isolate to send its SendPort
    final completer = Completer<void>();
    _tickSubscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        _isolateReady = true;
        completer.complete();
      } else if (message == 'tick') {
        _tick();
      }
    });

    await completer.future;
  }

  Future<void> _loadSounds() async {
    if (_settings.sound == MetronomeSound.silent) {
      _soundsLoaded = false;
      return;
    }

    try {
      // Dispose old sources if any
      await _disposeSources();

      // Get asset paths for each beat type
      final strongPath = _settings.sound.getAssetPath(BeatType.strong);
      final mediumPath = _settings.sound.getAssetPath(BeatType.medium);
      final weakPath = _settings.sound.getAssetPath(BeatType.weak);

      // Load sounds using SoLoud
      _strongSource = await _soloud.loadAsset(strongPath);
      _mediumSource = await _soloud.loadAsset(mediumPath);
      _weakSource = await _soloud.loadAsset(weakPath);

      _soundsLoaded = true;
    } catch (_) {
      _soundsLoaded = false;
    }
  }

  Future<void> _disposeSources() async {
    if (_strongSource != null) {
      await _soloud.disposeSource(_strongSource!);
      _strongSource = null;
    }
    if (_mediumSource != null) {
      await _soloud.disposeSource(_mediumSource!);
      _mediumSource = null;
    }
    if (_weakSource != null) {
      await _soloud.disposeSource(_weakSource!);
      _weakSource = null;
    }
  }

  @override
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      await stop();
    }

    final soundChanged = _settings.sound != newSettings.sound;
    _settings = newSettings;

    // Reload sounds if sound type changed
    if (soundChanged) {
      await _loadSounds();
    }

    if (wasPlaying) {
      await start();
    }
  }

  /// Get interval for subdivision ticks (faster than beat interval).
  double get _subdivisionIntervalMs =>
      _settings.intervalMsPrecise / _settings.subdivision.divisionsPerBeat;

  /// Total ticks per measure (beats × subdivisions).
  int get _ticksPerMeasure =>
      _settings.timeSignature.beatsPerMeasure *
      _settings.subdivision.divisionsPerBeat;

  @override
  Future<void> start() async {
    if (_isPlaying) return;
    if (!_initialized) {
      await init();
    }

    _isPlaying = true;
    _currentBeat = 0;
    _currentSubdivision = 0;
    _tickCount = 0;

    // Play first beat immediately (no waiting for isolate round-trip)
    _tick();

    // Send subdivision interval to isolate (not beat interval)
    _isolateSendPort?.send(_subdivisionIntervalMs);
    // Start timing in isolate (will handle subsequent beats)
    _isolateSendPort?.send('start');
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentBeat = 0;
    _currentSubdivision = 0;
    _tickCount = 0;
    _isolateSendPort?.send('stop');
  }

  @override
  Future<void> toggle() async {
    if (_isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  void _tick() {
    if (!_isPlaying) return;

    final divisions = _settings.subdivision.divisionsPerBeat;

    // Calculate beat number and subdivision index from tick count
    _currentSubdivision = _tickCount % divisions;
    final beatIndex = _tickCount ~/ divisions;
    _currentBeat = (beatIndex % _settings.timeSignature.beatsPerMeasure) + 1;
    final isMainBeat = _currentSubdivision == 0;

    // Check if this subdivision should play sound (based on soundPattern)
    final shouldPlaySound = _settings.subdivision.shouldPlayAt(_currentSubdivision);

    // Determine sound to play
    final BeatType beatType;
    if (_settings.accentPattern == AccentPattern.uniform) {
      // Uniform: all sounds the same (main beats + subdivisions)
      beatType = BeatType.medium;
    } else if (isMainBeat) {
      // Main beat - use accent pattern
      beatType = _getBeatType(_currentBeat);
    } else {
      // Subdivision tick - always weak
      beatType = BeatType.weak;
    }

    // Notify callbacks BEFORE playing sound to minimize animation latency
    // (UI update starts while sound is being triggered)
    if (isMainBeat && shouldPlaySound) {
      final isAccent = _isAccentBeat(_currentBeat);
      onBeat?.call(_currentBeat, isAccent);
    }
    onSubdivision?.call(_currentSubdivision, isMainBeat);

    // Play sound only if this subdivision should sound (not a rest)
    if (shouldPlaySound) {
      _playBeat(beatType);
    }

    // Increment tick count
    _tickCount++;
    if (_tickCount >= _ticksPerMeasure) {
      _tickCount = 0;
    }
  }

  bool _isAccentBeat(int beat) {
    final ts = _settings.timeSignature;

    switch (_settings.accentPattern) {
      case AccentPattern.firstBeatOnly:
      case AccentPattern.strongMediumWeak:
        if (ts.isCompound) {
          // Compound time: accent every 3 beats (1, 4, 7, 10...)
          return (beat - 1) % 3 == 0;
        }
        return beat == 1;
      case AccentPattern.uniform:
        return false;
    }
  }

  BeatType _getBeatType(int beat) {
    final ts = _settings.timeSignature;

    switch (_settings.accentPattern) {
      case AccentPattern.uniform:
        return BeatType.medium;

      case AccentPattern.firstBeatOnly:
        if (ts.isCompound) {
          // Compound time: strong on every 3rd beat (1, 4, 7, 10...)
          return (beat - 1) % 3 == 0 ? BeatType.strong : BeatType.weak;
        }
        return beat == 1 ? BeatType.strong : BeatType.weak;

      case AccentPattern.strongMediumWeak:
        if (ts.isCompound) {
          // Compound time: strong on main beats (1, 4, 7, 10...)
          return (beat - 1) % 3 == 0 ? BeatType.strong : BeatType.weak;
        }
        if (beat == 1) return BeatType.strong;
        if (ts == TimeSignature.fourFour && beat == 3) {
          return BeatType.medium;
        }
        return BeatType.weak;
    }
  }

  void _playBeat(BeatType beatType) {
    if (_settings.sound == MetronomeSound.silent || !_soundsLoaded) return;

    final source = switch (beatType) {
      BeatType.strong => _strongSource,
      BeatType.medium => _mediumSource,
      BeatType.weak => _weakSource,
    };

    if (source == null) return;

    // SoLoud.play is non-blocking and handles audio on native thread
    try {
      _soloud.play(source);
    } catch (_) {
      // Silently ignore playback errors
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_isPlaying) {
      // Update subdivision interval in isolate
      _isolateSendPort?.send(_subdivisionIntervalMs);
    }
  }

  @override
  Future<void> incrementBpm(int delta) async {
    await setBpm(_settings.bpm + delta);
  }

  @override
  Future<void> playTapSound() async {
    if (!_initialized) {
      await init();
    }

    // Fire-and-forget: don't await, just trigger playback immediately
    playFirstBeatSync();
  }

  /// Play first beat sound synchronously (no await).
  /// Used for instant feedback when play button is pressed.
  void playFirstBeatSync() {
    if (_strongSource != null) {
      try {
        // Don't await - fire and forget for immediate playback
        _soloud.play(_strongSource!);
      } catch (_) {
        // Silently ignore
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stop();

    // Dispose isolate
    _isolateSendPort?.send('dispose');
    await _tickSubscription?.cancel();
    _receivePort?.close();
    _timingIsolate?.kill(priority: Isolate.immediate);
    _timingIsolate = null;
    _isolateSendPort = null;
    _receivePort = null;
    _isolateReady = false;

    await _disposeSources();
    _initialized = false;
  }
}
