import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/vocab_set.dart';
import '../../domain/scheduler/due_policy.dart';
import 'vocab_repository_provider.dart';

part 'vocab_sets_provider.g.dart';

/// The current user's vocabulary sets, oldest first (#1124).
@riverpod
Future<List<VocabSet>> vocabSets(VocabSetsRef ref) {
  final repo = ref.watch(vocabRepositoryProvider);
  return repo.getSets();
}

/// A one-line rollup for the practice-tool panel: how many sets exist and how
/// many cards are due for review right now across all of them (#1124).
class VocabSummary {
  final int setCount;
  final int dueCount;

  const VocabSummary({required this.setCount, required this.dueCount});
}

/// Aggregate [VocabSummary] over every set (#1124). Recomputed on demand; the
/// panel autoDisposes it when the practice modal closes.
@riverpod
Future<VocabSummary> vocabSummary(VocabSummaryRef ref) async {
  final repo = ref.watch(vocabRepositoryProvider);
  final sets = await repo.getSets();
  final now = DateTime.now();
  var due = 0;
  for (final set in sets) {
    final cards = await repo.getCards(set.id);
    due += cards.where((c) => isCardDue(c, now)).length;
  }
  return VocabSummary(setCount: sets.length, dueCount: due);
}
