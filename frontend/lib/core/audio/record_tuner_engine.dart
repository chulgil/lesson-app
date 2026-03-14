// Record-based tuner engine
// Uses the record package for audio input (supports all platforms)
// Uses pitch_detector_dart (YIN algorithm) for pitch detection

import 'dart:async';
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import 'package:lessonaza/features/practice/domain/entities/tuner_types.dart';

import 'pitch_detection/stability_filter.dart';
import 'tuner_engine.dart';

/// Configuration for the record tuner engine.
class RecordTunerConfig {
  const RecordTunerConfig({
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.minProbability = 0.70, // Lowered for better high-frequency detection
    this.stabilityFrames = 2, // Reduced for faster response
    this.amplitudeThreshold = 0.01, // Very sensitive for quiet sounds
  });

  final int sampleRate;
  final int bufferSize;
  final double minProbability;
  final int stabilityFrames;
  final double amplitudeThreshold;
}

/// Tuner engine using the record package for audio input.
///
/// This engine uses the device microphone to detect pitch in real-time.
/// Uses YIN algorithm via pitch_detector_dart for accurate pitch detection.
/// Works on all platforms (iOS, Android, macOS, Windows, Linux).
class RecordTunerEngine implements TunerEngine {
  RecordTunerEngine({
    RecordTunerConfig? config,
    double referenceFrequency = 440.0,
  })  : _config = config ?? const RecordTunerConfig(),
        _referenceFrequency = referenceFrequency;

  final RecordTunerConfig _config;
  final AudioRecorder _recorder = AudioRecorder();
  final _streamController = StreamController<TunerNote?>.broadcast();

  StreamSubscription<Uint8List>? _audioSubscription;

  // Pitch detector (YIN algorithm)
  late PitchDetector _pitchDetector;

  // Filters
  late StabilityFilter _stabilityFilter;
  late AmplitudeGate _amplitudeGate;

  bool _isListening = false;
  bool _isInitialized = false;
  bool _isProcessingEnabled = false; // Whether to process pitch data
  bool _isStreamActive = false; // Whether recorder stream is active
  bool _isRestarting = false; // Prevent concurrent restart attempts
  TunerNote? _currentNote;
  double _referenceFrequency;
  double _sensitivity = 0.5;

  // Heartbeat: track when last audio data arrived to detect dead streams
  DateTime? _lastDataTime;
  static const _streamDeadThreshold = Duration(seconds: 2);

  // Buffer for accumulating audio samples
  final List<double> _sampleBuffer = [];


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
      // Check microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        onError?.call('Microphone permission denied');
        return false;
      }

      // Initialize pitch detector (YIN algorithm)
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
      return true;
    } catch (e) {
      onError?.call('Failed to initialize: $e');
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
      _isListening = true;
      _isProcessingEnabled = true;
      _stabilityFilter.reset();
      _amplitudeGate.reset();
      _sampleBuffer.clear();

      // Start stream if not already active
      if (!_isStreamActive) {
        await _startStream();
      }
    } catch (e) {
      _isListening = false;
      _isProcessingEnabled = false;
      onError?.call('Failed to start audio capture: $e');
    }
  }

  /// Start the recorder stream (internal helper).
  Future<void> _startStream() async {
    if (_isStreamActive) return;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
        // Prevent record package from overriding our audio session config
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );

    _lastDataTime = DateTime.now();
    _audioSubscription = stream.listen(
      _onAudioData,
      onError: _onAudioError,
    );

    _isStreamActive = true;
  }

  /// Restart the recorder stream (e.g., after app resume when iOS killed AVAudioEngine).
  Future<void> restartStream() async {
    if (_isRestarting) return;
    _isRestarting = true;

    try {
      // Force stop the dead stream
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      try {
        await _recorder.stop();
      } catch (_) {
        // Recorder may already be stopped
      }
      _isStreamActive = false;
      _sampleBuffer.clear();

      // Start a fresh stream
      await _startStream();
    } catch (e) {
      onError?.call('Failed to restart stream: $e');
    } finally {
      _isRestarting = false;
    }
  }

  /// Check if the stream appears to be dead (no data received recently).
  bool get isStreamDead {
    if (!_isStreamActive) return true;
    if (_lastDataTime == null) return true;
    return DateTime.now().difference(_lastDataTime!) > _streamDeadThreshold;
  }

  /// Stop the recorder stream (internal helper).
  Future<void> _stopStream() async {
    if (!_isStreamActive) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();

    _isStreamActive = false;
  }

  @override
  Future<void> stop() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _isProcessingEnabled = false;

      // Actually stop the stream
      await _stopStream();

      _currentNote = null;
      _sampleBuffer.clear();

      _streamController.add(null);
    } catch (e) {
      onError?.call('Failed to stop audio capture: $e');
    }
  }

  @override
  Future<void> stopForBackground() async {
    try {
      _isListening = false;
      _isProcessingEnabled = false;

      await _stopStream();

      _currentNote = null;
      _sampleBuffer.clear();

      _streamController.add(null);
    } catch (e) {
      onError?.call('Failed to stop for background: $e');
    }
  }

  /// Warm up the engine by starting the recorder stream without processing.
  ///
  /// This pre-configures the audio session and starts the microphone,
  /// so that enabling processing later is instantaneous and doesn't
  /// block the main thread or interrupt other audio.
  @override
  Future<void> warmUp() async {
    if (_isStreamActive) {
      return;
    }

    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    try {
      _isProcessingEnabled = false;
      _stabilityFilter.reset();
      _amplitudeGate.reset();
      _sampleBuffer.clear();

      await _startStream();
    } catch (e) {
      onError?.call('Failed to warm up: $e');
    }
  }

  /// Enable pitch processing (stream must be active from warmUp or start).
  ///
  /// If the stream is dead (e.g., after app resume), restarts it first.
  @override
  void enableProcessing() {
    if (!_isStreamActive) {
      return;
    }

    _isListening = true;
    _isProcessingEnabled = true;
    _stabilityFilter.reset();
    _amplitudeGate.reset();
    _sampleBuffer.clear();
  }

  /// Disable pitch processing but keep the stream active.
  ///
  /// This allows instant re-enabling without audio session reconfiguration.
  @override
  void disableProcessing() {
    _isListening = false;
    _isProcessingEnabled = false;
    _currentNote = null;
    _sampleBuffer.clear();

    _streamController.add(null);
  }

  /// Check if the stream is active (warmed up or started).
  @override
  bool get isStreamActive => _isStreamActive;

  /// Check microphone permission without re-initializing.
  /// Useful for re-checking after app resume.
  Future<bool> checkPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Check if processing is enabled.
  @override
  bool get isProcessingEnabled => _isProcessingEnabled;

  @override
  Future<void> toggle() async {
    if (_isListening) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _recorder.dispose();
    _streamController.close();
  }

  /// Process incoming audio data (PCM16 format).
  Future<void> _onAudioData(Uint8List data) async {
    // Update heartbeat timestamp
    _lastDataTime = DateTime.now();

    // Skip processing if not enabled (keep-warm mode)
    if (!_isProcessingEnabled) return;

    try {
      // Convert PCM16 bytes to float samples
      final samples = _convertPcm16ToFloat(data);

      if (samples.isEmpty) return;

      // Accumulate samples until we have enough for analysis
      _sampleBuffer.addAll(samples);

      // Process when we have enough samples
      while (_sampleBuffer.length >= _config.bufferSize) {
        final bufferToProcess =
            _sampleBuffer.sublist(0, _config.bufferSize).toList();
        _sampleBuffer.removeRange(0, _config.bufferSize ~/ 2); // 50% overlap

        await _processBuffer(bufferToProcess);
      }
    } catch (_) {
      // Audio processing error - silently ignore
    }
  }

  Future<void> _processBuffer(List<double> samples) async {
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
        return;
      }
    }

    // Not stable - emit null (provider handles grace period)
    _emitNote(null);
  }

  void _onAudioError(Object error) {
    onError?.call('Audio capture error: $error');
  }

  /// Convert PCM16 bytes to float samples (-1.0 to 1.0).
  List<double> _convertPcm16ToFloat(Uint8List bytes) {
    final samples = <double>[];

    // PCM16 is 2 bytes per sample, little-endian
    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Read 16-bit signed integer (little-endian)
      int sample = bytes[i] | (bytes[i + 1] << 8);

      // Convert to signed
      if (sample > 32767) {
        sample -= 65536;
      }

      // Normalize to -1.0 to 1.0
      samples.add(sample / 32768.0);
    }

    return samples;
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
  }
}
