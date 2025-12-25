import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../models/metronome_settings.dart';

/// Callback for beat events.
///
/// [beatNumber] is the current beat (1-based, resets each measure).
/// [isAccent] indicates if this is the first beat of a measure.
typedef BeatCallback = void Function(int beatNumber, bool isAccent);

/// Timer-based metronome engine with audio playback.
///
/// Uses [AudioPlayer] for sound and [Timer.periodic] for timing.
/// Supports different sounds for strong/medium/weak beats.
class MetronomeEngine {
  MetronomeEngine();

  // Audio player pool for each beat type (2 players each for overlap)
  final List<AudioPlayer> _strongPlayers = [];
  final List<AudioPlayer> _mediumPlayers = [];
  final List<AudioPlayer> _weakPlayers = [];
  int _strongIndex = 0;
  int _mediumIndex = 0;
  int _weakIndex = 0;

  Timer? _timer;
  Stopwatch? _stopwatch;
  int _expectedTicks = 0;

  MetronomeSettings _settings = const MetronomeSettings();
  int _currentBeat = 0;
  bool _isPlaying = false;
  bool _soundsLoaded = false;

  // Asset paths cached for playback
  String _strongAsset = '';
  String _mediumAsset = '';
  String _weakAsset = '';

  BeatCallback? onBeat;

  /// Whether the metronome is currently playing.
  bool get isPlaying => _isPlaying;

  /// Current beat number (1-based).
  int get currentBeat => _currentBeat;

  /// Current settings.
  MetronomeSettings get settings => _settings;

  /// Initialize and load sounds.
  Future<void> init() async {
    await _initAudioPlayers();
    await _loadSoundPaths();
  }

  Future<void> _initAudioPlayers() async {
    // Create 2 players per beat type for alternating playback
    for (var i = 0; i < 2; i++) {
      final strong = AudioPlayer();
      final medium = AudioPlayer();
      final weak = AudioPlayer();

      await strong.setPlayerMode(PlayerMode.lowLatency);
      await medium.setPlayerMode(PlayerMode.lowLatency);
      await weak.setPlayerMode(PlayerMode.lowLatency);

      _strongPlayers.add(strong);
      _mediumPlayers.add(medium);
      _weakPlayers.add(weak);
    }
  }

  /// Warm up audio players by pre-loading sounds
  Future<void> _warmUpAudio() async {
    if (!_soundsLoaded || _settings.sound == MetronomeSound.silent) return;

    // Pre-load all sound files to reduce first-play latency
    try {
      for (final player in _strongPlayers) {
        await player.setSource(AssetSource(_strongAsset));
      }
      for (final player in _mediumPlayers) {
        await player.setSource(AssetSource(_mediumAsset));
      }
      for (final player in _weakPlayers) {
        await player.setSource(AssetSource(_weakAsset));
      }
      debugPrint('MetronomeEngine: Audio warmed up');
    } catch (e) {
      debugPrint('MetronomeEngine: Warm-up failed: $e');
    }
  }

  /// Update metronome settings.
  ///
  /// If playing, automatically restarts with new settings.
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      stop();
    }

    final soundChanged = _settings.sound != newSettings.sound;
    _settings = newSettings;

    // Reload sounds if sound type changed
    if (soundChanged) {
      await _loadSoundPaths();
    }

    if (wasPlaying) {
      start();
    }
  }

  Future<void> _loadSoundPaths() async {
    if (_settings.sound == MetronomeSound.silent) {
      _soundsLoaded = false;
      return;
    }

    // Get asset paths for each beat type
    final strongPath = _settings.sound.getAssetPath(BeatType.strong);
    final mediumPath = _settings.sound.getAssetPath(BeatType.medium);
    final weakPath = _settings.sound.getAssetPath(BeatType.weak);

    // Remove 'assets/' prefix for AssetSource
    _strongAsset = strongPath.replaceFirst('assets/', '');
    _mediumAsset = mediumPath.replaceFirst('assets/', '');
    _weakAsset = weakPath.replaceFirst('assets/', '');

    debugPrint('MetronomeEngine: Sound paths set...');
    debugPrint('  Strong: $_strongAsset');
    debugPrint('  Medium: $_mediumAsset');
    debugPrint('  Weak: $_weakAsset');

    _soundsLoaded = true;

    // Pre-load sounds to reduce first-play latency
    await _warmUpAudio();
  }

  /// Start the metronome.
  void start() {
    if (_isPlaying) return;

    _isPlaying = true;
    _currentBeat = 0;
    _expectedTicks = 0;

    // Play first beat immediately
    _tick();

    // Start stopwatch AFTER first beat for accurate intervals
    // This ensures beat 2 is exactly intervalMs after beat 1
    _stopwatch = Stopwatch()..start();

    // Use high-frequency timer with drift correction
    // Check every 5ms for more precise timing
    _timer = Timer.periodic(
      const Duration(milliseconds: 5),
      (_) => _checkAndTick(),
    );
  }

  /// Check if it's time to tick based on elapsed time (drift-corrected).
  void _checkAndTick() {
    if (_stopwatch == null) return;

    final elapsed = _stopwatch!.elapsedMilliseconds;
    final intervalMs = _settings.intervalMs;
    final expectedTime = (_expectedTicks + 1) * intervalMs;

    // If we've reached or passed the expected time, tick
    if (elapsed >= expectedTime) {
      _expectedTicks++;
      _tick();
    }
  }

  /// Stop the metronome.
  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
    _currentBeat = 0;
    _expectedTicks = 0;
  }

  /// Toggle play/stop.
  void toggle() {
    if (_isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void _tick() {
    _currentBeat++;
    if (_currentBeat > _settings.timeSignature.beatsPerMeasure) {
      _currentBeat = 1;
    }

    final beatType = _getBeatType(_currentBeat);
    final isAccent = _currentBeat == 1 &&
        _settings.accentPattern != AccentPattern.uniform;

    // Play sound (fire and forget - don't await)
    _playBeat(beatType);

    // Notify listeners
    onBeat?.call(_currentBeat, isAccent);
  }

  /// Determine beat type based on beat number, time signature, and accent pattern.
  BeatType _getBeatType(int beat) {
    switch (_settings.accentPattern) {
      case AccentPattern.uniform:
        // All beats same intensity (medium)
        return BeatType.medium;

      case AccentPattern.firstBeatOnly:
        // First beat strong, rest weak
        return beat == 1 ? BeatType.strong : BeatType.weak;

      case AccentPattern.strongMediumWeak:
        // Original pattern: strong-medium-weak
        if (beat == 1) return BeatType.strong;

        // For 4/4, beat 3 is medium
        if (_settings.timeSignature == TimeSignature.fourFour && beat == 3) {
          return BeatType.medium;
        }

        // For 6/8, beat 4 is medium (second group starts)
        if (_settings.timeSignature == TimeSignature.sixEight && beat == 4) {
          return BeatType.medium;
        }

        return BeatType.weak;
    }
  }

  void _playBeat(BeatType beatType) {
    if (_settings.sound == MetronomeSound.silent || !_soundsLoaded) return;

    // Get player and asset based on beat type, using round-robin for overlap
    final (player, asset) = switch (beatType) {
      BeatType.strong => (
          _strongPlayers[_strongIndex++ % _strongPlayers.length],
          _strongAsset
        ),
      BeatType.medium => (
          _mediumPlayers[_mediumIndex++ % _mediumPlayers.length],
          _mediumAsset
        ),
      BeatType.weak => (
          _weakPlayers[_weakIndex++ % _weakPlayers.length],
          _weakAsset
        ),
    };

    // Play the sound (fire and forget)
    player.play(AssetSource(asset)).catchError((e) {
      debugPrint('MetronomeEngine: Failed to play beat: $e');
    });
  }

  /// Set BPM while playing (for real-time adjustment).
  void setBpm(int bpm) {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_isPlaying) {
      // Reset timing for new BPM
      _expectedTicks = 0;
      _stopwatch?.reset();
      _stopwatch?.start();
    }
  }

  /// Increment BPM by given amount.
  void incrementBpm(int delta) {
    setBpm(_settings.bpm + delta);
  }

  /// Dispose resources.
  Future<void> dispose() async {
    stop();
    for (final player in _strongPlayers) {
      await player.dispose();
    }
    for (final player in _mediumPlayers) {
      await player.dispose();
    }
    for (final player in _weakPlayers) {
      await player.dispose();
    }
    _strongPlayers.clear();
    _mediumPlayers.clear();
    _weakPlayers.clear();
  }
}
