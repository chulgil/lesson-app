/// The spaced-repetition scheduling state of a single vocabulary card (#1124).
///
/// Immutable value object carrying the SuperMemo-2 variables ([easeFactor],
/// [repetitions], [intervalDays]) plus the derived [dueDate]. A freshly created
/// card is due immediately ([CardReviewState.initial]). [Sm2Scheduler] consumes
/// this with a [ReviewGrade] to produce the next state.
class CardReviewState {
  /// SM-2 ease factor — the interval multiplier for mature cards. Starts at 2.5,
  /// floored at 1.3 by the scheduler.
  final double easeFactor;

  /// Consecutive successful recalls since the last lapse (0 after an `again`).
  final int repetitions;

  /// Current inter-review interval in days (0 before the first review).
  final int intervalDays;

  /// When the card next becomes due for review.
  final DateTime dueDate;

  /// When the card was last reviewed; null before the first review.
  final DateTime? lastReviewedAt;

  const CardReviewState({
    required this.easeFactor,
    required this.repetitions,
    required this.intervalDays,
    required this.dueDate,
    this.lastReviewedAt,
  });

  /// A brand-new card: default ease 2.5, no reviews yet, due immediately at
  /// [createdAt].
  factory CardReviewState.initial(DateTime createdAt) => CardReviewState(
    easeFactor: 2.5,
    repetitions: 0,
    intervalDays: 0,
    dueDate: createdAt,
    lastReviewedAt: null,
  );

  CardReviewState copyWith({
    double? easeFactor,
    int? repetitions,
    int? intervalDays,
    DateTime? dueDate,
    DateTime? lastReviewedAt,
  }) => CardReviewState(
    easeFactor: easeFactor ?? this.easeFactor,
    repetitions: repetitions ?? this.repetitions,
    intervalDays: intervalDays ?? this.intervalDays,
    dueDate: dueDate ?? this.dueDate,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );

  Map<String, dynamic> toJson() => {
    'easeFactor': easeFactor,
    'repetitions': repetitions,
    'intervalDays': intervalDays,
    'dueDate': dueDate.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };

  factory CardReviewState.fromJson(Map<String, dynamic> json) => CardReviewState(
    easeFactor: (json['easeFactor'] as num).toDouble(),
    repetitions: json['repetitions'] as int,
    intervalDays: json['intervalDays'] as int,
    dueDate: DateTime.parse(json['dueDate'] as String),
    lastReviewedAt: json['lastReviewedAt'] == null
        ? null
        : DateTime.parse(json['lastReviewedAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardReviewState &&
          runtimeType == other.runtimeType &&
          easeFactor == other.easeFactor &&
          repetitions == other.repetitions &&
          intervalDays == other.intervalDays &&
          dueDate == other.dueDate &&
          lastReviewedAt == other.lastReviewedAt;

  @override
  int get hashCode => Object.hash(
    easeFactor,
    repetitions,
    intervalDays,
    dueDate,
    lastReviewedAt,
  );
}
