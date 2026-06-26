/// A catalog of **expertise tags** for a coaching discipline — the
/// within-discipline specializations a teacher can claim (music='instruments',
/// fitness='specialties', language='subjects').
///
/// First-class abstraction for the multi-Discipline platform (#964, design doc
/// "36-멀티카테고리-Discipline-플랫폼-설계"). Pointed at by
/// `Discipline.expertiseCatalogId`; resolved via `ExpertiseCatalogRegistry`.
/// The music catalog (id 'instruments') is the SSOT for the instrument names —
/// `InstrumentList.all` delegates to it.
///
/// Pure value object — no Flutter / serialization deps.
class ExpertiseCatalog {
  /// Stable identifier, matches `Discipline.expertiseCatalogId`:
  /// 'instruments' | 'specialties' | 'subjects' ...
  final String id;

  /// The selectable expertise tags for this catalog, in display order.
  final List<String> items;

  const ExpertiseCatalog({required this.id, required this.items});

  @override
  String toString() => 'ExpertiseCatalog($id, ${items.length} items)';
}
