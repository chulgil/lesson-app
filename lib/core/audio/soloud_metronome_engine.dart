import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
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
    expectedTicks = 0;
    stopwatch = Stopwatch()..start();
    // Send first tick immediately
    mainSendPort.send('tick');
    // Start the timing loop
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
  bool _isPlaying = false;
  bool _initialized = false;
  bool _soundsLoaded = false;
  bool _isolateReady = false;

  @override
  BeatCallback? onBeat;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get currentBeat => _currentBeat;

  @override
  MetronomeSettings get settings => _settings;

  @override
  Future<void> init() async {
    if (_initialized) return;

    final stopwatch = Stopwatch()..start();
    debugPrint('SoLoudMetronomeEngine: init started');

    try {
      // Initialize SoLoud engine
      if (!_soloud.isInitialized) {
        await _soloud.init();
        debugPrint('SoLoudMetronomeEngine: SoLoud initialized at ${stopwatch.elapsedMilliseconds}ms');
      }

      // Initialize timing isolate
      await _initIsolate();
      debugPrint('SoLoudMetronomeEngine: Isolate ready at ${stopwatch.elapsedMilliseconds}ms');

      await _loadSounds();
      debugPrint('SoLoudMetronomeEngine: sounds loaded at ${stopwatch.elapsedMilliseconds}ms');

      _initialized = true;
      debugPrint('SoLoudMetronomeEngine: initialized in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('SoLoudMetronomeEngine: init failed: $e');
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

      debugPrint('SoLoudMetronomeEngine: Loading sounds...');
      debugPrint('  Strong: $strongPath');
      debugPrint('  Medium: $mediumPath');
      debugPrint('  Weak: $weakPath');

      // Load sounds using SoLoud
      _strongSource = await _soloud.loadAsset(strongPath);
      _mediumSource = await _soloud.loadAsset(mediumPath);
      _weakSource = await _soloud.loadAsset(weakPath);

      _soundsLoaded = true;
      debugPrint('SoLoudMetronomeEngine: Sounds loaded successfully');
    } catch (e) {
      debugPrint('SoLoudMetronomeEngine: Failed to load sounds: $e');
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

  @override
  Future<void> start() async {
    if (_isPlaying) return;
    if (!_initialized) {
      await init();
    }

    _isPlaying = true;
    _currentBeat = 0;

    // Send interval to isolate
    _isolateSendPort?.send(_settings.intervalMsPrecise);
    // Start timing in isolate
    _isolateSendPort?.send('start');

    debugPrint('SoLoudMetronomeEngine: Started at ${_settings.bpm} BPM (Isolate timing)');
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentBeat = 0;
    _isolateSendPort?.send('stop');
    debugPrint('SoLoudMetronomeEngine: Stopped');
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

    _currentBeat++;
    if (_currentBeat > _settings.timeSignature.beatsPerMeasure) {
      _currentBeat = 1;
    }

    final beatType = _getBeatType(_currentBeat);
    final isAccent = _currentBeat == 1 &&
        _settings.accentPattern != AccentPattern.uniform;

    // Play sound using SoLoud (fire and forget - native thread handles audio)
    _playBeat(beatType);

    // Notify listeners
    onBeat?.call(_currentBeat, isAccent);
  }

  BeatType _getBeatType(int beat) {
    switch (_settings.accentPattern) {
      case AccentPattern.uniform:
        return BeatType.medium;

      case AccentPattern.firstBeatOnly:
        return beat == 1 ? BeatType.strong : BeatType.weak;

      case AccentPattern.strongMediumWeak:
        if (beat == 1) return BeatType.strong;
        if (_settings.timeSignature == TimeSignature.fourFour && beat == 3) {
          return BeatType.medium;
        }
        if (_settings.timeSignature == TimeSignature.sixEight && beat == 4) {
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
    } catch (e) {
      debugPrint('SoLoudMetronomeEngine: Failed to play beat: $e');
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_isPlaying) {
      // Update interval in isolate
      _isolateSendPort?.send(_settings.intervalMsPrecise);
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

    if (_strongSource != null) {
      try {
        await _soloud.play(_strongSource!);
      } catch (e) {
        debugPrint('SoLoudMetronomeEngine: Failed to play tap sound: $e');
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
    debugPrint('SoLoudMetronomeEngine: Disposed');
  }
}
