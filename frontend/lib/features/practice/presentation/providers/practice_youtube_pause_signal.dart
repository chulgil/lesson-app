import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §3.5 entry-point 5 — pause-signal stream consumed by
/// [PracticeYoutubePlayer] / [PracticeYoutubeMiniPlayer].
///
/// Producers (recording stop, result-sheet open) call
/// `ref.read(practiceYoutubePauseTickerProvider.notifier).state++`.
/// The player listens and pauses its iframe controller on every increment.
final practiceYoutubePauseTickerProvider = StateProvider<int>((ref) => 0);
