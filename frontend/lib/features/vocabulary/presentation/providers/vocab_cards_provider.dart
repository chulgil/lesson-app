import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/vocab_card.dart';
import '../../domain/scheduler/due_policy.dart';
import 'vocab_repository_provider.dart';

part 'vocab_cards_provider.g.dart';

/// All cards in set [setId], oldest first (#1124).
@riverpod
Future<List<VocabCard>> vocabCards(VocabCardsRef ref, String setId) {
  final repo = ref.watch(vocabRepositoryProvider);
  return repo.getCards(setId);
}

/// The due-for-review queue for a review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set (the set page's session). Ordered by due date
/// (most overdue first) so the earliest-due cards are seen first.
@riverpod
Future<List<VocabCard>> dueCards(DueCardsRef ref, String? setId) async {
  final repo = ref.watch(vocabRepositoryProvider);
  final now = DateTime.now();

  final List<VocabCard> pool;
  if (setId != null) {
    pool = await repo.getCards(setId);
  } else {
    pool = <VocabCard>[];
    for (final set in await repo.getSets()) {
      pool.addAll(await repo.getCards(set.id));
    }
  }

  return pool.where((c) => isCardDue(c, now)).toList()
    ..sort((a, b) => a.reviewState.dueDate.compareTo(b.reviewState.dueDate));
}
