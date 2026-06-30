import '../repositories/teacher_search_repository.dart';

// Discipline-keyed teacher-search facet registry for the multi-Discipline platform
// (#976, Phase 3, design doc "36-멀티카테고리-Discipline-플랫폼-설계" §3 계층2 / U6).
//
// Pure domain — references only the [TeacherSearchRepository] interface (no Riverpod
// Ref, no presentation). Names how each discipline's search facet (the dynamic
// filter dimension — music: instruments, fitness: 종목, language: 과목) resolves its
// available values from the repository. Music is discipline 0; a future Discipline
// (Phase 4) registers its own facet here without touching the search providers.

/// Resolves the available values for one search facet from the [repo].
typedef ProviderSearchFacetResolver =
    Future<List<String>> Function(TeacherSearchRepository repo);

/// SSOT registry of discipline-keyed search facets, looked up by facet id
/// (= `Discipline.expertiseCatalogId`).
///
/// **Lookup by id — never `enum switch`.** Adding a discipline's facet is a data
/// registration here, with zero change to the search providers, so the music
/// vertical stays byte-identical.
class ProviderSearchFacetRegistry {
  const ProviderSearchFacetRegistry._();

  /// Music (discipline 0): the `instruments` facet resolves to the repository's
  /// teacher-scan instruments list — byte-identical to the pre-#976
  /// `availableInstruments` provider.
  static final Map<String, ProviderSearchFacetResolver> _byId = {
    'instruments': (repo) => repo.getAvailableInstruments(),
  };

  /// Resolve a facet by [facetId]; null if no discipline registers it.
  static ProviderSearchFacetResolver? byId(String facetId) => _byId[facetId];

  /// All registered facet ids (music: `instruments`).
  static Iterable<String> get registeredFacetIds => _byId.keys;
}
