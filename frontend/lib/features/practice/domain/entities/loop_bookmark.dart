/// Student-authored loop bookmark — a named A-B sub-range inside a
/// [PracticeLoopOverride].
///
/// A student can mark several tricky passages (intro / development / ending)
/// per video, then jump between them by selecting from the bookmark list.
/// Bookmarks are stored as part of [PracticeLoopOverride.bookmarks].
///
/// Spec: GH #511 — Multi marker loop bookmarks (§3.5 follow-up).
class LoopBookmark {
  /// Stable id (generated at creation). Used for update / delete / select
  /// addressing.
  final String id;

  /// Display name (UI enforces non-empty, falls back to a default when blank).
  final String name;

  /// Loop start position (seconds, integer).
  final int startSeconds;

  /// Loop end position (seconds, integer). Must be `> startSeconds`.
  final int endSeconds;

  /// Color slot index (0-based). The UI maps the index to one of the five
  /// notebook palette tones — students don't pick a color directly, the slot
  /// is assigned in insertion order to keep cognitive load minimal.
  final int colorIndex;

  const LoopBookmark({
    required this.id,
    required this.name,
    required this.startSeconds,
    required this.endSeconds,
    required this.colorIndex,
  });

  LoopBookmark copyWith({
    String? id,
    String? name,
    int? startSeconds,
    int? endSeconds,
    int? colorIndex,
  }) {
    return LoopBookmark(
      id: id ?? this.id,
      name: name ?? this.name,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'colorIndex': colorIndex,
  };

  static LoopBookmark fromJson(Map<String, dynamic> json) {
    return LoopBookmark(
      id: json['id'] as String,
      name: json['name'] as String,
      startSeconds: json['startSeconds'] as int,
      endSeconds: json['endSeconds'] as int,
      colorIndex: (json['colorIndex'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LoopBookmark &&
      other.id == id &&
      other.name == name &&
      other.startSeconds == startSeconds &&
      other.endSeconds == endSeconds &&
      other.colorIndex == colorIndex;

  @override
  int get hashCode =>
      Object.hash(id, name, startSeconds, endSeconds, colorIndex);
}
