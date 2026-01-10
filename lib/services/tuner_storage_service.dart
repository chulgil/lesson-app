import 'package:hive_flutter/hive_flutter.dart';
import '../features/practice/domain/entities/tuner_settings.dart';
import '../features/practice/domain/entities/tuner_types.dart';

/// Service for persisting tuner settings using Hive.
class TunerStorageService {
  static const String _boxName = 'tuner_settings';
  static const String _referenceFrequencyKey = 'referenceFrequency';
  static const String _transpositionKey = 'transposition';
  static const String _enharmonicModeKey = 'enharmonicMode';
  static const String _difficultyKey = 'difficulty';
  static const String _clefTypeKey = 'clefType';
  static const String _showComboKey = 'showCombo';
  static const String _vibrationFeedbackKey = 'vibrationFeedback';

  Box? _box;

  /// Singleton instance
  static final TunerStorageService _instance = TunerStorageService._internal();
  factory TunerStorageService() => _instance;
  TunerStorageService._internal();

  /// Initialize the storage service.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save tuner settings.
  Future<void> saveSettings(TunerSettings settings) async {
    if (_box == null) await init();

    await _box!.put(_referenceFrequencyKey, settings.referenceFrequency);
    await _box!.put(_transpositionKey, settings.transposition.index);
    await _box!.put(_enharmonicModeKey, settings.enharmonicMode.index);
    await _box!.put(_difficultyKey, settings.difficulty.index);
    await _box!.put(_clefTypeKey, settings.clefType.index);
    await _box!.put(_showComboKey, settings.showCombo);
    await _box!.put(_vibrationFeedbackKey, settings.vibrationFeedback);
  }

  /// Load tuner settings.
  Future<TunerSettings> loadSettings() async {
    if (_box == null) await init();

    final referenceFrequency =
        _box!.get(_referenceFrequencyKey, defaultValue: 440.0) as double;
    final transpositionIndex =
        _box!.get(_transpositionKey, defaultValue: 0) as int;
    final enharmonicModeIndex =
        _box!.get(_enharmonicModeKey, defaultValue: 0) as int;
    final difficultyIndex = _box!.get(_difficultyKey, defaultValue: 1) as int;
    final clefTypeIndex = _box!.get(_clefTypeKey, defaultValue: 0) as int;
    final showCombo = _box!.get(_showComboKey, defaultValue: true) as bool;
    final vibrationFeedback =
        _box!.get(_vibrationFeedbackKey, defaultValue: false) as bool;

    return TunerSettings(
      referenceFrequency: TunerSettings.clampFrequency(referenceFrequency),
      transposition: Transposition
          .values[transpositionIndex.clamp(0, Transposition.values.length - 1)],
      enharmonicMode: EnharmonicMode
          .values[enharmonicModeIndex.clamp(0, EnharmonicMode.values.length - 1)],
      difficulty: TunerDifficulty
          .values[difficultyIndex.clamp(0, TunerDifficulty.values.length - 1)],
      clefType: ClefType
          .values[clefTypeIndex.clamp(0, ClefType.values.length - 1)],
      showCombo: showCombo,
      vibrationFeedback: vibrationFeedback,
    );
  }

  /// Close the storage.
  Future<void> close() async {
    await _box?.close();
  }
}
