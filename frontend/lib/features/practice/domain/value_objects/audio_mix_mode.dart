/// Audio mix mode for YouTube + recording + metronome combinations.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §3.3
///
/// Pure domain enum — no display/string concerns. Display labels live in
/// `presentation/extensions/audio_mix_visuals.dart`.
enum AudioMixMode {
  /// Video only, no recording.
  videoOnly,

  /// Recording only — video is paused.
  recordOnly,

  /// Video + microphone recording at the same time (user intent).
  mixed,

  /// Video volume set to 0 (visual only) + recording.
  videoMuted,

  /// Headphones required — video + recording, sound routed to headphones.
  headphoneOnly,

  /// Video + metronome + recording (3-way mix, user responsibility).
  metronomeMixed,
}
