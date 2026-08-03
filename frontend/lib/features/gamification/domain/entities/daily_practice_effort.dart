// Maps a core [EffortSource] onto the single DailyPractice field it feeds, for
// music (discipline 0) (#971, Phase 2). Additive: extracts the previously
// hardcoded PracticeRecordingService switch into a declarative, discipline-
// overridable injector that lives with the DailyPractice payload it produces —
// music output byte-identical. Minute sources accumulate [amount] minutes;
// recording accumulates one occurrence and ignores [amount]. A future fitness
// Discipline (Phase 4, #979) supplies its own injector over its own payload.
import '../../../../core/domain/value_objects/effort_source.dart';
import 'daily_practice.dart';

extension EffortSourceDailyPractice on EffortSource {
  DailyPractice toDailyPractice(int amount) => switch (this) {
    EffortSource.metronome => DailyPractice(metronomeMinutes: amount),
    EffortSource.tuner => DailyPractice(tunerMinutes: amount),
    EffortSource.youtube => DailyPractice(youtubeMinutes: amount),
    EffortSource.manual => DailyPractice(manualMinutes: amount),
    EffortSource.recording => const DailyPractice(recordingCount: 1),
  };
}
