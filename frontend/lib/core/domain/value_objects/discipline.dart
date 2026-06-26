/// A coaching **discipline** (vertical) — music, fitness, language, etc.
///
/// First-class abstraction for the multi-Discipline platform (#962, design doc
/// "36-멀티카테고리-Discipline-플랫폼-설계"). Music is discipline 0; adding a
/// discipline = registering data in [DisciplineRegistry], no core code change.
///
/// NOTE — naming guard: distinct from "Category"/`SettingGroup` (the teacher
/// settings 5묶음, glossary §14). Never use "category" to mean a discipline.
///
/// Pure value object — no Flutter/theme/serialization deps. Display name and
/// theme color are resolved at the presentation boundary from [displayKey] /
/// [themeColorSeed] (later phases: StringOverlay, ExpertiseColorResolver).
class Discipline {
  /// Stable identifier: 'music' | 'fitness' | 'language' ...
  final String id;

  /// Key the presentation layer resolves to a localized display name.
  final String displayKey;

  /// ARGB seed (int) for the discipline's theme color. Presentation resolves.
  final int themeColorSeed;

  /// Identifier of the expertise catalog (music='instruments',
  /// fitness='specialties', language='subjects').
  final String expertiseCatalogId;

  const Discipline({
    required this.id,
    required this.displayKey,
    required this.themeColorSeed,
    required this.expertiseCatalogId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Discipline &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayKey == other.displayKey &&
          themeColorSeed == other.themeColorSeed &&
          expertiseCatalogId == other.expertiseCatalogId;

  @override
  int get hashCode =>
      Object.hash(id, displayKey, themeColorSeed, expertiseCatalogId);

  @override
  String toString() => 'Discipline($id)';
}
