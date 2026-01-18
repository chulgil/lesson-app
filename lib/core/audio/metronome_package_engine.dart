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
      final (mainPath, accentedPath) = _getSoundPaths(_settings);

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

    // Check if this subdivision should play sound (based on soundPattern)
    final shouldPlaySound = _settings.subdivision.shouldPlayAt(subdivisionIndex);

    _currentBeat = beatNumber;
    _currentSubdivision = subdivisionIndex;

    // Notify subdivision callback (always, for UI visualization)
    onSubdivision?.call(subdivisionIndex, isMainBeat);

    // Only call onBeat for main beats that should sound
    // Note: Native engine will still play sound; soundPattern affects callbacks only
    if (isMainBeat && shouldPlaySound) {
      final isAccent = _isAccentBeat(beatNumber);
      onBeat?.call(beatNumber, isAccent);
    }
  }

  bool _isAccentBeat(int beat) {
    // beat is 1-indexed (1,2,3,4...)
    final ts = _settings.timeSignature;

    switch (_settings.accentPattern) {
      case AccentPattern.firstBeatOnly:
      case AccentPattern.strongMediumWeak:
        if (ts.isCompound) {
          // Compound time: accent every 3 beats (1, 4, 7, 10...)
          // 6/8 has 2 main beats, 9/8 has 3 main beats, 12/8 has 4 main beats
          return (beat - 1) % 3 == 0;
        }
        return beat == 1;
      case AccentPattern.uniform:
        return false;
    }
  }

  /// Helper to get sound paths based on current settings
  (String mainPath, String accentedPath) _getSoundPaths(MetronomeSettings settings) {
    // Uniform pattern: all beats use the same sound (medium)
    if (settings.accentPattern == AccentPattern.uniform) {
      final uniformSound = settings.sound.getAssetPath(BeatType.medium);
      return (uniformSound, uniformSound);
    } else if (settings.subdivision.divisionsPerBeat > 1) {
      // Subdivision mode: weak sound for subdivisions, strong for main beats
      return (
        settings.sound.getAssetPath(BeatType.weak),
        settings.sound.getAssetPath(BeatType.strong),
      );
    } else {
      // Normal mode: strong for main beats, weak for others
      return (
        settings.sound.getAssetPath(BeatType.strong),
        settings.sound.getAssetPath(BeatType.weak),
      );
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
    final accentPatternChanged =
        _settings.accentPattern != newSettings.accentPattern;

    _settings = newSettings;

    if (!_initialized) {
      await init();
      return;
    }

    // Collect all updates needed
    final (mainPath, accentedPath) = _getSoundPaths(newSettings);
    final actualTimeSignature =
        newSettings.timeSignature.beatsPerMeasure *
            newSettings.subdivision.divisionsPerBeat;
    final actualBpm =
        newSettings.bpm * newSettings.subdivision.divisionsPerBeat;

    debugPrint('MetronomePackageEngine: updateSettings - subdivision=${newSettings.subdivision.label}, '
        'timeSignature=$actualTimeSignature, bpm=$actualBpm');

    // Update all settings without awaiting each one (native calls may block)
    // Order matters: sounds first, then timeSignature, then BPM
    if (subdivisionChanged || accentPatternChanged || soundChanged) {
      debugPrint('MetronomePackageEngine: mainPath=$mainPath, accentedPath=$accentedPath');
      _metronome.setAudioFile(mainPath: mainPath, accentedPath: accentedPath);
    }

    if (subdivisionChanged || timeSignatureChanged) {
      debugPrint('MetronomePackageEngine: setTimeSignature($actualTimeSignature)');
      _metronome.setTimeSignature(actualTimeSignature);
    }

    if (subdivisionChanged || bpmChanged) {
      debugPrint('MetronomePackageEngine: setBPM($actualBpm)');
      _metronome.setBPM(actualBpm);
    }

    // Give native side time to process
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('MetronomePackageEngine: updateSettings completed');
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
