import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:metronome/metronome.dart' as pkg;
import '../../models/metronome_settings.dart';
import 'metronome_engine_interface.dart';

/// Metronome engine using the 'metronome' package (AVAudioEngine on iOS).
///
/// This engine wraps the metronome package which uses native AVAudioEngine
/// for sample-accurate timing. The audio timing is handled by the native
/// looping buffer, providing much better accuracy than Timer-based approaches.
///
/// ## Subdivision Support
/// Subdivisions are implemented by multiplying BPM and timeSignature:
/// - 120 BPM + triplet (3) = 360 actual BPM
/// - 4/4 + triplet (3) = 12 ticks per measure
///
/// Sound mapping for subdivisions:
/// - mainPath = subdivision click (weak sound)
/// - accentedPath = main beat click (strong sound)
class MetronomePackageEngine implements MetronomeEngineInterface {
  MetronomePackageEngine();

  final pkg.Metronome _metronome = pkg.Metronome();
  StreamSubscription<int>? _tickSubscription;

  MetronomeSettings _settings = const MetronomeSettings();
  int _currentBeat = 0;
  int _currentSubdivision = 0;
  bool _isPlaying = false;
  bool _initialized = false;

  @override
  BeatCallback? onBeat;

  /// Callback for subdivision ticks (for UI visualization).
  /// Parameters: (subdivisionIndex, isMainBeat)
  /// subdivisionIndex: 0-based index within the beat
  /// isMainBeat: true if this is the main beat (index 0)
  void Function(int subdivisionIndex, bool isMainBeat)? onSubdivision;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get currentBeat => _currentBeat;

  /// Current subdivision index within the beat (0-based).
  int get currentSubdivision => _currentSubdivision;

  @override
  MetronomeSettings get settings => _settings;

  /// Get the actual BPM sent to the native engine (multiplied by subdivision).
  int get _actualBpm => _settings.bpm * _settings.subdivision.divisionsPerBeat;

  /// Get the actual time signature sent to the native engine.
  int get _actualTimeSignature =>
      _settings.timeSignature.beatsPerMeasure *
      _settings.subdivision.divisionsPerBeat;

  @override
  Future<void> init() async {
    if (_initialized) return;

    debugPrint('MetronomePackageEngine: init started');

    try {
      // For subdivisions, swap the sound paths:
      // - mainPath (played on non-first beats) = subdivision click (weak)
      // - accentedPath (played on first beat) = main beat click (strong)
      final String mainPath;
      final String accentedPath;

      if (_settings.subdivision.divisionsPerBeat > 1) {
        // Subdivision mode: weak sound for subdivisions, strong for main beats
        mainPath = _settings.sound.getAssetPath(BeatType.weak);
        accentedPath = _settings.sound.getAssetPath(BeatType.strong);
      } else {
        // Normal mode: strong for main beats, weak for others
        mainPath = _settings.sound.getAssetPath(BeatType.strong);
        accentedPath = _settings.sound.getAssetPath(BeatType.weak);
      }

      debugPrint('MetronomePackageEngine: mainPath=$mainPath');
      debugPrint('MetronomePackageEngine: accentedPath=$accentedPath');
      debugPrint('MetronomePackageEngine: actualBpm=$_actualBpm');
      debugPrint('MetronomePackageEngine: actualTimeSignature=$_actualTimeSignature');

      await _metronome.init(
        mainPath,
        accentedPath: accentedPath,
        bpm: _actualBpm,
        volume: 100,
        enableTickCallback: true,
        timeSignature: _actualTimeSignature,
        sampleRate: 44100,
      );

      // Subscribe to tick stream
      _tickSubscription = _metronome.tickStream.listen(_onTick);

      _initialized = true;
      debugPrint('MetronomePackageEngine: init completed');
    } catch (e) {
      debugPrint('MetronomePackageEngine: init failed - $e');
      rethrow;
    }
  }

  void _onTick(int tick) {
    if (!_isPlaying) return;

    final divisions = _settings.subdivision.divisionsPerBeat;

    // Calculate beat number and subdivision index
    // tick is 0-indexed from the package
    final subdivisionIndex = tick % divisions;
    final beatIndex = tick ~/ divisions;
    final beatNumber = beatIndex + 1; // 1-indexed beat number
    final isMainBeat = subdivisionIndex == 0;

    _currentBeat = beatNumber;
    _currentSubdivision = subdivisionIndex;

    // Notify subdivision callback
    onSubdivision?.call(subdivisionIndex, isMainBeat);

    // Only call onBeat for main beats (to maintain backward compatibility)
    if (isMainBeat) {
      final isAccent = _isAccentBeat(beatNumber);
      onBeat?.call(beatNumber, isAccent);
    }
  }

  bool _isAccentBeat(int beat) {
    // beat is 1-indexed (1,2,3,4)
    switch (_settings.accentPattern) {
      case AccentPattern.firstBeatOnly:
      case AccentPattern.strongMediumWeak:
        return beat == 1;
      case AccentPattern.uniform:
        return false;
    }
  }

  @override
  Future<void> updateSettings(MetronomeSettings newSettings) async {
    final soundChanged = _settings.sound != newSettings.sound;
    final timeSignatureChanged =
        _settings.timeSignature != newSettings.timeSignature;
    final bpmChanged = _settings.bpm != newSettings.bpm;
    final subdivisionChanged =
        _settings.subdivision != newSettings.subdivision;

    _settings = newSettings;

    if (!_initialized) {
      await init();
      return;
    }

    // If subdivision changed, we need to reconfigure everything
    if (subdivisionChanged) {
      debugPrint(
          'MetronomePackageEngine: subdivision changed to ${newSettings.subdivision.label}');

      // Update sound paths (may need to swap)
      final String mainPath;
      final String accentedPath;

      if (newSettings.subdivision.divisionsPerBeat > 1) {
        mainPath = newSettings.sound.getAssetPath(BeatType.weak);
        accentedPath = newSettings.sound.getAssetPath(BeatType.strong);
      } else {
        mainPath = newSettings.sound.getAssetPath(BeatType.strong);
        accentedPath = newSettings.sound.getAssetPath(BeatType.weak);
      }

      await _metronome.setAudioFile(
          mainPath: mainPath, accentedPath: accentedPath);

      // Update BPM and time signature with new multiplier
      final actualBpm =
          newSettings.bpm * newSettings.subdivision.divisionsPerBeat;
      final actualTimeSignature =
          newSettings.timeSignature.beatsPerMeasure *
              newSettings.subdivision.divisionsPerBeat;

      await _metronome.setBPM(actualBpm);
      await _metronome.setTimeSignature(actualTimeSignature);

      debugPrint('MetronomePackageEngine: actualBpm=$actualBpm');
      debugPrint(
          'MetronomePackageEngine: actualTimeSignature=$actualTimeSignature');
      return;
    }

    // Handle other changes
    if (soundChanged) {
      final String mainPath;
      final String accentedPath;

      if (newSettings.subdivision.divisionsPerBeat > 1) {
        mainPath = newSettings.sound.getAssetPath(BeatType.weak);
        accentedPath = newSettings.sound.getAssetPath(BeatType.strong);
      } else {
        mainPath = newSettings.sound.getAssetPath(BeatType.strong);
        accentedPath = newSettings.sound.getAssetPath(BeatType.weak);
      }

      await _metronome.setAudioFile(
          mainPath: mainPath, accentedPath: accentedPath);
      debugPrint('MetronomePackageEngine: sound updated');
    }

    if (timeSignatureChanged) {
      final actualTimeSignature =
          newSettings.timeSignature.beatsPerMeasure *
              newSettings.subdivision.divisionsPerBeat;
      await _metronome.setTimeSignature(actualTimeSignature);
      debugPrint(
          'MetronomePackageEngine: timeSignature updated to $actualTimeSignature');
    }

    if (bpmChanged) {
      final actualBpm =
          newSettings.bpm * newSettings.subdivision.divisionsPerBeat;
      await _metronome.setBPM(actualBpm);
      debugPrint('MetronomePackageEngine: BPM updated to $actualBpm');
    }
  }

  @override
  Future<void> start() async {
    if (_isPlaying) return;

    if (!_initialized) {
      await init();
    }

    debugPrint(
        'MetronomePackageEngine: start at ${_settings.bpm} BPM (actual: $_actualBpm)');
    _isPlaying = true;
    _currentBeat = 0;
    _currentSubdivision = 0;
    await _metronome.play();
  }

  @override
  Future<void> stop() async {
    if (!_isPlaying) return;

    debugPrint('MetronomePackageEngine: stop');
    _isPlaying = false;
    _currentBeat = 0;
    _currentSubdivision = 0;
    await _metronome.stop();
  }

  @override
  Future<void> toggle() async {
    if (_isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  Future<void> setBpm(int bpm) async {
    final clampedBpm = MetronomeSettings.clampBpm(bpm);
    if (clampedBpm == _settings.bpm) return;

    _settings = _settings.copyWith(bpm: clampedBpm);

    if (_initialized) {
      final actualBpm = clampedBpm * _settings.subdivision.divisionsPerBeat;
      await _metronome.setBPM(actualBpm);
    }
  }

  @override
  Future<void> incrementBpm(int delta) async {
    await setBpm(_settings.bpm + delta);
  }

  @override
  Future<void> playTapSound() async {
    // The metronome package doesn't have a direct tap sound API
    // We could use a separate audio player, but for simplicity,
    // provide haptic feedback instead
    HapticFeedback.lightImpact();
  }

  @override
  Future<void> dispose() async {
    debugPrint('MetronomePackageEngine: dispose');
    await stop();
    _tickSubscription?.cancel();
    _tickSubscription = null;
    await _metronome.destroy();
    _initialized = false;
  }
}
