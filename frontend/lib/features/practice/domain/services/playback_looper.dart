/// Pure playback loop algorithm — decides whether to seek, trigger count-in, or
/// mark completion based on the current playhead position.
///
/// No I/O, no Flutter dependency. Tested in isolation.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.6
class PlaybackLooper {
  /// Loop start seconds (inclusive).
  final int startSeconds;

  /// Loop end seconds (exclusive).
  final int endSeconds;

  /// Target number of repetitions. Loop completes once [completedCount] reaches this.
  final int targetRepeatCount;

  /// Whether loop mode is enabled. When false, video plays through naturally.
  final bool loopEnabled;

  /// When true, trigger a count-in before seeking back to [startSeconds].
  final bool countInEnabled;

  /// Margin in seconds — playhead reaching `endSeconds - margin` triggers seek-back.
  /// YouTube iframe seekTo has ~1s accuracy; use 0 by default for integer-second markers.
  final double endMarginSeconds;

  const PlaybackLooper({
    required this.startSeconds,
    required this.endSeconds,
    required this.targetRepeatCount,
    required this.loopEnabled,
    required this.countInEnabled,
    this.endMarginSeconds = 0.1,
  }) : assert(startSeconds >= 0),
       assert(endSeconds > startSeconds),
       assert(targetRepeatCount >= 1);

  /// Decision based on the current [positionSeconds] and how many loops have completed.
  PlaybackLoopDecision evaluate({
    required double positionSeconds,
    required int completedCount,
  }) {
    if (!loopEnabled) {
      return const PlaybackLoopDecision(
        action: PlaybackLoopAction.continuePlaying,
      );
    }

    if (positionSeconds < (endSeconds - endMarginSeconds)) {
      return const PlaybackLoopDecision(
        action: PlaybackLoopAction.continuePlaying,
      );
    }

    // Reached end of loop section.
    final nextCount = completedCount + 1;

    if (nextCount >= targetRepeatCount) {
      return PlaybackLoopDecision(
        action: PlaybackLoopAction.completeTarget,
        nextCompletedCount: nextCount,
      );
    }

    if (countInEnabled) {
      return PlaybackLoopDecision(
        action: PlaybackLoopAction.countInThenSeekBack,
        nextCompletedCount: nextCount,
        seekToSeconds: startSeconds,
      );
    }

    return PlaybackLoopDecision(
      action: PlaybackLoopAction.seekBack,
      nextCompletedCount: nextCount,
      seekToSeconds: startSeconds,
    );
  }

  /// First-play decision: when student taps play, should we count-in first?
  PlaybackLoopDecision evaluateFirstPlay() {
    if (countInEnabled) {
      return PlaybackLoopDecision(
        action: PlaybackLoopAction.countInThenPlay,
        seekToSeconds: startSeconds,
      );
    }
    return PlaybackLoopDecision(
      action: PlaybackLoopAction.seekBack,
      seekToSeconds: startSeconds,
    );
  }
}

/// Action the player should take given the current state.
enum PlaybackLoopAction {
  /// Keep playing — no intervention.
  continuePlaying,

  /// Seek back to loop start and resume.
  seekBack,

  /// Run count-in (3-2-1) then seek back to loop start.
  countInThenSeekBack,

  /// Run count-in (3-2-1) then start play from loop start.
  countInThenPlay,

  /// Target reached — stop and notify.
  completeTarget,
}

class PlaybackLoopDecision {
  final PlaybackLoopAction action;
  final int? nextCompletedCount;
  final int? seekToSeconds;

  const PlaybackLoopDecision({
    required this.action,
    this.nextCompletedCount,
    this.seekToSeconds,
  });
}
