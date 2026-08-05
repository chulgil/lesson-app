// Discipline-neutral effort-source view over a PracticeEvidence's music
// PracticeSource (#971, Phase 2). Additive: maps the existing five-way music
// source onto the core [EffortSource] seam — no field, serialization, or
// consumer change, music behaviour unchanged. The mapping is 1:1 (music is
// discipline 0); a future Discipline would supply its own source set.
import '../../../../core/domain/value_objects/effort_source.dart';
import 'practice_evidence.dart';

extension PracticeSourceEffort on PracticeSource {
  EffortSource get effortSource => switch (this) {
    PracticeSource.metronome => EffortSource.metronome,
    PracticeSource.tuner => EffortSource.tuner,
    PracticeSource.youtube => EffortSource.youtube,
    PracticeSource.recording => EffortSource.recording,
    PracticeSource.manual => EffortSource.manual,
  };
}
