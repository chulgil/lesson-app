// Discipline-neutral range view over a PracticeSection's music range fields
// (#969, Phase 2). Additive: derives a [RangeSpec] from the existing
// rangeType/startMeasure/endMeasure/startLine/endLine — no field, serialization,
// or consumer change, music behaviour unchanged.

import '../../../../core/domain/value_objects/range_spec.dart';
import 'practice_repertoire.dart';

extension PracticeSectionRange on PracticeSection {
  /// The section's practice range as a discipline-neutral [RangeSpec].
  ///
  /// Maps the music storage onto the abstraction: full -> [WholeRange],
  /// measure -> [RangeSpec.measures], line -> [RangeSpec.lines]. A line section
  /// with missing bounds (malformed legacy data) degrades to [WholeRange] as a
  /// safe, non-throwing fallback; the legacy `PracticeSectionDisplay.rangeText`
  /// renders the same case as an empty string.
  RangeSpec get range {
    switch (rangeType) {
      case SectionRangeType.full:
        return const RangeSpec.whole();
      case SectionRangeType.line:
        if (startLine != null && endLine != null) {
          return RangeSpec.lines(startLine!, endLine!);
        }
        return const RangeSpec.whole();
      case SectionRangeType.measure:
        return RangeSpec.measures(startMeasure, endMeasure);
    }
  }
}
