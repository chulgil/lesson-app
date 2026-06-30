// Discipline-neutral signal-gauge tool interface for the multi-Discipline
// platform (#978, Phase 4 seam, design doc "36-멀티카테고리-Discipline-플랫폼-설계" §3 계층2).
//
// Names the discipline-neutral contract of a signal gauge: the active reading
// state and the start/stop/toggle/dispose lifecycle. The music tuner
// ([TunerEngine]) extends this with its pitch/note/cent/judgement surface
// (noteStream, currentNote, referenceFrequency, ...); a future fitness
// form-gauge or heart-rate-zone gauge (Phase 4+) registers its own
// [SignalGaugeTool] without importing the tuner. Music is discipline 0 — pure
// supertype extraction, no behaviour change.

/// Discipline-neutral signal-gauge tool (#978).
///
/// A tool that reads an input signal against a target. The music tuner
/// implements this via [TunerEngine] (microphone → frequency → cents →
/// judgement); other disciplines supply their own gauge (camera form alignment,
/// heart-rate zone). Holds only the neutral active-state + lifecycle surface —
/// the signal type, target and judgement live on each discipline's
/// sub-interface. [isListening] names the active reading state from the tuner
/// origin; a generic gauge is "listening" to its input signal while reading.
abstract class SignalGaugeTool {
  /// Whether the gauge is currently active (reading its input signal).
  bool get isListening;

  /// Start reading the input signal.
  Future<void> start();

  /// Stop reading the input signal.
  Future<void> stop();

  /// Toggle between reading and stopped.
  Future<void> toggle() async {
    if (isListening) {
      await stop();
    } else {
      await start();
    }
  }

  /// Dispose resources.
  void dispose();
}
