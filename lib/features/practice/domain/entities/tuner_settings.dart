// Tuner settings domain entity
// Settings for chromatic tuner with professional features

import 'tuner_types.dart';

/// Enharmonic display mode for accidentals.
enum EnharmonicMode {
  /// Show only sharp names (C#, D#, F#, G#, A#)
  sharpOnly('샤프', 'C#, D#, ...'),

  /// Show only flat names (Db, Eb, Gb, Ab, Bb)
  flatOnly('플랫', 'Db, Eb, ...'),

  /// Show both (C#/Db, D#/Eb, ...)
  both('병기', 'C#/Db, ...');

  const EnharmonicMode(this.label, this.example);

  final String label;
  final String example;
}

/// Tuner settings with reference frequency, transposition, and display options.
class TunerSettings {
  const TunerSettings({
    this.referenceFrequency = 440.0,
    this.transposition = Transposition.c,
    this.enharmonicMode = EnharmonicMode.sharpOnly,
    this.difficulty = TunerDifficulty.intermediate,
    this.showCombo = true,
    this.vibrationFeedback = false,
  });

  /// Reference frequency for A4 (430-450Hz range).
  final double referenceFrequency;

  /// Transposition for wind instruments.
  final Transposition transposition;

  /// How to display accidentals (sharps, flats, or both).
  final EnharmonicMode enharmonicMode;

  /// Difficulty level for judgement thresholds.
  final TunerDifficulty difficulty;

  /// Whether to show combo counter.
  final bool showCombo;

  /// Whether to vibrate on perfect tuning.
  final bool vibrationFeedback;

  /// Minimum reference frequency (430Hz for baroque)
  static const double minReferenceFrequency = 430.0;

  /// Maximum reference frequency (450Hz for high orchestras)
  static const double maxReferenceFrequency = 450.0;

  /// Common reference frequency presets
  static const List<double> frequencyPresets = [
    440.0, // International standard
    441.0,
    442.0, // European/Korean orchestras
    443.0,
  ];

  /// Create a copy with modified values.
  TunerSettings copyWith({
    double? referenceFrequency,
    Transposition? transposition,
    EnharmonicMode? enharmonicMode,
    TunerDifficulty? difficulty,
    bool? showCombo,
    bool? vibrationFeedback,
  }) {
    return TunerSettings(
      referenceFrequency: referenceFrequency ?? this.referenceFrequency,
      transposition: transposition ?? this.transposition,
      enharmonicMode: enharmonicMode ?? this.enharmonicMode,
      difficulty: difficulty ?? this.difficulty,
      showCombo: showCombo ?? this.showCombo,
      vibrationFeedback: vibrationFeedback ?? this.vibrationFeedback,
    );
  }

  /// Clamp reference frequency to valid range.
  static double clampFrequency(double value) {
    if (value < minReferenceFrequency) return minReferenceFrequency;
    if (value > maxReferenceFrequency) return maxReferenceFrequency;
    return value;
  }

  /// Get display string for reference frequency (e.g., "A4 = 442Hz")
  String get frequencyDisplayString =>
      'A4 = ${referenceFrequency.toStringAsFixed(0)}Hz';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TunerSettings &&
        other.referenceFrequency == referenceFrequency &&
        other.transposition == transposition &&
        other.enharmonicMode == enharmonicMode &&
        other.difficulty == difficulty &&
        other.showCombo == showCombo &&
        other.vibrationFeedback == vibrationFeedback;
  }

  @override
  int get hashCode {
    return Object.hash(
      referenceFrequency,
      transposition,
      enharmonicMode,
      difficulty,
      showCombo,
      vibrationFeedback,
    );
  }
}
