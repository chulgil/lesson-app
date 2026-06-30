// Tuner engine interface
// Abstract interface for pitch detection engines

import 'package:lessonaza/features/practice/domain/entities/tuner_types.dart';

import 'signal_gauge_tool.dart';

/// Callback type for pitch detection events.
typedef OnPitchDetected = void Function(TunerNote? note);

/// Callback type for tuner error events.
typedef OnTunerError = void Function(String message);

/// Abstract interface for tuner engines — the music (discipline 0)
/// [SignalGaugeTool].
///
/// Extends the discipline-neutral signal-gauge contract (active state +
/// start/stop/toggle/dispose lifecycle) with the tuner's pitch surface:
/// note stream, current note, reference frequency, sensitivity and the
/// microphone keep-warm controls (#978). A future fitness/language gauge
/// registers its own [SignalGaugeTool] without importing this interface.
///
/// Implementations can use different pitch detection algorithms:
/// - FFT-based (Fast Fourier Transform)
/// - Autocorrelation
/// - YIN algorithm
/// - McLeod Pitch Method
abstract class TunerEngine extends SignalGaugeTool {
  /// Stream of detected notes.
  ///
  /// Emits null when no clear pitch is detected.
  /// Emits a [TunerNote] when a pitch is detected.
  Stream<TunerNote?> get noteStream;

  /// Current detected note (null if none).
  TunerNote? get currentNote;

  /// Reference frequency for A4 (default 440Hz).
  double get referenceFrequency;

  /// Set the reference frequency for A4.
  set referenceFrequency(double value);

  /// Sensitivity threshold for pitch detection (0.0 - 1.0).
  ///
  /// Lower values detect quieter sounds but may be less accurate.
  /// Higher values require louder sounds but are more accurate.
  double get sensitivity;

  /// Set the sensitivity threshold.
  set sensitivity(double value);

  /// Initialize the engine and request microphone permissions.
  ///
  /// Returns true if initialization was successful.
  /// Returns false if microphone permission was denied.
  Future<bool> init();

  /// Warm up the engine by starting the audio stream without processing.
  ///
  /// This pre-configures the audio session and starts the microphone,
  /// so that enabling processing later is instantaneous.
  /// Override in implementations that support keep-warm pattern.
  Future<void> warmUp() async {
    // Default: just initialize
    await init();
  }

  /// Enable pitch processing (stream must be active).
  ///
  /// Call after [warmUp] for instant tuner activation.
  void enableProcessing() {
    // Default: no-op, override in implementations
  }

  /// Disable pitch processing but keep the stream active.
  ///
  /// This allows instant re-enabling without audio session reconfiguration.
  void disableProcessing() {
    // Default: no-op, override in implementations
  }

  /// Stop audio completely for background transition.
  ///
  /// Unlike [stop], this always stops regardless of current [isListening] state.
  /// Use when the app goes to background to ensure the mic is fully off.
  Future<void> stopForBackground() async {
    await stop();
  }

  /// Whether the audio stream is active (warmed up or started).
  bool get isStreamActive => isListening;

  /// Whether pitch processing is enabled.
  bool get isProcessingEnabled => isListening;

  /// Callback for pitch detection events.
  OnPitchDetected? onPitchDetected;

  /// Callback for error events.
  OnTunerError? onError;
}

/// Configuration for tuner engine.
class TunerEngineConfig {
  const TunerEngineConfig({
    this.sampleRate = 44100,
    this.bufferSize = 4096,
    this.referenceFrequency = 440.0,
    this.sensitivity = 0.5,
    this.minFrequency = 27.5, // A0
    this.maxFrequency = 4186.0, // C8
  });

  /// Audio sample rate in Hz.
  final int sampleRate;

  /// FFT buffer size (must be power of 2).
  final int bufferSize;

  /// Reference frequency for A4.
  final double referenceFrequency;

  /// Sensitivity threshold (0.0 - 1.0).
  final double sensitivity;

  /// Minimum detectable frequency in Hz.
  final double minFrequency;

  /// Maximum detectable frequency in Hz.
  final double maxFrequency;

  /// Create a copy with modified values.
  TunerEngineConfig copyWith({
    int? sampleRate,
    int? bufferSize,
    double? referenceFrequency,
    double? sensitivity,
    double? minFrequency,
    double? maxFrequency,
  }) {
    return TunerEngineConfig(
      sampleRate: sampleRate ?? this.sampleRate,
      bufferSize: bufferSize ?? this.bufferSize,
      referenceFrequency: referenceFrequency ?? this.referenceFrequency,
      sensitivity: sensitivity ?? this.sensitivity,
      minFrequency: minFrequency ?? this.minFrequency,
      maxFrequency: maxFrequency ?? this.maxFrequency,
    );
  }
}

/// Pitch detection result from the engine.
class PitchDetectionResult {
  const PitchDetectionResult({
    required this.frequency,
    required this.confidence,
    required this.amplitude,
  });

  /// Detected frequency in Hz.
  final double frequency;

  /// Confidence level of the detection (0.0 - 1.0).
  final double confidence;

  /// Amplitude level of the audio (0.0 - 1.0).
  final double amplitude;

  /// Whether this is a valid detection.
  bool get isValid => frequency > 0 && confidence > 0.5;

  @override
  String toString() =>
      'PitchDetectionResult(${frequency.toStringAsFixed(1)}Hz, '
      'conf=${confidence.toStringAsFixed(2)}, '
      'amp=${amplitude.toStringAsFixed(2)})';
}
