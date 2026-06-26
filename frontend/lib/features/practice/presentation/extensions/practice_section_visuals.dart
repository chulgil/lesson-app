import '../../../../core/l10n/string_overlay.dart';
import '../../domain/entities/practice_repertoire.dart';

/// Display conversion for a [PracticeSection]'s practice range (#966). The
/// range *logic* (which unit applies) lives here in presentation; the
/// discipline-dependent *vocabulary* (마디·줄·전체) comes from the music
/// [StringOverlay] — mirroring how `AppStrings` delegates to
/// `StringOverlayRegistry.music` (#968). Other disciplines swap the vocabulary
/// by registering their own overlay.
extension PracticeSectionDisplay on PracticeSection {
  /// Range display string based on [rangeType] (e.g. "1~4 마디", "1~3줄", "전체").
  String get rangeText {
    final strings = StringOverlayRegistry.music.practiceSection;
    switch (rangeType) {
      case SectionRangeType.full:
        return strings.fullRangeLabel;
      case SectionRangeType.line:
        return (startLine != null && endLine != null)
            ? strings.lineRange(startLine!, endLine!)
            : '';
      case SectionRangeType.measure:
        return strings.measureRange(startMeasure, endMeasure);
    }
  }
}
