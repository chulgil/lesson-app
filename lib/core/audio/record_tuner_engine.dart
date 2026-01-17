// Record-based tuner engine
// Uses the record package for audio input (supports all platforms)
// Uses pitch_detector_dart (YIN algorithm) for pitch detection

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import 'package:lesson_app/features/practice/domain/entities/tuner_types.dart';

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
  TunerNote? _currentNote;
  double _referenceFrequency;
  double _sensitivity = 0.5;

  // Buffer for accumulating audio samples
  final List<double> _sampleBuffer = [];

  // Note hold mechanism - keeps last note during brief gaps
  TunerNote? _lastValidNote;
  DateTime? _lastValidNoteTime;
  static const Duration _noteHoldDuration = Duration(milliseconds: 800);

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
      debugPrint('RecordTunerEngine: Initializing...');

      // Check microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('RecordTunerEngine: No microphone permission');
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
      debugPrint('RecordTunerEngine: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('RecordTunerEngine: Init failed - $e');
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
      debugPrint('RecordTunerEngine: Starting audio capture...');

      _isListening = true;
      _isProcessingEnabled = true;
      _stabilityFilter.reset();
      _amplitudeGate.reset();
      _sampleBuffer.clear();
      _lastValidNote = null;
      _lastValidNoteTime = null;

      // Start stream if not already active
      if (!_isStreamActive) {
        await _startStream();
      }

      debugPrint('RecordTunerEngine: Audio capture started');
    } catch (e) {
      _isListening = false;
      _isProcessingEnabled = false;
      debugPrint('RecordTunerEngine: Start failed - $e');
      onError?.call('Failed to start audio capture: $e');
    }
  }

  /// Start the recorder stream (internal helper).
  Future<void> _startStream() async {
    if (_isStreamActive) return;

    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _config.sampleRate,
        numChannels: 1,
      ),
    );

    _audioSubscription = stream.listen(
      _onAudioData,
      onError: _onAudioError,
    );

    _isStreamActive = true;
    debugPrint('RecordTunerEngine: Stream started');
  }

  /// Stop the recorder stream (internal helper).
  Future<void> _stopStream() async {
    if (!_isStreamActive) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();

    _isStreamActive = false;
    debugPrint('RecordTunerEngine: Stream stopped');
  }

  @override
  Future<void> stop() async {
    if (!_isListening) return;

    try {
      debugPrint('RecordTunerEngine: Stopping audio capture...');

      _isListening = false;
      _isProcessingEnabled = false;

      // Actually stop the stream
      await _stopStream();

      _currentNote = null;
      _sampleBuffer.clear();
      _lastValidNote = null;
      _lastValidNoteTime = null;

      _streamController.add(null);
      onPitchDetected?.call(null);

      debugPrint('RecordTunerEngine: Audio capture stopped');
    } catch (e) {
      debugPrint('RecordTunerEngine: Stop failed - $e');
      onError?.call('Failed to stop audio capture: $e');
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
      debugPrint('RecordTunerEngine: Already warmed up');
      return;
    }

    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    try {
      debugPrint('RecordTunerEngine: Warming up (starting stream without processing)...');

      _isProcessingEnabled = false;
      _stabilityFilter.reset();
      _amplitudeGate.reset();
      _sampleBuffer.clear();

      await _startStream();

      debugPrint('RecordTunerEngine: Warm up complete');
    } catch (e) {
      debugPrint('RecordTunerEngine: Warm up failed - $e');
      onError?.call('Failed to warm up: $e');
    }
  }

  /// Enable pitch processing (stream must be active from warmUp or start).
  ///
  /// This is instantaneous and doesn't block the main thread.
  @override
  void enableProcessing() {
    if (!_isStreamActive) {
      debugPrint('RecordTunerEngine: Cannot enable processing - stream not active');
      return;
    }

    debugPrint('RecordTunerEngine: Enabling processing');
    _isListening = true;
    _isProcessingEnabled = true;
    _stabilityFilter.reset();
    _amplitudeGate.reset();
    _sampleBuffer.clear();
    _lastValidNote = null;
    _lastValidNoteTime = null;
  }

  /// Disable pitch processing but keep the stream active.
  ///
  /// This allows instant re-enabling without audio session reconfiguration.
  @override
  void disableProcessing() {
    debugPrint('RecordTunerEngine: Disabling processing (keeping stream active)');
    _isListening = false;
    _isProcessingEnabled = false;
    _currentNote = null;
    _sampleBuffer.clear();
    _lastValidNote = null;
    _lastValidNoteTime = null;

    _streamController.add(null);
    onPitchDetected?.call(null);
  }

  /// Check if the stream is active (warmed up or started).
  @override
  bool get isStreamActive => _isStreamActive;

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
  void dispose() {
    stop();
    _recorder.dispose();
    _streamController.close();
  }

  /// Process incoming audio data (PCM16 format).
  Future<void> _onAudioData(Uint8List data) async {
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
    } catch (e) {
      debugPrint('RecordTunerEngine: Audio processing error - $e');
    }
  }

  Future<void> _processBuffer(List<double> samples) async {
    // Check amplitude (noise gate)
    final amplitude = _calculateAmplitude(samples);
    if (!_amplitudeGate.check(amplitude)) {
      // Use note hold - emit last valid note if within hold duration
      _emitWithHold(null);
      return;
    }

    // Detect pitch using YIN algorithm
    final pitchResult = await _pitchDetector.getPitchFromFloatBuffer(samples);

    // Debug log
    if (pitchResult.pitched && pitchResult.pitch > 0) {
      debugPrint('Pitch: ${pitchResult.pitch.toStringAsFixed(1)}Hz');
    }

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
        // Update last valid note and emit
        _lastValidNote = note;
        _lastValidNoteTime = DateTime.now();
        _emitNote(note);
        return;
      }
    }

    // Not stable - use note hold mechanism
    _emitWithHold(null);
  }

  /// Emit note with hold mechanism - keeps last note during brief gaps.
  void _emitWithHold(TunerNote? note) {
    if (note != null) {
      _lastValidNote = note;
      _lastValidNoteTime = DateTime.now();
      _emitNote(note);
      return;
    }

    // Check if we should hold the last valid note
    if (_lastValidNote != null && _lastValidNoteTime != null) {
      final elapsed = DateTime.now().difference(_lastValidNoteTime!);
      if (elapsed < _noteHoldDuration) {
        // Keep emitting last valid note (don't emit null)
        // This prevents flickering during brief detection gaps
        return;
      }
    }

    // Hold duration expired - clear note
    _lastValidNote = null;
    _lastValidNoteTime = null;
    _emitNote(null);
  }

  void _onAudioError(Object error) {
    debugPrint('RecordTunerEngine: Audio error - $error');
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
    onPitchDetected?.call(note);
  }
}
