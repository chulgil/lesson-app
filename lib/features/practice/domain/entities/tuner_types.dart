// Tuner domain types
// Core types for chromatic tuner with gamification
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

/// Musical note names (chromatic scale).
enum NoteName {
  C('C', 'C', false),
  Cs('C#', 'Db', true),
  D('D', 'D', false),
  Ds('D#', 'Eb', true),
  E('E', 'E', false),
  F('F', 'F', false),
  Fs('F#', 'Gb', true),
  G('G', 'G', false),
  Gs('G#', 'Ab', true),
  A('A', 'A', false),
  As('A#', 'Bb', true),
  B('B', 'B', false);

  const NoteName(this.sharpName, this.flatName, this.isAccidental);

  /// Name using sharp notation (C#, D#, etc.)
  final String sharpName;

  /// Name using flat notation (Db, Eb, etc.)
  final String flatName;

  /// Whether this is an accidental (black key on piano)
  final bool isAccidental;

  /// Get display name based on preference
  String displayName({bool preferFlat = false}) {
    if (!isAccidental) return sharpName;
    return preferFlat ? flatName : sharpName;
  }

  /// Get enharmonic display (C#/Db)
  String get enharmonicName {
    if (!isAccidental) return sharpName;
    return '$sharpName/$flatName';
  }

  /// Get semitone index (C=0, C#=1, ... B=11)
  int get semitoneIndex => index;

  /// Calculate frequency for a given octave and reference A4
  double frequency(int octave, {double referenceA4 = 440.0}) {
    // A4 = reference (default 440Hz)
    // Each semitone = 2^(1/12) ratio
    final a4Index = NoteName.A.semitoneIndex + 4 * 12; // A4's absolute index
    final noteIndex = semitoneIndex + octave * 12;
    final semitonesDiff = noteIndex - a4Index;
    return referenceA4 * math.pow(2, semitonesDiff / 12);
  }
}

/// Tuning status for the tuner.
enum TuningStatus {
  /// No sound detected
  idle('대기중', '소리를 들려주세요'),

  /// Listening but no clear pitch yet
  listening('감지중', '음을 찾는 중...'),

  /// Pitch detected and in tune (within perfect threshold)
  tuned('정확', '완벽해요!'),

  /// Pitch detected but flat (too low)
  flat('낮음', '조금 높여주세요'),

  /// Pitch detected but sharp (too high)
  sharp('높음', '조금 낮춰주세요');

  const TuningStatus(this.label, this.description);

  final String label;
  final String description;
}

/// Judgement result for gamification.
enum JudgementResult {
  /// Excellent tuning (within tight threshold)
  perfect('Perfect', '완벽해옹!', 0x9090EE90),

  /// Good tuning (within moderate threshold)
  good('Good', '좋아옹!', 0x90FFEB3B),

  /// Poor tuning (outside threshold)
  miss('Miss', '다시 해봐옹~', 0x909E9E9E);

  const JudgementResult(this.label, this.message, this.colorValue);

  final String label;
  final String message;
  final int colorValue;
}

/// Difficulty level for judgement thresholds.
enum TunerDifficulty {
  /// Beginner: generous thresholds
  beginner('초보', perfectCent: 15, goodCent: 30),

  /// Intermediate: moderate thresholds
  intermediate('중급', perfectCent: 10, goodCent: 20),

  /// Advanced: strict thresholds
  advanced('고급', perfectCent: 5, goodCent: 10);

  const TunerDifficulty(
    this.label, {
    required this.perfectCent,
    required this.goodCent,
  });

  final String label;

  /// Maximum cent deviation for Perfect judgement
  final int perfectCent;

  /// Maximum cent deviation for Good judgement
  final int goodCent;

  /// Judge the cent deviation
  JudgementResult judge(double centDeviation) {
    final absCent = centDeviation.abs();
    if (absCent <= perfectCent) return JudgementResult.perfect;
    if (absCent <= goodCent) return JudgementResult.good;
    return JudgementResult.miss;
  }
}

/// Transposition setting for wind instruments.
enum Transposition {
  /// Concert pitch (C instruments: piano, violin, flute)
  c('C', '실음', 0),

  /// Bb instruments (clarinet, trumpet, soprano sax)
  bb('Bb', 'Bb관', -2),

  /// Eb instruments (alto sax, baritone sax)
  eb('Eb', 'Eb관', -9),

  /// F instruments (horn)
  f('F', 'F관', -7),

  /// A instruments (clarinet in A)
  a('A', 'A관', -3);

  const Transposition(this.label, this.description, this.semitoneOffset);

  final String label;
  final String description;

  /// Semitone offset from concert pitch
  final int semitoneOffset;

  /// Apply transposition to a note
  NoteName transpose(NoteName note) {
    final newIndex = (note.semitoneIndex + semitoneOffset) % 12;
    return NoteName.values[newIndex < 0 ? newIndex + 12 : newIndex];
  }
}

/// Detected musical note with pitch information.
class TunerNote {
  const TunerNote({
    required this.name,
    required this.octave,
    required this.frequency,
    required this.centDeviation,
  });

  /// The note name (C, C#, D, etc.)
  final NoteName name;

  /// The octave number (0-8, A4 = 440Hz by default)
  final int octave;

  /// The detected frequency in Hz
  final double frequency;

  /// Deviation from perfect pitch in cents (-50 to +50)
  final double centDeviation;

  /// Full note name with octave (e.g., "A4", "C#5")
  String get fullName => '${name.sharpName}$octave';

  /// Full note name with octave using flat notation
  String get fullNameFlat => '${name.flatName}$octave';

  /// Get tuning status based on cent deviation
  TuningStatus get status {
    if (centDeviation.abs() <= 5) return TuningStatus.tuned;
    if (centDeviation < 0) return TuningStatus.flat;
    return TuningStatus.sharp;
  }

  /// Get display string for cent deviation (e.g., "+5", "-10")
  String get centDisplayString {
    if (centDeviation >= 0) {
      return '+${centDeviation.toStringAsFixed(1)}';
    }
    return centDeviation.toStringAsFixed(1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TunerNote &&
        other.name == name &&
        other.octave == octave &&
        (other.frequency - frequency).abs() < 0.01 &&
        (other.centDeviation - centDeviation).abs() < 0.1;
  }

  @override
  int get hashCode => Object.hash(name, octave, frequency.round());

  @override
  String toString() =>
      'TunerNote($fullName, ${frequency.toStringAsFixed(1)}Hz, $centDisplayString¢)';
}

/// Current state of the tuner.
class TunerState {
  const TunerState({
    this.status = TuningStatus.idle,
    this.currentNote,
    this.isListening = false,
    this.lastJudgement,
  });

  /// Current tuning status
  final TuningStatus status;

  /// Currently detected note (null if none)
  final TunerNote? currentNote;

  /// Whether the tuner is actively listening
  final bool isListening;

  /// Last judgement result (for gamification)
  final JudgementResult? lastJudgement;

  /// Create a copy with modified values
  TunerState copyWith({
    TuningStatus? status,
    TunerNote? currentNote,
    bool? isListening,
    JudgementResult? lastJudgement,
    bool clearNote = false,
    bool clearJudgement = false,
  }) {
    return TunerState(
      status: status ?? this.status,
      currentNote: clearNote ? null : (currentNote ?? this.currentNote),
      isListening: isListening ?? this.isListening,
      lastJudgement:
          clearJudgement ? null : (lastJudgement ?? this.lastJudgement),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TunerState &&
        other.status == status &&
        other.currentNote == currentNote &&
        other.isListening == isListening &&
        other.lastJudgement == lastJudgement;
  }

  @override
  int get hashCode => Object.hash(status, currentNote, isListening);
}

/// Utility functions for pitch calculations.
class PitchUtils {
  PitchUtils._();

  /// Standard A4 frequency
  static const double standardA4 = 440.0;

  /// Calculate the note and octave from a frequency.
  static TunerNote? frequencyToNote(
    double frequency, {
    double referenceA4 = standardA4,
  }) {
    if (frequency <= 0 || frequency < 20 || frequency > 20000) {
      return null;
    }

    // Calculate semitones from A4
    final semitones = 12 * (math.log(frequency / referenceA4) / math.ln2);
    final roundedSemitones = semitones.round();

    // Calculate octave and note index
    // A4 is note index 9 (A) in octave 4
    final totalSemitones = roundedSemitones + 9 + (4 * 12);
    final octave = totalSemitones ~/ 12;
    final noteIndex = totalSemitones % 12;

    // Calculate cent deviation
    final exactFrequency =
        referenceA4 * math.pow(2, roundedSemitones / 12);
    final centDeviation = 1200 * (math.log(frequency / exactFrequency) / math.ln2);

    // Clamp to valid range
    if (octave < 0 || octave > 8) return null;

    return TunerNote(
      name: NoteName.values[noteIndex],
      octave: octave,
      frequency: frequency,
      centDeviation: centDeviation.clamp(-50.0, 50.0),
    );
  }

  /// Calculate the expected frequency for a note.
  static double noteToFrequency(
    NoteName note,
    int octave, {
    double referenceA4 = standardA4,
  }) {
    return note.frequency(octave, referenceA4: referenceA4);
  }
}
