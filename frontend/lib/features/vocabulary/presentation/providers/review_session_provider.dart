import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/review_grade.dart';
import '../../domain/entities/vocab_card.dart';
import '../../domain/scheduler/sm2_scheduler.dart';
import 'vocab_cards_provider.dart';
import 'vocab_repository_provider.dart';
import 'vocab_sets_provider.dart';

part 'review_session_provider.g.dart';

/// Snapshot state of one flashcard review session (#1124).
///
/// [queue] is fixed when the session starts; [index] walks forward as cards are
/// graded. A lapse (`again`) reschedules the card to the next calendar day, so
/// it leaves today's queue rather than reappearing — the queue is a single pass.
class ReviewSessionState {
  final List<VocabCard> queue;
  final int index;

  const ReviewSessionState({required this.queue, required this.index});

  bool get isDone => index >= queue.length;
  VocabCard? get current => isDone ? null : queue[index];
  int get total => queue.length;
  int get completed => index;
  int get remaining => queue.length - index;

  ReviewSessionState copyWith({int? index}) =>
      ReviewSessionState(queue: queue, index: index ?? this.index);
}

/// Drives a flashcard review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set. The due queue is read **once** at [build] (a
/// snapshot, not a live watch), so persisting each grade never resets the
/// session. On the final grade it refreshes the library's due counts.
@riverpod
class ReviewSession extends _$ReviewSession {
  static const _scheduler = Sm2Scheduler();

  /// Guards the async grade→persist window. Card state and index are read before
  /// the `await saveCard`, so a second tap arriving during that window would read
  /// the same index and card and grade the same card twice (last-write-wins on a
  /// non-atomic store) — silently dropping the learner's real grade. This flag
  /// drops the re-entrant call instead of processing it.
  bool _grading = false;

  @override
  Future<ReviewSessionState> build(String? setId) async {
    final queue = await ref.read(dueCardsProvider(setId).future);
    return ReviewSessionState(queue: List.unmodifiable(queue), index: 0);
  }

  /// Grade the current card: compute its next SM-2 state, persist it, advance.
  Future<void> grade(ReviewGrade grade) async {
    final current = state.valueOrNull;
    if (_grading || current == null || current.isDone) return;
    _grading = true;
    try {
      final card = current.queue[current.index];
      final nextState = _scheduler.review(
        card.reviewState,
        grade,
        DateTime.now(),
      );
      await ref
          .read(vocabRepositoryProvider)
          .saveCard(card.copyWith(reviewState: nextState));

      final nextIndex = current.index + 1;
      state = AsyncData(current.copyWith(index: nextIndex));

      if (nextIndex >= current.queue.length) {
        _refreshLibrary(setId);
      }
    } finally {
      _grading = false;
    }
  }

  /// Invalidate the read-side providers so due badges and card states update
  /// once the session ends (write → read invalidation). The session itself only
  /// *read* the due queue, so this never rebuilds/resets it.
  void _refreshLibrary(String? setId) {
    ref.invalidate(vocabSummaryProvider);
    ref.invalidate(vocabSetsProvider);
    ref.invalidate(dueCardsProvider(setId));
    if (setId != null) ref.invalidate(vocabCardsProvider(setId));
  }
}
