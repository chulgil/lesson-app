import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_trimmer_service.dart';

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
/// Supports segment-based playback for middle silence skip.
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

  /// Current position in the audio file.
  Duration _position = Duration.zero;
  Duration get position => _position;

  /// Total duration.
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  /// Progress as 0-1 value (based on effective playable content).
  double get progress {
    final effDur = effectiveDuration;
    if (effDur.inMilliseconds == 0) return 0;
    return (effectivePosition.inMilliseconds / effDur.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Currently loaded file path.
  String? _currentPath;
  String? get currentPath => _currentPath;

  /// Trim metadata for current file.
  TrimMetadata? _trimMetadata;

  /// Current segment index for multi-segment playback.
  int _currentSegmentIndex = 0;

  /// Whether we're in the middle of a segment transition.
  bool _isTransitioning = false;

  /// Content start position (after trim).
  Duration get contentStart => _trimMetadata?.contentStart ?? Duration.zero;

  /// Content end position (after trim).
  Duration get contentEnd => _trimMetadata?.contentEnd ?? _duration;

  /// Effective duration (accounting for trimming and segment skips).
  Duration get effectiveDuration =>
      _trimMetadata?.effectivePlayDuration ?? _duration;

  /// Whether playback has multiple segments.
  bool get hasSegments =>
      _trimMetadata != null && _trimMetadata!.hasMiddleSilenceSkip;

  /// Current segments for playback.
  List<PlayableSegment> get _segments =>
      _trimMetadata?.segments ?? const [];

  /// Effective position (relative to playable content, excluding skipped sections).
  Duration get effectivePosition {
    if (!hasSegments) {
      // No segments, use simple calculation
      return _position - contentStart;
    }

    // Calculate effective position across segments
    Duration effectivePos = Duration.zero;
    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      if (i < _currentSegmentIndex) {
        // Add full duration of previous segments
        effectivePos += seg.duration;
      } else if (i == _currentSegmentIndex) {
        // Add partial duration of current segment
        if (_position >= seg.start && _position <= seg.end) {
          effectivePos += _position - seg.start;
        }
        break;
      }
    }
    return effectivePos;
  }

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

      // Skip position checks during segment transition
      if (_isTransitioning) return;

      // Handle segment-based playback
      if (hasSegments && _state == PlaybackState.playing) {
        _handleSegmentPlayback(pos);
        return;
      }

      // Note: Trim end check is handled by recording_player_sheet.dart
      // which adjusts for actual file duration vs metadata duration
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

  /// Handle segment-based playback transitions.
  void _handleSegmentPlayback(Duration pos) {
    if (_segments.isEmpty || _currentSegmentIndex >= _segments.length) {
      return;
    }

    final currentSegment = _segments[_currentSegmentIndex];

    // Check if we've reached the end of current segment
    if (pos >= currentSegment.end) {
      final nextIndex = _currentSegmentIndex + 1;

      if (nextIndex >= _segments.length) {
        // No more segments, playback complete
        debugPrint('AudioPlayer: All segments completed');
        stop();
        onComplete?.call();
        return;
      }

      // Transition to next segment
      _transitionToSegment(nextIndex);
    }
  }

  /// Transition to a specific segment (seamless seek).
  Future<void> _transitionToSegment(int segmentIndex) async {
    if (segmentIndex >= _segments.length) return;

    _isTransitioning = true;
    _currentSegmentIndex = segmentIndex;
    final segment = _segments[segmentIndex];

    debugPrint('AudioPlayer: Transitioning to segment $segmentIndex '
        '(${segment.start} ~ ${segment.end})');

    await _player.seek(segment.start);
    _isTransitioning = false;
  }

  /// Find segment index for a given position.
  int _findSegmentForPosition(Duration pos) {
    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      if (pos >= seg.start && pos < seg.end) {
        return i;
      }
      // Position is in a gap (skipped silence), use next segment
      if (i < _segments.length - 1) {
        final nextSeg = _segments[i + 1];
        if (pos >= seg.end && pos < nextSeg.start) {
          return i + 1;
        }
      }
    }
    return 0;
  }

  /// Load an audio file for playback.
  Future<bool> load(String filePath) async {
    try {
      _currentPath = filePath;
      _currentSegmentIndex = 0;

      // Load trim metadata if exists
      _trimMetadata = await AudioTrimmerService.instance.readTrimMetadata(filePath);
      if (_trimMetadata != null && _trimMetadata!.hasTrimming) {
        debugPrint('AudioPlayer: Loaded with trim - start: ${_trimMetadata!.contentStart}, end: ${_trimMetadata!.contentEnd}');
        if (_trimMetadata!.hasMiddleSilenceSkip) {
          debugPrint('AudioPlayer: Has ${_segments.length} segments for middle silence skip');
          for (int i = 0; i < _segments.length; i++) {
            final seg = _segments[i];
            debugPrint('  Segment $i: ${seg.start} ~ ${seg.end} (${seg.duration})');
          }
        }
      }

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

      // Handle segment-based playback
      if (hasSegments && _segments.isNotEmpty) {
        _currentSegmentIndex = 0;
        final firstSegment = _segments[0];
        await _player.seek(firstSegment.start);
        debugPrint('AudioPlayer: Seeked to first segment start: ${firstSegment.start}');
      }
      // Seek to content start if trimmed (non-segment playback)
      else if (_trimMetadata != null && _trimMetadata!.contentStart > Duration.zero) {
        await _player.seek(_trimMetadata!.contentStart);
        debugPrint('AudioPlayer: Seeked to trim start: ${_trimMetadata!.contentStart}');
      }

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
      _currentSegmentIndex = 0;
      debugPrint('AudioPlayer: Stopped');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to stop: $e');
    }
  }

  /// Seek to a position.
  Future<void> seek(Duration position) async {
    try {
      // Update segment index for segment-based playback
      if (hasSegments) {
        _currentSegmentIndex = _findSegmentForPosition(position);
      }
      await _player.seek(position);
      debugPrint('AudioPlayer: Seeked to $position');
    } catch (e) {
      debugPrint('AudioPlayer: Failed to seek: $e');
    }
  }

  /// Seek to an effective position (relative to playable content).
  Future<void> seekToEffectivePosition(Duration effectivePos) async {
    if (!hasSegments) {
      // Simple case: just add content start offset
      await seek(contentStart + effectivePos);
      return;
    }

    // Convert effective position to actual position
    Duration accumulated = Duration.zero;
    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      if (accumulated + seg.duration > effectivePos) {
        // Target is in this segment
        final offsetInSegment = effectivePos - accumulated;
        final actualPos = seg.start + offsetInSegment;
        _currentSegmentIndex = i;
        await _player.seek(actualPos);
        debugPrint('AudioPlayer: Seeked to effective $effectivePos -> actual $actualPos (segment $i)');
        return;
      }
      accumulated += seg.duration;
    }

    // Past end, seek to last segment end
    if (_segments.isNotEmpty) {
      final lastSeg = _segments.last;
      _currentSegmentIndex = _segments.length - 1;
      await _player.seek(lastSeg.end);
    }
  }

  /// Seek by a relative amount (based on effective position).
  Future<void> seekRelative(Duration delta) async {
    if (hasSegments) {
      // For segment-based playback, use effective position
      final newEffective = effectivePosition + delta;
      final clampedEffective = Duration(
        milliseconds: newEffective.inMilliseconds.clamp(0, effectiveDuration.inMilliseconds),
      );
      await seekToEffectivePosition(clampedEffective);
    } else {
      // Simple case
      final newPosition = _position + delta;
      final clampedPosition = Duration(
        milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
      );
      await seek(clampedPosition);
    }
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
