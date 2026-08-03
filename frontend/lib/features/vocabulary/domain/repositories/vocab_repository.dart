import '../entities/vocab_card.dart';
import '../entities/vocab_set.dart';

/// Persistence boundary for the vocabulary tool (#1124).
///
/// The first slice ships a local-first Hive implementation
/// ([LocalVocabRepository]); there is deliberately no remote yet (the language
/// backend is unbuilt, so a remote repo would call dead endpoints). Keeping this
/// interface lets a future backend slice drop in without touching providers.
abstract class VocabRepository {
  /// All of the current user's sets, ordered by creation time (oldest first).
  Future<List<VocabSet>> getSets();

  /// Insert or update [set] (matched by [VocabSet.id]).
  Future<void> saveSet(VocabSet set);

  /// Remove the set [setId] and cascade-delete all of its cards.
  Future<void> deleteSet(String setId);

  /// All cards in [setId], ordered by creation time (oldest first).
  Future<List<VocabCard>> getCards(String setId);

  /// Insert or update [card] (matched by [VocabCard.id]); also the path by which
  /// a graded card's new review state is persisted.
  Future<void> saveCard(VocabCard card);

  /// Remove card [cardId] from set [setId].
  Future<void> deleteCard(String setId, String cardId);
}
