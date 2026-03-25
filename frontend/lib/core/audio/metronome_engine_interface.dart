import '../../features/practice/domain/entities/metronome_settings.dart';

/// Callback for beat events.
typedef BeatCallback = void Function(int beatNumber, bool isAccent);

/// Abstract interface for metronome engines.
///
/// Implemented by both [MetronomeEngine] (Flutter/Timer-based) and
/// [NativeMetronomeEngine] (Platform-specific AudioTrack/AVAudioEngine).
abstract class MetronomeEngineInterface {
  /// Whether the metronome is currently playing.
  bool get isPlaying;

  /// Current beat number (1-based).
  int get currentBeat;

  /// Current settings.
  MetronomeSettings get settings;

  /// Callback for beat events.
  BeatCallback? onBeat;

  /// Initialize the engine.
  Future<void> init();

  /// Update settings.
  Future<void> updateSettings(MetronomeSettings newSettings);

  /// Start the metronome.
  Future<void> start();

  /// Stop the metronome.
  Future<void> stop();

  /// Toggle play/stop.
  Future<void> toggle();

  /// Set BPM.
  Future<void> setBpm(int bpm);

  /// Increment BPM.
  Future<void> incrementBpm(int delta);

  /// Play a single tap sound (for tap tempo feedback).
  Future<void> playTapSound();

  /// Dispose resources.
  Future<void> dispose();
}
