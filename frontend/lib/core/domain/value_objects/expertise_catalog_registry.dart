import 'discipline.dart';
import 'expertise_catalog.dart';

/// SSOT registry of [ExpertiseCatalog]s, keyed by `Discipline.expertiseCatalogId`
/// (#964).
///
/// **Lookup by id — never `enum switch`.** Adding a discipline's catalog is a
/// data registration here, with zero core-code change (mirrors
/// `DisciplineRegistry`). The music catalog (id 'instruments') is the SSOT for
/// instrument names: `InstrumentList.all` delegates to [music] `.items`.
class ExpertiseCatalogRegistry {
  const ExpertiseCatalogRegistry._();

  /// Music vertical catalog — the instrument list. SSOT for instrument names.
  static const ExpertiseCatalog music = ExpertiseCatalog(
    id: 'instruments',
    items: <String>[
      '바이올린',
      '비올라',
      '첼로',
      '콘트라베이스',
      '피아노',
      '플루트',
      '클라리넷',
      '오보에',
      '바순',
      '호른',
      '트럼펫',
      '트롬본',
      '튜바',
      '타악기',
      '하프',
      '기타',
      '성악',
      '작곡/이론',
    ],
  );

  /// All registered catalogs, in registration order (music first).
  static const List<ExpertiseCatalog> _registered = <ExpertiseCatalog>[music];

  static List<ExpertiseCatalog> get all => _registered;

  /// Resolve a catalog by [id]; null if not registered.
  static ExpertiseCatalog? byId(String id) {
    for (final c in _registered) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The catalog for [discipline] (via its `expertiseCatalogId`), falling back
  /// to [fallback] (music) for unregistered ids.
  static ExpertiseCatalog forDiscipline(Discipline discipline) =>
      byId(discipline.expertiseCatalogId) ?? fallback;

  /// Fallback catalog for null / legacy / unknown ids (= music instruments).
  static const ExpertiseCatalog fallback = music;
}
