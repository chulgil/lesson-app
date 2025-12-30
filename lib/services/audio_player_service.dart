import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// State of audio playback.
enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Service for audio playback functionality.
///
/// Uses audioplayers package for cross-platform audio playback.
class AudioPlayerService {
  AudioPlayerService();

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  /// Current playback state.
  PlaybackState _state = PlaybackState.idle;
  PlaybackState get state => _state;

  /// Whether currently playing.
  bool get isPlaying => _state == PlaybackState.playing;

  /// Whether paused.
  bool get isPaused => _state == PlaybackState.paused;

  /// Whether idle or completed.
  bool get isStopped =>
      _state == PlaybackState.idle || _state == PlaybackState.completed;

  /// Current position.
  Duration _position = Duration.zero;
  Duration get position => _position;

  /// Total duration.
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  /// Progress as 0-1 value.
  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Currently loaded file path.
  String? _currentPath;
  String? get currentPath => _currentPath;

  /// Callback when playback completes.
  VoidCallback? onComplete;

  /// Stream of position changes.
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// Stream of playback state changes.
  Stream<PlaybackState> get stateStream =>
      _player.onPlayerStateChanged.map(_mapPlayerState);

  /// Initialize the player service.
  Future<void> init() async {
    _playerStateSubscription = _player.onPlayerStateChanged.listen((playerState) {
      _state = _mapPlayerState(playerState);
      debugPrint('AudioPlayer: State changed to $_state');

      if (_state == PlaybackState.completed) {
        onComplete?.call();
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      _position = pos;
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      _duration = dur;
    });
  }

  PlaybackState _mapPlayerState(PlayerState playerState) {
    switch (playerState) {
      case PlayerState.playing:
        return PlaybackState.playing;
      case PlayerState.paused:
        return PlaybackState.paused;
      case PlayerState.stopped:
        return PlaybackState.idle;
      case PlayerState.completed:
        return PlaybackState.completed;
      case PlayerState.disposed:
        return PlaybackState.idle;
    }
  }

  /// Load an audio file for playback.
  Future<bool> load(String filePath) async {
    try {
      _currentPath = filePath;
      debugPrint('AudioPlayer: Loading $filePath');
      return true;
    } catch (e) {
      debugPrint('AudioPlayer: Failed to load $filePath: $e');
      _state = PlaybackState.error;
      return false;
    }
  }

  /// Play the loaded audio.
  Future<void> play() async {
    try {
      if (_currentPath == null) {
        debugPrint('AudioPlayer: No file loaded');
        return;
      }
      // Use UrlSource with file:// protocol for iOS compatibility
      final fileUrl = 'file://$_currentPath';
      await _player.play(UrlSource(fileUrl));
      debugPrint('AudioPlayer: Playing $fileUrl');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to play: $e');
    }
  }

  /// Pause playback.
  Future<void> pause() async {
    try {
      await _player.pause();
      debugPrint('AudioPlayer: Paused');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to pause: $e');
    }
  }

  /// Stop playback and reset position.
  Future<void> stop() async {
    try {
      await _player.stop();
      _position = Duration.zero;
      debugPrint('AudioPlayer: Stopped');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to stop: $e');
    }
  }

  /// Seek to a position.
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      debugPrint('AudioPlayer: Seeked to $position');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to seek: $e');
    }
  }

  /// Seek by a relative amount.
  Future<void> seekRelative(Duration delta) async {
    final newPosition = _position + delta;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await seek(clampedPosition);
  }

  /// Skip forward by seconds.
  Future<void> skipForward([int seconds = 10]) async {
    await seekRelative(Duration(seconds: seconds));
  }

  /// Skip backward by seconds.
  Future<void> skipBackward([int seconds = 10]) async {
    await seekRelative(Duration(seconds: -seconds));
  }

  /// Set playback speed.
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setPlaybackRate(speed.clamp(0.5, 2.0));
      debugPrint('AudioPlayer: Speed set to $speed');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to set speed: $e');
    }
  }

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('AudioPlayer: Volume set to $volume');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to set volume: $e');
    }
  }

  /// Toggle play/pause.
  Future<void> toggle() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Format duration as mm:ss.
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _player.dispose();
    debugPrint('AudioPlayer: Disposed');
  }
}
