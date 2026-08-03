// Effort-source value object for the multi-Discipline platform (#971, Phase 2,
// design doc "36-멀티카테고리-Discipline-플랫폼-설계" §6.3). Pure domain — no
// Flutter/serialization/presentation deps. Names the kind of activity that
// produced a unit of practice effort, decoupled from the practice feature's own
// PracticeSource so the discipline-neutral effort/heatmap model can reference it
// without importing features/practice. The members are music's (discipline 0)
// five sources; a future fitness Discipline (Phase 4, #979) supplies its own
// source -> field injection (see EffortSourceDailyPractice.toDailyPractice).
// Music is discipline 0.
enum EffortSource { metronome, tuner, youtube, recording, manual }
