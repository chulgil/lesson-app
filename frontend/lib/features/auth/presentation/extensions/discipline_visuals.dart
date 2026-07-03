import '../../../../core/domain/value_objects/discipline.dart';
import '../../../../core/l10n/app_strings.dart';

/// Presentation resolution of a [Discipline]'s display name (#977).
///
/// Maps the pure-domain [Discipline.displayKey] to an AppStrings label at the
/// presentation boundary (domain stays string-free). Music + fitness + language
/// arms today (#1102). A later phase supersedes this with the design's
/// StringOverlay / a shared
/// discipline presentation layer once more disciplines (and a theme-color
/// resolver) exist; the sole consumer is DisciplineSelectionScreen.
extension DisciplineVisuals on Discipline {
  String get displayName {
    switch (displayKey) {
      case 'discipline.music':
        return AppStrings.disciplineMusic;
      case 'discipline.fitness':
        return AppStrings.disciplineFitness;
      case 'discipline.language':
        return AppStrings.disciplineLanguage;
      default:
        // Unknown key degrades to music (= DisciplineRegistry.fallback) rather
        // than surface a raw key.
        return AppStrings.disciplineMusic;
    }
  }
}
