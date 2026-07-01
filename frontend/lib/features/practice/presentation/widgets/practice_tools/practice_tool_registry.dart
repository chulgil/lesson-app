import '../../../../../core/domain/value_objects/discipline_registry.dart';
import 'fitness_practice_tools.dart';
import 'music_practice_tools.dart';
import 'practice_tool.dart';

/// Discipline-keyed practice-tool registry for the multi-Discipline platform
/// (#979-A, Phase 4). Mirrors [DisciplineRegistry] / `ProviderSearchFacetRegistry`
/// (#962 / #976): a discipline's practice tools are looked up by id — never
/// `enum switch`. Registering a discipline's tools is a single map entry with
/// zero change to the modal shell, so the music vertical stays byte-identical.
///
/// Presentation layer — [PracticeTool] carries Flutter widget builders, so this
/// must NOT move to `core/domain/value_objects/` (flutter-architecture layer
/// boundary), mirroring [PracticeTool]'s own placement.
class PracticeToolRegistry {
  const PracticeToolRegistry._();

  /// Music (discipline 0): metronome + tuner. A future discipline (Phase 4 /
  /// #979-B: fitness) registers its own tool list here as one map entry.
  static final Map<String, List<PracticeTool>> _byId = {
    DisciplineRegistry.music.id: musicPracticeTools,
    DisciplineRegistry.fitness.id: fitnessPracticeTools,
  };

  /// The tools registered for [disciplineId]; null if none registered.
  static List<PracticeTool>? byId(String disciplineId) => _byId[disciplineId];

  /// The tools for [disciplineId], falling back to the music tool set for
  /// null / legacy / unknown ids (mirrors [DisciplineRegistry.fallback]).
  static List<PracticeTool> forDiscipline(String disciplineId) =>
      _byId[disciplineId] ?? musicPracticeTools;

  /// All registered discipline ids (music, fitness) — #979-B.
  static Iterable<String> get registeredDisciplineIds => _byId.keys;
}
