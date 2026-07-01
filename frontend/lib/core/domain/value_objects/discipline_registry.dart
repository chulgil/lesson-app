import 'discipline.dart';

/// SSOT registry of registered [Discipline]s (#962).
///
/// **Lookup by id — never `enum switch (discipline)`.** Adding a discipline is
/// a data registration here (+ its [DisciplineProfile] in later phases), with
/// zero change to core code, so the music vertical stays pixel-identical.
///
/// Music is registered as instance 0; [fallback] returns it for null/legacy
/// `disciplineId` (non-destructive migration — null = music).
class DisciplineRegistry {
  const DisciplineRegistry._();

  /// Discipline 0 — the existing music vertical. Theme seed = paperAccent
  /// (음악 액션색, 0xFF9B1B12). expertiseCatalog = instruments(악기).
  static const Discipline music = Discipline(
    id: 'music',
    displayKey: 'discipline.music',
    themeColorSeed: 0xFF9B1B12,
    expertiseCatalogId: 'instruments',
  );

  /// Fitness (헬스 / GX) discipline — Phase 4 (#979-B). The second registered
  /// vertical; adding it is pure data (this const + the append below), so the
  /// music vertical stays pixel-identical. expertiseCatalog = specialties
  /// (웨이트/필라테스/PT). themeColorSeed is provisional — no consumer reads it
  /// yet, and the fitness brand palette is a later design decision.
  static const Discipline fitness = Discipline(
    id: 'fitness',
    displayKey: 'discipline.fitness',
    themeColorSeed: 0xFF2E7D32,
    expertiseCatalogId: 'specialties',
  );

  /// All registered disciplines, in registration order (music first).
  /// Adding a vertical = append here (Phase 5+: language).
  static const List<Discipline> _registered = <Discipline>[music, fitness];

  static List<Discipline> get all => _registered;

  /// Resolve a discipline by [id]; null if not registered.
  static Discipline? byId(String id) {
    for (final d in _registered) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Fallback discipline for null / legacy / unknown ids (= music).
  static const Discipline fallback = music;
}
