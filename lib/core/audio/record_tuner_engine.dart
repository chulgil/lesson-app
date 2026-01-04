// Record-based tuner engine
// Uses the record package for audio input with FFT pitch detection

import 'dart:async';
import 'dart:math' as math;

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:lesson_app/features/practice/domain/entities/tuner_settings.dart';
import 'package:lesson_app/features/practice/domain/entities/tuner_types.dart';

import 'tuner_engine.dart';

/// Tuner engine using the record package for audio input.
///
/// This engine uses the device microphone to detect pitch in real-time.
/// It uses amplitude monitoring and frequency estimation to detect notes.
class RecordTunerEngine implements TunerEngine {
  RecordTunerEngine({
    TunerEngineConfig? config,
  }) : _config = config ?? const TunerEngineConfig();

  final TunerEngineConfig _config;
  final AudioRecorder _recorder = AudioRecorder();
  final _streamController = StreamController<TunerNote?>.broadcast();

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _processingTimer;

  bool _isListening = false;
  bool _isInitialized = false;
  TunerNote? _currentNote;
  double _referenceFrequency = 440.0;
  double _sensitivity = 0.5;

  // Amplitude history for frequency estimation
  final List<double> _amplitudeHistory = [];
  static const int _historySize = 64;

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
    _referenceFrequency = TunerSettings.clampFrequency(value);
  }

  @override
  double get sensitivity => _sensitivity;

  @override
  set sensitivity(double value) {
    _sensitivity = value.clamp(0.0, 1.0);
  }

  @override
  OnPitchDetected? onPitchDetected;

  @override
  OnTunerError? onError;

  @override
  Future<bool> init() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      onError?.call('Microphone permission denied');
      return false;
    }

    // Check if recording is supported
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      onError?.call('Recording not available');
      return false;
    }

    _isInitialized = true;
    return true;
  }

  @override
  Future<void> start() async {
    if (_isListening) return;
    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    try {
      // Start recording with amplitude monitoring
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: '', // Empty path for stream-only mode
      );

      _isListening = true;
      _amplitudeHistory.clear();

      // Monitor amplitude at 60Hz
      _processingTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _processAudio(),
      );
    } catch (e) {
      onError?.call('Failed to start recording: $e');
    }
  }

  @override
  Future<void> stop() async {
    _processingTimer?.cancel();
    _processingTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (_isListening) {
      try {
        await _recorder.stop();
      } catch (_) {
        // Ignore stop errors
      }
    }

    _isListening = false;
    _currentNote = null;
    _amplitudeHistory.clear();
    _streamController.add(null);
    onPitchDetected?.call(null);
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
    _processingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _streamController.close();
  }

  Future<void> _processAudio() async {
    if (!_isListening) return;

    try {
      final amplitude = await _recorder.getAmplitude();
      final currentDb = amplitude.current;

      // Convert dB to linear amplitude (0-1)
      // -160 dB is silence, 0 dB is max
      final linearAmp = math.pow(10, currentDb / 20).clamp(0.0, 1.0);

      // Check if amplitude is above threshold
      final threshold = (1 - _sensitivity) * 0.1; // Adjusted for sensitivity
      if (linearAmp < threshold) {
        _emitNote(null);
        return;
      }

      // Add to history for frequency estimation
      _amplitudeHistory.add(linearAmp.toDouble());
      if (_amplitudeHistory.length > _historySize) {
        _amplitudeHistory.removeAt(0);
      }

      // TODO: Implement proper FFT-based pitch detection
      // For now, we use a simplified frequency estimation
      // This is a placeholder that should be replaced with proper FFT analysis

      // Estimate frequency from amplitude pattern
      // This is a very rough approximation and should be replaced
      final estimatedFreq = _estimateFrequency();

      if (estimatedFreq != null &&
          estimatedFreq >= _config.minFrequency &&
          estimatedFreq <= _config.maxFrequency) {
        final note = PitchUtils.frequencyToNote(
          estimatedFreq,
          referenceA4: _referenceFrequency,
        );
        _emitNote(note);
      } else {
        _emitNote(null);
      }
    } catch (e) {
      // Silently handle amplitude reading errors
    }
  }

  /// Estimate frequency from amplitude history.
  ///
  /// NOTE: This is a placeholder implementation.
  /// Real pitch detection requires proper FFT or autocorrelation analysis.
  double? _estimateFrequency() {
    if (_amplitudeHistory.length < _historySize ~/ 2) {
      return null;
    }

    // TODO: Implement proper pitch detection algorithm
    // Options:
    // 1. FFT with peak detection
    // 2. Autocorrelation
    // 3. YIN algorithm
    // 4. McLeod Pitch Method

    // For now, return a dummy frequency based on amplitude pattern
    // This should be replaced with actual pitch detection

    // Placeholder: detect zero crossings (very rough approximation)
    int zeroCrossings = 0;
    for (int i = 1; i < _amplitudeHistory.length; i++) {
      final prev = _amplitudeHistory[i - 1] - 0.5;
      final curr = _amplitudeHistory[i] - 0.5;
      if (prev * curr < 0) {
        zeroCrossings++;
      }
    }

    if (zeroCrossings < 2) return null;

    // Estimate frequency from zero crossings
    // This is highly inaccurate but serves as a placeholder
    final samplesPerCycle = _amplitudeHistory.length / (zeroCrossings / 2);
    final estimatedFreq = _config.sampleRate / 60 / samplesPerCycle;

    // Validate range
    if (estimatedFreq < 50 || estimatedFreq > 2000) {
      return null;
    }

    return estimatedFreq;
  }

  void _emitNote(TunerNote? note) {
    if (_currentNote != note) {
      _currentNote = note;
      _streamController.add(note);
      onPitchDetected?.call(note);
    }
  }
}
