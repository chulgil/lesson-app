import '../value_objects/audio_mix_mode.dart';

/// Translates [AudioMixMode] into audio-session + player-volume side effects.
///
/// The default implementation lives in `data/services/` and uses
/// [AudioSessionManager.enableRecordingMode] + YouTube player volume control.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.2-§5.3
abstract class PracticeAudioMixService {
  /// Applies the given [mode]. Must be idempotent.
  ///
  /// Concrete implementations may:
  /// - call [AudioSessionManager.enableRecordingMode] for `*recording*` modes
  /// - mute the YouTube player for `videoMuted`
  /// - keep the session in playback-only mode for `videoOnly`
  Future<void> apply(AudioMixMode mode);

  /// Last applied mode (null = never applied).
  AudioMixMode? get currentMode;

  /// Tear down (e.g. when leaving the practice flow).
  Future<void> reset();
}

/// Pure helper — translates a mode into recommended user feedback.
class AudioMixModePolicy {
  AudioMixModePolicy._();

  /// True if this mode mixes video sound into the mic path (best effort).
  static bool requiresRecordingPath(AudioMixMode mode) {
    switch (mode) {
      case AudioMixMode.videoOnly:
        return false;
      case AudioMixMode.recordOnly:
      case AudioMixMode.mixed:
      case AudioMixMode.videoMuted:
      case AudioMixMode.headphoneOnly:
      case AudioMixMode.metronomeMixed:
        return true;
    }
  }

  /// True if the user should be encouraged to plug in headphones for this mode.
  static bool recommendsHeadphones(AudioMixMode mode) {
    switch (mode) {
      case AudioMixMode.videoOnly:
      case AudioMixMode.recordOnly:
      case AudioMixMode.videoMuted:
        return false;
      case AudioMixMode.mixed:
      case AudioMixMode.headphoneOnly:
      case AudioMixMode.metronomeMixed:
        return true;
    }
  }

  /// True if the YouTube player should be muted (volume 0) in this mode.
  static bool videoShouldBeMuted(AudioMixMode mode) =>
      mode == AudioMixMode.videoMuted;

  /// True if the YouTube player should be paused entirely in this mode.
  static bool videoShouldBePaused(AudioMixMode mode) =>
      mode == AudioMixMode.recordOnly;
}
