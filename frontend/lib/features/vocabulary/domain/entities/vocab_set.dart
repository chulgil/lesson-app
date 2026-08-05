/// A named collection of vocabulary cards the learner reviews together (#1124).
///
/// The organizational unit of the vocabulary tool: a learner keeps several sets
/// (e.g. "HSK4", "TOEIC 800") and reviews each independently. Immutable value
/// object; cards live separately (keyed by [VocabSet.id]) rather than embedded,
/// so a card review never rewrites the whole set.
class VocabSet {
  /// Stable local identifier (generated at creation). Not user-facing.
  final String id;

  /// User-facing set name shown in the list and review header.
  final String title;

  /// When the learner created this set (used for stable ordering).
  final DateTime createdAt;

  const VocabSet({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  VocabSet copyWith({String? id, String? title, DateTime? createdAt}) =>
      VocabSet(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VocabSet.fromJson(Map<String, dynamic> json) => VocabSet(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, title, createdAt);
}
