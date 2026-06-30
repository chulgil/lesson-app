// Practice repeat-target value object for the multi-Discipline platform (#970,
// Phase 2, design doc "36-멀티카테고리-Discipline-플랫폼-설계" §2/§5.1).
//
// Pure domain — no Flutter/serialization/presentation deps. "How many times" to
// repeat a practice unit. Music is single-axis (times per day); fitness (Phase 4,
// #979) adds a second axis (sets x reps) via [RepeatTarget.setsReps] without
// restructuring. Music is discipline 0.

/// "How much to repeat" — a discipline-neutral repeat target (#970).
///
/// [primary] is the main repeat axis (music: times-per-day; fitness: sets).
/// [secondary] is an optional second axis — null for single-axis disciplines
/// like music, non-null for fitness (reps-per-set, Phase 4 #979).
class RepeatTarget {
  /// Main repeat axis (music: times-per-day; fitness: sets). The music view
  /// (PracticeSection.repeatTarget) always emits >= 1.
  final int primary;

  /// Optional second axis (fitness reps-per-set). Null for single-axis (music).
  final int? secondary;

  const RepeatTarget._({required this.primary, this.secondary});

  /// Single-axis target: repeat [times] (music times-per-day).
  factory RepeatTarget.single(int times) => RepeatTarget._(primary: times);

  /// Two-axis target: [sets] x [reps] (fitness, Phase 4 #979). Skeleton only —
  /// no discipline registers it yet.
  factory RepeatTarget.setsReps(int sets, int reps) =>
      RepeatTarget._(primary: sets, secondary: reps);

  /// True when this is a single-axis target (no [secondary]) — the music case.
  bool get isSingleAxis => secondary == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTarget &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          secondary == other.secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() =>
      secondary == null
          ? 'RepeatTarget($primary)'
          : 'RepeatTarget($primary x $secondary)';
}
