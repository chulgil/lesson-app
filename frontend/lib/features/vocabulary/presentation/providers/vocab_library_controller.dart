import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/vocab_card.dart';
import '../../domain/entities/vocab_set.dart';
import 'vocab_cards_provider.dart';
import 'vocab_repository_provider.dart';
import 'vocab_sets_provider.dart';

part 'vocab_library_controller.g.dart';

/// Imperative write API for vocabulary sets and cards (#1124).
///
/// The single mutation entry point: every create / edit / delete persists
/// through the repository and then invalidates the affected read providers, so
/// lists and due badges refresh without callers wiring invalidation themselves
/// (write → read invalidation).
@riverpod
class VocabLibrary extends _$VocabLibrary {
  @override
  void build() {}

  /// Monotonic-enough local id for a single user (microsecond clock).
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<VocabSet> createSet(String title) async {
    final set = VocabSet(
      id: _newId(),
      title: title.trim(),
      createdAt: DateTime.now(),
    );
    await ref.read(vocabRepositoryProvider).saveSet(set);
    ref.invalidate(vocabSetsProvider);
    ref.invalidate(vocabSummaryProvider);
    return set;
  }

  Future<void> renameSet(VocabSet set, String title) async {
    await ref
        .read(vocabRepositoryProvider)
        .saveSet(set.copyWith(title: title.trim()));
    ref.invalidate(vocabSetsProvider);
  }

  Future<void> deleteSet(String setId) async {
    await ref.read(vocabRepositoryProvider).deleteSet(setId);
    ref.invalidate(vocabSetsProvider);
    ref.invalidate(vocabSummaryProvider);
    ref.invalidate(vocabCardsProvider(setId));
    ref.invalidate(dueCardsProvider(setId));
    ref.invalidate(dueCardsProvider(null));
  }

  Future<void> addCard(
    String setId, {
    required String front,
    required String back,
    String? example,
    String? memo,
  }) async {
    final card = VocabCard.create(
      id: _newId(),
      setId: setId,
      front: front.trim(),
      back: back.trim(),
      example: _nullIfBlank(example),
      memo: _nullIfBlank(memo),
      createdAt: DateTime.now(),
    );
    await ref.read(vocabRepositoryProvider).saveCard(card);
    _invalidateCards(setId);
  }

  Future<void> editCard(
    VocabCard card, {
    required String front,
    required String back,
    String? example,
    String? memo,
  }) async {
    // Build explicitly (not copyWith) so clearing example/memo to null sticks —
    // copyWith's `?? this.x` can't distinguish "unchanged" from "cleared".
    final updated = VocabCard(
      id: card.id,
      setId: card.setId,
      front: front.trim(),
      back: back.trim(),
      example: _nullIfBlank(example),
      memo: _nullIfBlank(memo),
      createdAt: card.createdAt,
      reviewState: card.reviewState,
    );
    await ref.read(vocabRepositoryProvider).saveCard(updated);
    _invalidateCards(card.setId);
  }

  Future<void> deleteCard(String setId, String cardId) async {
    await ref.read(vocabRepositoryProvider).deleteCard(setId, cardId);
    _invalidateCards(setId);
  }

  void _invalidateCards(String setId) {
    ref.invalidate(vocabCardsProvider(setId));
    ref.invalidate(dueCardsProvider(setId));
    ref.invalidate(dueCardsProvider(null));
    ref.invalidate(vocabSummaryProvider);
    ref.invalidate(vocabSetsProvider);
  }
}
