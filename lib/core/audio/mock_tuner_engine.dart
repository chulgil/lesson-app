// Mock tuner engine for testing and development
// Simulates pitch detection without actual microphone input

import 'dart:async';
import 'dart:math' as math;

import 'package:lesson_app/features/practice/domain/entities/tuner_settings.dart';
import 'package:lesson_app/features/practice/domain/entities/tuner_types.dart';

import 'tuner_engine.dart';

/// Mock tuner engine that simulates pitch detection.
///
/// Useful for:
/// - UI development without microphone access
/// - Testing tuner widgets and animations
/// - Demo mode on simulators
class MockTunerEngine implements TunerEngine {
  MockTunerEngine({
    TunerEngineConfig? config,
    this.simulationMode = MockSimulationMode.random,
  }) : config = config ?? const TunerEngineConfig();

  /// Engine configuration.
  final TunerEngineConfig config;
  final MockSimulationMode simulationMode;

  Timer? _timer;
  final _streamController = StreamController<TunerNote?>.broadcast();
  final _random = math.Random();

  bool _isListening = false;
  TunerNote? _currentNote;
  double _referenceFrequency = 440.0;
  double _sensitivity = 0.5;

  // Simulation state
  int _simulationStep = 0;
  NoteName _targetNote = NoteName.A;
  double _targetCent = 0;

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
    // Mock initialization always succeeds
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  @override
  Future<void> start() async {
    if (_isListening) return;

    _isListening = true;
    _simulationStep = 0;

    // Simulate pitch detection at ~30fps
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _simulatePitchDetection();
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isListening = false;
    _currentNote = null;
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
    _timer?.cancel();
    _streamController.close();
  }

  void _simulatePitchDetection() {
    switch (simulationMode) {
      case MockSimulationMode.random:
        _simulateRandomNote();
        break;
      case MockSimulationMode.sweep:
        _simulateSweep();
        break;
      case MockSimulationMode.targetNote:
        _simulateTargetNote();
        break;
      case MockSimulationMode.tuningApproach:
        _simulateTuningApproach();
        break;
    }

    _simulationStep++;
  }

  void _simulateRandomNote() {
    // 10% chance of no detection
    if (_random.nextDouble() < 0.1) {
      _emitNote(null);
      return;
    }

    // Random note from A3 to A5
    final noteIndex = _random.nextInt(12);
    final octave = 3 + _random.nextInt(3);
    final note = NoteName.values[noteIndex];

    // Random cent deviation (-30 to +30)
    final cent = (_random.nextDouble() * 60) - 30;

    _emitNoteFromParams(note, octave, cent);
  }

  void _simulateSweep() {
    // Sweep through all notes cyclically
    final noteIndex = (_simulationStep ~/ 30) % 12;
    final octave = 4;
    final note = NoteName.values[noteIndex];

    // Slight cent variation
    final cent = math.sin(_simulationStep * 0.1) * 10;

    _emitNoteFromParams(note, octave, cent);
  }

  void _simulateTargetNote() {
    // Always emit the target note with slight variation
    final cent = _targetCent + (math.sin(_simulationStep * 0.2) * 3);
    _emitNoteFromParams(_targetNote, 4, cent);
  }

  void _simulateTuningApproach() {
    // Simulate approaching perfect tuning
    // Start with large deviation, gradually approach 0
    final progress = (_simulationStep % 150) / 150.0;
    final deviation = 40 * (1 - progress) * math.sin(_simulationStep * 0.3);

    _emitNoteFromParams(_targetNote, 4, deviation);
  }

  void _emitNoteFromParams(NoteName name, int octave, double centDeviation) {
    final baseFreq = name.frequency(octave, referenceA4: _referenceFrequency);
    final frequency = baseFreq * math.pow(2, centDeviation / 1200);

    final note = TunerNote(
      name: name,
      octave: octave,
      frequency: frequency,
      centDeviation: centDeviation.clamp(-50.0, 50.0),
    );

    _emitNote(note);
  }

  void _emitNote(TunerNote? note) {
    _currentNote = note;
    _streamController.add(note);
    onPitchDetected?.call(note);
  }

  /// Set target note for simulation modes that use it.
  void setTargetNote(NoteName note, {double cent = 0}) {
    _targetNote = note;
    _targetCent = cent;
  }

  /// Reset simulation state.
  void resetSimulation() {
    _simulationStep = 0;
  }
}

/// Simulation modes for the mock tuner engine.
enum MockSimulationMode {
  /// Random notes with random deviations
  random,

  /// Sweep through all 12 notes cyclically
  sweep,

  /// Always emit the target note
  targetNote,

  /// Simulate approaching perfect tuning (for demos)
  tuningApproach,
}
