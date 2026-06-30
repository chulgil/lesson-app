import '../../../../core/domain/value_objects/discipline.dart';
import '../../../../core/l10n/app_strings.dart';

/// Presentation resolution of a [Discipline]'s display name (#977).
///
/// Phase-3 stub: maps the pure-domain [Discipline.displayKey] to an AppStrings
/// label at the presentation boundary (domain stays string-free). Only music is
/// registered today, so the switch has a single arm. Phase 4 supersedes this
/// with the design's StringOverlay / a shared discipline presentation layer once
/// multiple disciplines (and a theme-color resolver) exist; until then the sole
/// consumer is DisciplineSelectionScreen.
extension DisciplineVisuals on Discipline {
  String get displayName {
    switch (displayKey) {
      case 'discipline.music':
        return AppStrings.disciplineMusic;
      default:
        // Registry is closed to music today; degrade to it (= DisciplineRegistry
        // .fallback) rather than surface a raw key.
        return AppStrings.disciplineMusic;
    }
  }
}
