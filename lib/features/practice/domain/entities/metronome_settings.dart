// Metronome settings domain entities
// Moved from lib/models/metronome_settings.dart for Clean Architecture

/// Beat intensity type for different sounds per beat position.
enum BeatType {
  /// First beat of measure (accent).
  strong,

  /// Middle beat (e.g., beat 3 in 4/4).
  medium,

  /// Off-beats (e.g., beats 2, 4 in 4/4).
  weak,
}

/// Accent pattern for metronome beats.
enum AccentPattern {
  /// Uniform pattern - all beats same intensity.
  uniform('균일', '모든 박자 동일'),

  /// First beat only strong, rest weak (강 약 약 약).
  firstBeatOnly('첫박강조', '첫박만 강조'),

  /// Strong-medium-weak pattern (강 약 중 약 for 4/4).
  strongMediumWeak('강중약', '첫박 강, 3박 중간');

  const AccentPattern(this.label, this.description);

  final String label;
  final String description;
}

/// Subdivision pattern for metronome.
/// Determines how many clicks per beat.
enum Subdivision {
  /// Quarter notes - 1 click per beat (default).
  quarter(1, '기본', 'Quarter', '●'),

  /// Eighth notes - 2 clicks per beat.
  eighth(2, '8분음표', 'Eighth', '● ○'),

  /// Triplets - 3 clicks per beat.
  triplet(3, '셋잇단음', 'Triplet', '● ○ ○'),

  /// Sixteenth notes - 4 clicks per beat.
  sixteenth(4, '16분음표', 'Sixteenth', '● ○ ○ ○'),

  /// Quintuplets - 5 clicks per beat.
  quintuplet(5, '5연음', 'Quintuplet', '● ○ ○ ○ ○'),

  /// Sextuplets - 6 clicks per beat.
  sextuplet(6, '6연음', 'Sextuplet', '● ○ ○ ○ ○ ○');

  const Subdivision(
    this.divisionsPerBeat,
    this.label,
    this.englishName,
    this.visualPattern,
  );

  /// Number of subdivisions per beat.
  final int divisionsPerBeat;

  /// Korean display name.
  final String label;

  /// English name.
  final String englishName;

  /// Visual pattern representation.
  final String visualPattern;

  /// Whether this is a basic subdivision (shown in main selector).
  bool get isBasic => divisionsPerBeat <= 4;
}

/// Time signature options for the metronome.
enum TimeSignature {
  twoFour('2/4', 2),
  threeFour('3/4', 3),
  fourFour('4/4', 4),
  sixEight('6/8', 6);

  const TimeSignature(this.label, this.beatsPerMeasure);

  final String label;
  final int beatsPerMeasure;
}

/// Available metronome sounds.
enum MetronomeSound {
  pen('펜', 'pen', 'pen', false),
  drum('드럼', 'drum', 'hybrid', false),
  happyKitten('고양이', 'happy_kitten', 'happy_kitten', false),
  stick('스틱', 'stick', 'stick', false),
  woodblock('우드블록', 'woodblock', 'woodblock', false),
  silent('무음', '', '', false);

  const MetronomeSound(
      this.label, this.folderName, this.filePrefix, this.singleFile);

  final String label;
  final String folderName;
  final String filePrefix;
  final bool singleFile; // True if only one file for all beat types

  /// Get asset path for a specific beat type.
  String getAssetPath(BeatType beatType) {
    if (this == silent) return '';

    final basePath = 'assets/sounds/metronome/$folderName';

    // Single file sounds use same file for all beats
    if (singleFile) {
      return '$basePath/$filePrefix.wav';
    }

    return switch (beatType) {
      BeatType.strong => '$basePath/${filePrefix}_strong.wav',
      BeatType.medium => '$basePath/${filePrefix}_medium.wav',
      BeatType.weak => '$basePath/${filePrefix}_weak.wav',
    };
  }
}

/// Metronome settings with BPM, time signature, and sound options.
class MetronomeSettings {
  const MetronomeSettings({
    this.bpm = 60,
    this.timeSignature = TimeSignature.fourFour,
    this.sound = MetronomeSound.pen,
    this.accentPattern = AccentPattern.strongMediumWeak,
    this.subdivision = Subdivision.quarter,
    this.visualFlash = true,
    this.vibration = false,
  });

  /// Beats per minute (40-208 range).
  final int bpm;

  /// Time signature (2/4, 3/4, 4/4, 6/8).
  final TimeSignature timeSignature;

  /// Sound type for metronome clicks.
  final MetronomeSound sound;

  /// Accent pattern for beat intensity.
  final AccentPattern accentPattern;

  /// Subdivision pattern (quarter, eighth, triplet, etc.).
  final Subdivision subdivision;

  /// Whether to show visual flash on each beat.
  final bool visualFlash;

  /// Whether to vibrate on each beat.
  final bool vibration;

  /// Minimum allowed BPM.
  static const int minBpm = 30;

  /// Maximum allowed BPM.
  static const int maxBpm = 208;

  /// Calculate interval in milliseconds between beats (integer, for legacy).
  int get intervalMs => (60000 / bpm).round();

  /// Calculate precise interval in milliseconds between beats (double).
  /// Use this for accurate timing calculations to avoid cumulative rounding errors.
  double get intervalMsPrecise => 60000.0 / bpm;

  /// Create a copy with modified values.
  MetronomeSettings copyWith({
    int? bpm,
    TimeSignature? timeSignature,
    MetronomeSound? sound,
    AccentPattern? accentPattern,
    Subdivision? subdivision,
    bool? visualFlash,
    bool? vibration,
  }) {
    return MetronomeSettings(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      sound: sound ?? this.sound,
      accentPattern: accentPattern ?? this.accentPattern,
      subdivision: subdivision ?? this.subdivision,
      visualFlash: visualFlash ?? this.visualFlash,
      vibration: vibration ?? this.vibration,
    );
  }

  /// Clamp BPM to valid range.
  static int clampBpm(int value) {
    if (value < minBpm) return minBpm;
    if (value > maxBpm) return maxBpm;
    return value;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetronomeSettings &&
        other.bpm == bpm &&
        other.timeSignature == timeSignature &&
        other.sound == sound &&
        other.accentPattern == accentPattern &&
        other.subdivision == subdivision &&
        other.visualFlash == visualFlash &&
        other.vibration == vibration;
  }

  @override
  int get hashCode {
    return Object.hash(
      bpm,
      timeSignature,
      sound,
      accentPattern,
      subdivision,
      visualFlash,
      vibration,
    );
  }
}
