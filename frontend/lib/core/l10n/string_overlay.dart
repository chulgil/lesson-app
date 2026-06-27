import '../domain/value_objects/discipline.dart';

/// Discipline-dependent UI strings for the metronome tool — the first slice of
/// the multi-Discipline string overlay (#968). Music values; other disciplines
/// register their own (or fall back to music).
class MetronomeStrings {
  final String timeSignaturePickerTitle;
  final String simpleTimeTitle;
  final String compoundTimeTitle;
  final String subdivisionPickerTitle;
  final String basicPatternTitle;
  final String variationTitle;
  final String optionsTitle;
  final String visualFlashLabel;
  final String vibrationLabel;

  const MetronomeStrings({
    required this.timeSignaturePickerTitle,
    required this.simpleTimeTitle,
    required this.compoundTimeTitle,
    required this.subdivisionPickerTitle,
    required this.basicPatternTitle,
    required this.variationTitle,
    required this.optionsTitle,
    required this.visualFlashLabel,
    required this.vibrationLabel,
  });
}

/// Discipline-dependent vocabulary for a practice section's range display
/// (#966). Music sections measure progress in 마디·줄; other disciplines name
/// their own units (e.g. 세트·회) by registering their own overlay.
class PracticeSectionStrings {
  /// Unit for a measure range (music: '마디').
  final String measureUnit;

  /// Unit for a line range (music: '줄').
  final String lineUnit;

  /// Label for a full-piece range (music: '전체').
  final String fullRangeLabel;

  const PracticeSectionStrings({
    required this.measureUnit,
    required this.lineUnit,
    required this.fullRangeLabel,
  });

  /// e.g. "1~4 마디" — preserves the legacy space before the unit.
  String measureRange(int start, int end) => '$start~$end $measureUnit';

  /// e.g. "1~3줄" — preserves the legacy no-space form.
  String lineRange(int start, int end) => '$start~$end$lineUnit';
}

/// Per-discipline bundle of **discipline-dependent** UI strings (악기·곡·연습·
/// 레퍼토리·메트로놈), separated from the shared core `AppStrings` (저장·확인·
/// 결제·스케줄) for the multi-Discipline platform (#968, design doc
/// "36-멀티카테고리-Discipline-플랫폼-설계").
///
/// The music overlay holds the current values, so `AppStrings` delegation keeps
/// regression 0. Grows incrementally — first slice = [metronome]; more clusters
/// migrate in follow-ups (한번에 금지: AppStrings is 465KB / format-churn-prone).
class StringOverlay {
  final String disciplineId;
  final MetronomeStrings metronome;
  final PracticeSectionStrings practiceSection;

  const StringOverlay({
    required this.disciplineId,
    required this.metronome,
    required this.practiceSection,
  });
}

/// SSOT registry of [StringOverlay]s keyed by `Discipline.id` (#968, mirrors
/// `ExpertiseCatalogRegistry` / `ExpertiseColorResolverRegistry`).
///
/// **Lookup by id — never `enum switch`.** Registering a discipline's overlay
/// is a data change here. `AppStrings` delegates its discipline-dependent
/// getters to [music].
class StringOverlayRegistry {
  const StringOverlayRegistry._();

  /// Music vertical overlay — current string values (SSOT for the migrated
  /// slice; `AppStrings` delegates here).
  static const StringOverlay music = StringOverlay(
    disciplineId: 'music',
    metronome: MetronomeStrings(
      timeSignaturePickerTitle: '박자표 선택',
      simpleTimeTitle: '단순 박자',
      compoundTimeTitle: '복합 박자',
      subdivisionPickerTitle: '서브디비전 선택',
      basicPatternTitle: '기본 패턴',
      variationTitle: '베리에이션 (쉼표 포함)',
      optionsTitle: '옵션',
      visualFlashLabel: '시각 플래시',
      vibrationLabel: '진동',
    ),
    practiceSection: PracticeSectionStrings(
      measureUnit: '마디',
      lineUnit: '줄',
      fullRangeLabel: '전체',
    ),
  );

  static const List<StringOverlay> _registered = [music];

  /// Resolve an overlay by discipline [id]; null if not registered.
  static StringOverlay? byId(String id) {
    for (final o in _registered) {
      if (o.disciplineId == id) return o;
    }
    return null;
  }

  /// The overlay for [discipline] (by its `id`), falling back to [fallback]
  /// (music) for unregistered ids.
  static StringOverlay forDiscipline(Discipline discipline) =>
      byId(discipline.id) ?? fallback;

  /// Fallback for null / unregistered disciplines (= music base).
  static const StringOverlay fallback = music;
}
