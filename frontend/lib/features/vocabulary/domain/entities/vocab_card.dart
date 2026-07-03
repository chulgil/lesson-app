import 'card_review_state.dart';

/// A single flashcard: a word/phrase ([front]) and its meaning ([back]) plus
/// optional [example] and [memo], carrying its own SM-2 [reviewState] (#1124).
///
/// Immutable value object. The [reviewState] is embedded (not stored apart) so a
/// card and its scheduling always move together; grading a card produces a new
/// [VocabCard] via [copyWith] with the scheduler's next state.
class VocabCard {
  /// Stable local identifier (generated at creation). Not user-facing.
  final String id;

  /// Id of the owning [VocabSet].
  final String setId;

  /// The prompt side — the word/phrase being learned.
  final String front;

  /// The answer side — its meaning.
  final String back;

  /// Optional example sentence shown with the answer.
  final String? example;

  /// Optional freeform note shown with the answer.
  final String? memo;

  /// When the learner added this card.
  final DateTime createdAt;

  /// Spaced-repetition scheduling state for this card.
  final CardReviewState reviewState;

  const VocabCard({
    required this.id,
    required this.setId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.reviewState,
    this.example,
    this.memo,
  });

  /// A brand-new card: its [reviewState] starts due immediately at [createdAt]
  /// ([CardReviewState.initial]), so it enters the first review session.
  factory VocabCard.create({
    required String id,
    required String setId,
    required String front,
    required String back,
    required DateTime createdAt,
    String? example,
    String? memo,
  }) => VocabCard(
    id: id,
    setId: setId,
    front: front,
    back: back,
    example: example,
    memo: memo,
    createdAt: createdAt,
    reviewState: CardReviewState.initial(createdAt),
  );

  VocabCard copyWith({
    String? id,
    String? setId,
    String? front,
    String? back,
    String? example,
    String? memo,
    DateTime? createdAt,
    CardReviewState? reviewState,
  }) => VocabCard(
    id: id ?? this.id,
    setId: setId ?? this.setId,
    front: front ?? this.front,
    back: back ?? this.back,
    example: example ?? this.example,
    memo: memo ?? this.memo,
    createdAt: createdAt ?? this.createdAt,
    reviewState: reviewState ?? this.reviewState,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'setId': setId,
    'front': front,
    'back': back,
    'example': example,
    'memo': memo,
    'createdAt': createdAt.toIso8601String(),
    'reviewState': reviewState.toJson(),
  };

  factory VocabCard.fromJson(Map<String, dynamic> json) => VocabCard(
    id: json['id'] as String,
    setId: json['setId'] as String,
    front: json['front'] as String,
    back: json['back'] as String,
    example: json['example'] as String?,
    memo: json['memo'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reviewState: CardReviewState.fromJson(
      json['reviewState'] as Map<String, dynamic>,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          setId == other.setId &&
          front == other.front &&
          back == other.back &&
          example == other.example &&
          memo == other.memo &&
          createdAt == other.createdAt &&
          reviewState == other.reviewState;

  @override
  int get hashCode => Object.hash(
    id,
    setId,
    front,
    back,
    example,
    memo,
    createdAt,
    reviewState,
  );
}
