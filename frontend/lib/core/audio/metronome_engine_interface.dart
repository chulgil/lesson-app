import '../../features/practice/domain/entities/metronome_settings.dart';
import 'pace_cue_engine.dart';

// Re-export so existing importers of this file keep seeing [BeatCallback]
// (it moved to pace_cue_engine.dart as a discipline-neutral concept, #974).
export 'pace_cue_engine.dart' show BeatCallback;

/// Music (discipline 0) metronome engine — the music [PaceCueEngine].
///
/// Extends the discipline-neutral pace contract (lifecycle + beat callback) with
/// the metronome's BPM / time-signature / sound surface (#974). Implemented by
/// [NativeMetronomeEngine] (platform-specific AudioTrack/AVAudioEngine) and
/// [SoLoudMetronomeEngine] (macOS).
abstract class MetronomeEngineInterface extends PaceCueEngine {
  /// Current settings.
  MetronomeSettings get settings;

  /// Update settings.
  Future<void> updateSettings(MetronomeSettings newSettings);

  /// Set BPM.
  Future<void> setBpm(int bpm);

  /// Increment BPM.
  Future<void> incrementBpm(int delta);

  /// Play a single tap sound (for tap tempo feedback).
  Future<void> playTapSound();
}
