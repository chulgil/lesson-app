/// Student-authored loop memo at a specific timestamp inside a
/// [PracticeLoopOverride].
///
/// Free-form annotation for tricky passages — displayed as a brief overlay
/// when playback reaches [atSeconds]. Maximum 100 characters; rendered in
/// Gaegu (Tier 1 hand) to feel like a margin note.
///
/// Spec: GH #510 — Loop Memo
/// Refs: §3.5 follow-up for #506 YouTube loop practice.
class LoopMemo {
  /// Stable id (generated at creation). Used for update/delete addressing.
  final String id;

  /// Playback position (seconds, integer) when this memo should appear.
  final int atSeconds;

  /// Memo text. UI enforces <= 100 chars.
  final String text;

  /// Creation timestamp — used for ordering and audit.
  final DateTime createdAt;

  const LoopMemo({
    required this.id,
    required this.atSeconds,
    required this.text,
    required this.createdAt,
  });

  LoopMemo copyWith({
    String? id,
    int? atSeconds,
    String? text,
    DateTime? createdAt,
  }) {
    return LoopMemo(
      id: id ?? this.id,
      atSeconds: atSeconds ?? this.atSeconds,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'atSeconds': atSeconds,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  static LoopMemo fromJson(Map<String, dynamic> json) {
    return LoopMemo(
      id: json['id'] as String,
      atSeconds: json['atSeconds'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LoopMemo &&
      other.id == id &&
      other.atSeconds == atSeconds &&
      other.text == text &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, atSeconds, text, createdAt);
}
