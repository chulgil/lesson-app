// Discipline-neutral pace-cue engine interface for the multi-Discipline platform
// (#974, Phase 3 seam, design doc "36-멀티카테고리-Discipline-플랫폼-설계" §3 계층2).
//
// Names the discipline-neutral contract of a rhythmic pace cue: lifecycle
// (init/start/stop/toggle/dispose), play state, the current beat index, and a
// per-beat callback. The music metronome ([MetronomeEngineInterface]) extends this
// with its BPM / time-signature / sound surface; a future fitness Discipline
// (Phase 4, #979) registers its own [PaceCueEngine] (interval / set-rep cue)
// without importing the music metronome. Music is discipline 0 — pure interface
// extraction, no behaviour change.

/// Callback for beat events: [beatNumber] is 1-based, [isAccent] marks a strong beat.
typedef BeatCallback = void Function(int beatNumber, bool isAccent);

/// Discipline-neutral rhythmic pace-cue engine (#974).
///
/// The music metronome implements this via [MetronomeEngineInterface]; other
/// disciplines supply their own pace source. Holds only the neutral lifecycle and
/// beat-callback surface — no BPM/time-signature/sound (those live on the music
/// sub-interface).
abstract class PaceCueEngine {
  /// Whether the pace cue is currently playing.
  bool get isPlaying;

  /// Current beat number (1-based).
  int get currentBeat;

  /// Callback for beat events.
  BeatCallback? onBeat;

  /// Initialize the engine.
  Future<void> init();

  /// Start the pace cue.
  Future<void> start();

  /// Stop the pace cue.
  Future<void> stop();

  /// Toggle play/stop.
  Future<void> toggle();

  /// Dispose resources.
  Future<void> dispose();
}
