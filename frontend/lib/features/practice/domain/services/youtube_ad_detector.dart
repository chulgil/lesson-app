/// Heuristic ad detection for the YouTube iframe player.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §3.5 #509
///
/// The YouTube iframe API does not expose an explicit ad event to the
/// `youtube_player_iframe` package — see the package's [PlayerState] enum
/// (unknown, unStarted, ended, playing, paused, buffering, cued). The official
/// IFrame Player API also does not surface a stable ad-playback event.
/// Detection is therefore **best effort**: we infer ad playback from the
/// shape of the position stream while the player is in the `playing` state.
///
/// Heuristic — when the player is `playing`:
///  1. The reported position resets to ~0 mid-session (ads inject their own
///     timeline that starts at 0).
///  2. The position stays at ~0 for several consecutive samples while the
///     player remains `playing` (a real video resumes the prior position).
///  3. The position jumps backward by more than [_kAdJumpBackThresholdSec]
///     seconds without an explicit seek (= mid-roll ad).
///
/// All three signals must be observed during a `playing` window — ad
/// detection is conservative because false positives stop the loop counter.
///
/// No I/O, no Flutter dependency. Tested in isolation.
class YoutubeAdDetector {
  /// Position (in seconds) below which we consider the playhead "at zero".
  static const double _kZeroPositionThresholdSec = 0.5;

  /// Number of consecutive `playing` samples at zero before declaring an ad.
  static const int _kConsecutiveZeroSamples = 2;

  /// Backward jump in seconds (without explicit seek) that signals an ad.
  static const double _kAdJumpBackThresholdSec = 3.0;

  /// Forward jump threshold in seconds — ignore harmless small drifts.
  static const double _kForwardJumpToleranceSec = 5.0;

  double? _lastPosition;
  int _zeroSampleCount = 0;
  bool _isAdPlaying = false;

  /// Whether the most recent samples suggest an ad is currently playing.
  bool get isAdPlaying => _isAdPlaying;

  /// Notify the detector that the user explicitly seeked — resets the
  /// backward-jump signal so the seek itself is not classified as an ad.
  void onExplicitSeek() {
    _lastPosition = null;
    _zeroSampleCount = 0;
  }

  /// Notify the detector that the player paused, stopped, or the user
  /// manually resumed playback after an ad — clears the ad flag.
  void onResumeOrPause() {
    _isAdPlaying = false;
    _lastPosition = null;
    _zeroSampleCount = 0;
  }

  /// Feed a new position sample. [isPlaying] is whether the player is in the
  /// `playing` state. Returns the updated [isAdPlaying] flag.
  bool observe({required double positionSeconds, required bool isPlaying}) {
    if (!isPlaying) {
      // Outside the playing window, the heuristic cannot decide.
      _lastPosition = positionSeconds;
      _zeroSampleCount = 0;
      return _isAdPlaying;
    }

    // (1) Position reset to ~0 while playing → start of ad window.
    if (positionSeconds < _kZeroPositionThresholdSec) {
      _zeroSampleCount += 1;
      if (_zeroSampleCount >= _kConsecutiveZeroSamples) {
        _isAdPlaying = true;
      }
    } else {
      _zeroSampleCount = 0;
    }

    // (2) Mid-roll: position jumped backward significantly (without seek).
    final prev = _lastPosition;
    if (prev != null) {
      final delta = positionSeconds - prev;
      if (delta < -_kAdJumpBackThresholdSec) {
        _isAdPlaying = true;
      } else if (delta > _kForwardJumpToleranceSec) {
        // Large forward jump — likely the original video resumed after an ad.
        _isAdPlaying = false;
        _zeroSampleCount = 0;
      }
    }

    _lastPosition = positionSeconds;
    return _isAdPlaying;
  }
}
