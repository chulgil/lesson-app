import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/vocabulary/data/repositories/local_vocab_repository.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vocab_repo_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  VocabSet setFixture(String id, {DateTime? createdAt}) => VocabSet(
    id: id,
    title: 'set-$id',
    createdAt: createdAt ?? DateTime(2026, 7, 3),
  );

  VocabCard cardFixture(String id, String setId, {DateTime? createdAt}) =>
      VocabCard.create(
        id: id,
        setId: setId,
        front: 'front-$id',
        back: 'back-$id',
        createdAt: createdAt ?? DateTime(2026, 7, 3),
      );

  group('LocalVocabRepository — sets', () {
    test('getSets on a fresh box returns empty', () async {
      final repo = LocalVocabRepository('u1');
      expect(await repo.getSets(), isEmpty);
    });

    test('saveSet then getSets round-trips the set', () async {
      final repo = LocalVocabRepository('u1');
      final set = setFixture('s1');

      await repo.saveSet(set);

      expect(await repo.getSets(), [set]);
    });

    test('saveSet with an existing id upserts (no duplicate)', () async {
      final repo = LocalVocabRepository('u1');
      await repo.saveSet(setFixture('s1'));

      await repo.saveSet(setFixture('s1').copyWith(title: 'renamed'));

      final sets = await repo.getSets();
      expect(sets.length, 1);
      expect(sets.single.title, 'renamed');
    });

    test('getSets orders by createdAt ascending', () async {
      final repo = LocalVocabRepository('u1');
      await repo.saveSet(setFixture('late', createdAt: DateTime(2026, 7, 5)));
      await repo.saveSet(setFixture('early', createdAt: DateTime(2026, 7, 1)));

      expect((await repo.getSets()).map((s) => s.id).toList(), [
        'early',
        'late',
      ]);
    });
  });

  group('LocalVocabRepository — cards', () {
    test('saveCard then getCards round-trips incl. review state', () async {
      final repo = LocalVocabRepository('u1');
      final card = cardFixture('c1', 's1');

      await repo.saveCard(card);

      final cards = await repo.getCards('s1');
      expect(cards, [card]);
      expect(cards.single.reviewState.dueDate, card.reviewState.dueDate);
    });

    test('getCards scopes to the requested set', () async {
      final repo = LocalVocabRepository('u1');
      await repo.saveCard(cardFixture('c1', 's1'));
      await repo.saveCard(cardFixture('c2', 's2'));

      expect((await repo.getCards('s1')).map((c) => c.id), ['c1']);
      expect((await repo.getCards('s2')).map((c) => c.id), ['c2']);
    });

    test('saveCard upserts by id (grading rewrites the same card)', () async {
      final repo = LocalVocabRepository('u1');
      final card = cardFixture('c1', 's1');
      await repo.saveCard(card);

      final graded = card.copyWith(
        reviewState: card.reviewState.copyWith(repetitions: 3),
      );
      await repo.saveCard(graded);

      final cards = await repo.getCards('s1');
      expect(cards.length, 1);
      expect(cards.single.reviewState.repetitions, 3);
    });

    test('deleteCard removes only that card', () async {
      final repo = LocalVocabRepository('u1');
      await repo.saveCard(cardFixture('c1', 's1'));
      await repo.saveCard(cardFixture('c2', 's1'));

      await repo.deleteCard('s1', 'c1');

      expect((await repo.getCards('s1')).map((c) => c.id), ['c2']);
    });
  });

  group('LocalVocabRepository — cascade + isolation', () {
    test('deleteSet removes the set and cascades its cards', () async {
      final repo = LocalVocabRepository('u1');
      await repo.saveSet(setFixture('s1'));
      await repo.saveCard(cardFixture('c1', 's1'));

      await repo.deleteSet('s1');

      expect(await repo.getSets(), isEmpty);
      expect(await repo.getCards('s1'), isEmpty);
    });

    test('sets/cards are isolated per user id', () async {
      final repoA = LocalVocabRepository('userA');
      final repoB = LocalVocabRepository('userB');
      await repoA.saveSet(setFixture('s1'));
      await repoA.saveCard(cardFixture('c1', 's1'));

      expect(await repoB.getSets(), isEmpty);
      expect(await repoB.getCards('s1'), isEmpty);
      // userA still sees its own data.
      expect((await repoA.getSets()).map((s) => s.id), ['s1']);
    });
  });
}
