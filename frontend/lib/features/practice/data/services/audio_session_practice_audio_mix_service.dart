import '../../../../core/audio/audio_session_manager.dart';
import '../../domain/services/practice_audio_mix_service.dart';
import '../../domain/value_objects/audio_mix_mode.dart';

/// Default [PracticeAudioMixService] — switches the global audio session
/// between playback-only and play+record based on the requested
/// [AudioMixMode].
///
/// Mirrors the metronome+recording pattern (see [AudioSessionManager]):
/// recording-capable modes enable `playAndRecord` with `mixWithOthers` +
/// `defaultToSpeaker` so the metronome (and YouTube WebView audio) keep
/// flowing.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.2-§5.3
class AudioSessionPracticeAudioMixService implements PracticeAudioMixService {
  AudioMixMode? _currentMode;

  AudioSessionPracticeAudioMixService();

  @override
  AudioMixMode? get currentMode => _currentMode;

  @override
  Future<void> apply(AudioMixMode mode) async {
    if (_currentMode == mode) return;
    if (AudioMixModePolicy.requiresRecordingPath(mode)) {
      await AudioSessionManager.enableRecordingMode();
    } else {
      await AudioSessionManager.disableRecordingMode();
    }
    _currentMode = mode;
  }

  @override
  Future<void> reset() async {
    await AudioSessionManager.disableRecordingMode();
    _currentMode = null;
  }
}
