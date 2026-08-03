import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/vocab_card.dart';
import '../../domain/entities/vocab_set.dart';
import '../../domain/repositories/vocab_repository.dart';

/// Local-first Hive implementation of [VocabRepository] (#1124).
///
/// One shared `String` box holds the whole tool. Each value is a JSON array
/// string keyed by user id (mirrors `SelectedDisciplineStorage`'s user-scoping),
/// so accounts never cross-contaminate:
/// - `user:<uid>:vocab:sets` — the user's [VocabSet]s.
/// - `user:<uid>:vocab:cards:<setId>` — the cards of one set.
///
/// Reads/writes rewrite the whole per-key list; fine at personal-vocabulary
/// scale and keeps deletes and cascades trivial. No Hive TypeAdapters — values
/// are hand-serialized JSON (adapter regeneration footgun avoided).
class LocalVocabRepository implements VocabRepository {
  LocalVocabRepository(this.userId);

  /// The owner whose data this repository reads/writes. Injected by the provider
  /// (which rebuilds on account switch), so the instance is always single-user.
  final String userId;

  static const _boxName = 'vocab';

  String get _setsKey => 'user:$userId:vocab:sets';
  String _cardsKey(String setId) => 'user:$userId:vocab:cards:$setId';

  Future<Box<String>> _box() => Hive.openBox<String>(_boxName);

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
  }

  String _encodeList(List<Object?> jsonList) => jsonEncode(jsonList);

  @override
  Future<List<VocabSet>> getSets() async {
    final box = await _box();
    final sets = _decodeList(box.get(_setsKey), VocabSet.fromJson)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sets;
  }

  @override
  Future<void> saveSet(VocabSet set) async {
    final box = await _box();
    final sets = _decodeList(box.get(_setsKey), VocabSet.fromJson);
    final index = sets.indexWhere((s) => s.id == set.id);
    if (index >= 0) {
      sets[index] = set;
    } else {
      sets.add(set);
    }
    await box.put(_setsKey, _encodeList(sets.map((s) => s.toJson()).toList()));
  }

  @override
  Future<void> deleteSet(String setId) async {
    final box = await _box();
    final sets = _decodeList(box.get(_setsKey), VocabSet.fromJson)
      ..removeWhere((s) => s.id == setId);
    await box.put(_setsKey, _encodeList(sets.map((s) => s.toJson()).toList()));
    // Cascade: drop the set's card list entirely.
    await box.delete(_cardsKey(setId));
  }

  @override
  Future<List<VocabCard>> getCards(String setId) async {
    final box = await _box();
    final cards = _decodeList(box.get(_cardsKey(setId)), VocabCard.fromJson)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return cards;
  }

  @override
  Future<void> saveCard(VocabCard card) async {
    final box = await _box();
    final key = _cardsKey(card.setId);
    final cards = _decodeList(box.get(key), VocabCard.fromJson);
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    await box.put(key, _encodeList(cards.map((c) => c.toJson()).toList()));
  }

  @override
  Future<void> deleteCard(String setId, String cardId) async {
    final box = await _box();
    final key = _cardsKey(setId);
    final cards = _decodeList(box.get(key), VocabCard.fromJson)
      ..removeWhere((c) => c.id == cardId);
    await box.put(key, _encodeList(cards.map((c) => c.toJson()).toList()));
  }
}
