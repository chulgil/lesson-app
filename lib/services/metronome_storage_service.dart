import 'package:hive_flutter/hive_flutter.dart';
import '../models/metronome_settings.dart';

/// Service for persisting metronome settings using Hive.
class MetronomeStorageService {
  static const String _boxName = 'metronome_settings';
  static const String _bpmKey = 'bpm';
  static const String _timeSignatureKey = 'timeSignature';
  static const String _soundKey = 'sound';
  static const String _accentPatternKey = 'accentPattern';
  static const String _visualFlashKey = 'visualFlash';
  static const String _vibrationKey = 'vibration';

  Box? _box;

  /// Initialize the storage service.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save metronome settings.
  Future<void> saveSettings(MetronomeSettings settings) async {
    if (_box == null) await init();

    await _box!.put(_bpmKey, settings.bpm);
    await _box!.put(_timeSignatureKey, settings.timeSignature.index);
    await _box!.put(_soundKey, settings.sound.index);
    await _box!.put(_accentPatternKey, settings.accentPattern.index);
    await _box!.put(_visualFlashKey, settings.visualFlash);
    await _box!.put(_vibrationKey, settings.vibration);
  }

  /// Load metronome settings.
  Future<MetronomeSettings> loadSettings() async {
    if (_box == null) await init();

    final bpm = _box!.get(_bpmKey, defaultValue: 60) as int;
    final timeSignatureIndex = _box!.get(_timeSignatureKey, defaultValue: 2) as int;
    final soundIndex = _box!.get(_soundKey, defaultValue: 0) as int;
    final accentPatternIndex = _box!.get(_accentPatternKey, defaultValue: 0) as int;
    final visualFlash = _box!.get(_visualFlashKey, defaultValue: true) as bool;
    final vibration = _box!.get(_vibrationKey, defaultValue: false) as bool;

    return MetronomeSettings(
      bpm: MetronomeSettings.clampBpm(bpm),
      timeSignature: TimeSignature.values[timeSignatureIndex.clamp(0, TimeSignature.values.length - 1)],
      sound: MetronomeSound.values[soundIndex.clamp(0, MetronomeSound.values.length - 1)],
      accentPattern: AccentPattern.values[accentPatternIndex.clamp(0, AccentPattern.values.length - 1)],
      visualFlash: visualFlash,
      vibration: vibration,
    );
  }

  /// Close the storage.
  Future<void> close() async {
    await _box?.close();
  }
}
