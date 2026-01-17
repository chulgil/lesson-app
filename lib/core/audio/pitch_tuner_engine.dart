// Real pitch detection engine using YIN algorithm
// Uses pitch_detector_dart for pitch detection
// Uses flutter_audio_capture for microphone input

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

import '../../../features/practice/domain/entities/tuner_types.dart';
import 'pitch_detection/stability_filter.dart';
import 'tuner_engine.dart';

/// Configuration for the pitch tuner engine.
class PitchTunerConfig {
  const PitchTunerConfig({
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.minProbability = 0.85,
    this.stabilityFrames = 3,
    this.amplitudeThreshold = 0.05,
  });

  /// Audio sample rate in Hz.
  final int sampleRate;

  /// Buffer size for FFT analysis.
  final int bufferSize;

  /// Minimum probability to accept pitch (0.0-1.0).
  final double minProbability;

  /// Frames required for stable note detection.
  final int stabilityFrames;

  /// Minimum amplitude to detect (noise gate).
  final double amplitudeThreshold;
}

/// Real pitch detection engine using YIN algorithm.
///
/// Features:
/// - Uses flutter_audio_capture for microphone input
/// - Uses pitch_detector_dart (YIN algorithm) for pitch detection
/// - Stability filtering for consistent note display
/// - Amplitude gating for noise rejection
class PitchTunerEngine implements TunerEngine {
  PitchTunerEngine({
    PitchTunerConfig? config,
    double referenceFrequency = 440.0,
  })  : _config = config ?? const PitchTunerConfig(),
        _referenceFrequency = referenceFrequency;

  final PitchTunerConfig _config;

  // Audio capture
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();

  // Pitch detector (YIN algorithm)
  late final PitchDetector _pitchDetector;

  // Filters
  late final StabilityFilter _stabilityFilter;
  late final AmplitudeGate _amplitudeGate;

  // State
  bool _isListening = false;
  bool _isInitialized = false;
  double _referenceFrequency;
  double _sensitivity = 0.5;
  TunerNote? _currentNote;

  // Stream controller
  final StreamController<TunerNote?> _streamController =
      StreamController<TunerNote?>.broadcast();

  @override
  Stream<TunerNote?> get noteStream => _streamController.stream;

  @override
  bool get isListening => _isListening;

  @override
  TunerNote? get currentNote => _currentNote;

  @override
  double get referenceFrequency => _referenceFrequency;

  @override
  set referenceFrequency(double value) {
    _referenceFrequency = value.clamp(400.0, 480.0);
  }

  @override
  double get sensitivity => _sensitivity;

  @override
  set sensitivity(double value) {
    _sensitivity = value.clamp(0.0, 1.0);
    _amplitudeGate = AmplitudeGate(
      threshold: 0.01 + (1 - _sensitivity) * 0.19, // 0.01 ~ 0.2
    );
  }

  @override
  OnPitchDetected? onPitchDetected;

  @override
  OnTunerError? onError;

  @override
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      debugPrint('PitchTunerEngine: Initializing...');

      // Initialize pitch detector
      _pitchDetector = PitchDetector(
        audioSampleRate: _config.sampleRate.toDouble(),
        bufferSize: _config.bufferSize,
      );

      // Initialize filters
      _stabilityFilter = StabilityFilter(
        config: StabilityConfig(
          minProbability: _config.minProbability,
          stabilityFrames: _config.stabilityFrames,
        ),
      );

      _amplitudeGate = AmplitudeGate(
        threshold: _config.amplitudeThreshold,
      );

      _isInitialized = true;
      debugPrint('PitchTunerEngine: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('PitchTunerEngine: Init failed - $e');
      onError?.call('Failed to initialize pitch detector: $e');
      return false;
    }
  }

  @override
  Future<void> start() async {
    if (_isListening) return;
    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    try {
      debugPrint('PitchTunerEngine: Starting audio capture...');

      _isListening = true;
      _stabilityFilter.reset();
      _amplitudeGate.reset();

      await _audioCapture.start(
        _onAudioData,
        _onAudioError,
        sampleRate: _config.sampleRate,
        bufferSize: _config.bufferSize,
      );

      debugPrint('PitchTunerEngine: Audio capture started');
    } catch (e) {
      _isListening = false;
      debugPrint('PitchTunerEngine: Start failed - $e');
      onError?.call('Failed to start audio capture: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_isListening) return;

    try {
      debugPrint('PitchTunerEngine: Stopping audio capture...');

      await _audioCapture.stop();
      _isListening = false;
      _currentNote = null;

      _streamController.add(null);
      onPitchDetected?.call(null);

      debugPrint('PitchTunerEngine: Audio capture stopped');
    } catch (e) {
      debugPrint('PitchTunerEngine: Stop failed - $e');
      onError?.call('Failed to stop audio capture: $e');
    }
  }

  @override
  Future<void> toggle() async {
    if (_isListening) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  void dispose() {
    stop();
    _streamController.close();
  }

  // Keep-warm pattern methods (minimal implementation for PitchTunerEngine)
  @override
  Future<void> warmUp() async {
    await init();
  }

  @override
  void enableProcessing() {
    // No-op - uses standard start/stop
  }

  @override
  void disableProcessing() {
    // No-op - uses standard start/stop
  }

  @override
  bool get isStreamActive => _isListening;

  @override
  bool get isProcessingEnabled => _isListening;

  /// Process incoming audio data.
  Future<void> _onAudioData(dynamic data) async {
    try {
      // Convert to List<double> for pitch detection
      final List<double> samples = _convertToFloatSamples(data);

      if (samples.isEmpty) return;

      // Check amplitude (noise gate)
      final amplitude = _calculateAmplitude(samples);
      if (!_amplitudeGate.check(amplitude)) {
        _emitNote(null);
        return;
      }

      // Detect pitch using YIN algorithm
      final pitchResult = await _pitchDetector.getPitchFromFloatBuffer(samples);

      // Apply stability filter
      final stabilityResult = _stabilityFilter.process(
        frequency: pitchResult.pitch,
        probability: pitchResult.probability,
        pitched: pitchResult.pitched,
      );

      // Only emit if stable
      if (stabilityResult.isStable && stabilityResult.frequency > 0) {
        final note = _frequencyToNote(stabilityResult.frequency);
        if (note != null) {
          _emitNote(note);
        }
      } else if (!stabilityResult.isStable && _currentNote != null) {
        // Keep showing last note briefly (hysteresis)
        // This prevents flickering
      }
    } catch (e) {
      debugPrint('PitchTunerEngine: Audio processing error - $e');
    }
  }

  void _onAudioError(Object error) {
    debugPrint('PitchTunerEngine: Audio error - $error');
    onError?.call('Audio capture error: $error');
  }

  /// Convert raw audio data to float samples.
  List<double> _convertToFloatSamples(dynamic data) {
    if (data is List<double>) {
      return data;
    } else if (data is Float64List) {
      return data.toList();
    } else if (data is Float32List) {
      return data.map((e) => e.toDouble()).toList();
    } else if (data is List<num>) {
      return data.map((e) => e.toDouble()).toList();
    }
    return [];
  }

  /// Calculate RMS amplitude of samples.
  double _calculateAmplitude(List<double> samples) {
    if (samples.isEmpty) return 0;

    double sum = 0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return _sqrt(sum / samples.length);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Convert frequency to TunerNote.
  TunerNote? _frequencyToNote(double frequency) {
    return PitchUtils.frequencyToNote(
      frequency,
      referenceA4: _referenceFrequency,
    );
  }

  void _emitNote(TunerNote? note) {
    _currentNote = note;
    _streamController.add(note);
    onPitchDetected?.call(note);
  }
}
