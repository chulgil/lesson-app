import 'dart:async';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import '../../features/practice/domain/entities/metronome_settings.dart';
import 'metronome_engine_interface.dart';

/// Timer-based metronome engine with audio playback.
///
/// Uses [AudioPlayer] for sound and [Timer.periodic] for timing.
/// Supports different sounds for strong/medium/weak beats.
class MetronomeEngine implements MetronomeEngineInterface {
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
  bool _initialized = false;

  // Asset paths cached for playback
  String _strongAsset = '';
  String _mediumAsset = '';
  String _weakAsset = '';

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

    await _initAudioPlayers();
    await _loadSoundPaths();

    _initialized = true;
  }

  Future<void> _initAudioPlayers() async {
    // On Android, lowLatency mode has issues - use mediaPlayer instead
    // On iOS, lowLatency works well
    final mode = Platform.isAndroid
        ? PlayerMode.mediaPlayer
        : PlayerMode.lowLatency;

    // Create 2 players per beat type for alternating playback
    for (var i = 0; i < 2; i++) {
      final strong = AudioPlayer();
      final medium = AudioPlayer();
      final weak = AudioPlayer();

      await strong.setPlayerMode(mode);
      await medium.setPlayerMode(mode);
      await weak.setPlayerMode(mode);

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
    } catch (_) {
      // Warm-up failed silently
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
      await _loadSoundPaths();
    }

    if (wasPlaying) {
      await start();
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

    _soundsLoaded = true;

    // Pre-load sounds to reduce first-play latency
    await _warmUpAudio();
  }

  @override
  Future<void> start() async {
    if (_isPlaying) return;
    if (!_initialized) {
      await init();
    }

    // Clean up any lingering state from previous run
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;

    _isPlaying = true;
    _currentBeat = 0;
    _expectedTicks = 0;

    // Play first beat immediately
    _tick();

    // Start stopwatch AFTER first beat for accurate intervals
    _stopwatch = Stopwatch()..start();

    // Use high-frequency timer with drift correction
    _timer = Timer.periodic(
      const Duration(milliseconds: 5),
      (_) => _checkAndTick(),
    );
  }

  /// Check if it's time to tick based on elapsed time (drift-corrected).
  /// Uses precise double interval to avoid cumulative rounding errors.
  void _checkAndTick() {
    if (_stopwatch == null) return;

    final elapsed = _stopwatch!.elapsedMilliseconds;
    final intervalMs = _settings.intervalMsPrecise; // Use precise double interval
    final expectedTime = ((_expectedTicks + 1) * intervalMs).round();

    // If we've reached or passed the expected time, tick
    if (elapsed >= expectedTime) {
      _expectedTicks++;
      _tick();
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
    _currentBeat = 0;
    _expectedTicks = 0;
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

    // On Android, need to stop before each play for reliability
    if (Platform.isAndroid) {
      player.stop().then((_) {
        return player.play(AssetSource(asset));
      }).catchError((_) {});
    } else {
      // On iOS, just play directly (more efficient)
      player.play(AssetSource(asset)).catchError((_) {});
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
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

  @override
  Future<void> incrementBpm(int delta) async {
    await setBpm(_settings.bpm + delta);
  }

  @override
  Future<void> playTapSound() async {
    if (!_initialized) {
      await init();
    }
    // Play a strong beat sound for tap feedback
    _playBeat(BeatType.strong);
  }

  @override
  Future<void> dispose() async {
    await stop();
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
