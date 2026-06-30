// Discipline-neutral repeat-target view over a PracticeSection's N회 반복 field
// (#970, Phase 2). Additive: derives a [RepeatTarget] from the existing
// repeatCount — no field, serialization, or consumer change, music behaviour
// unchanged. dailyRepeatCounts (per-day progress) is out of scope here.

import '../../../../core/domain/value_objects/repeat_target.dart';
import 'practice_repertoire.dart';

extension PracticeSectionRepeatTarget on PracticeSection {
  /// The section's repeat target as a discipline-neutral [RepeatTarget].
  ///
  /// Music is single-axis: [RepeatTarget.primary] is the times-per-day count and
  /// [RepeatTarget.secondary] is always null. A section with N회 반복 enabled
  /// (`hasRepeatCount`, i.e. repeatCount >= 2) maps to that count; a section
  /// without it maps to a single repetition (practice once) — the faithful "off"
  /// state, since every section is practiced at least once.
  RepeatTarget get repeatTarget =>
      RepeatTarget.single(hasRepeatCount ? repeatCount! : 1);
}
