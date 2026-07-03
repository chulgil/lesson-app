import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/vocabulary/data/repositories/local_vocab_repository.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/review_grade.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/domain/repositories/vocab_repository.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_cards_provider.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_library_controller.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_repository_provider.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_sets_provider.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/review_session_provider.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;
  late LocalVocabRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vocab_provider_test');
    Hive.init(tempDir.path);
    repo = LocalVocabRepository('u1');
    container = ProviderContainer(
      overrides: [vocabRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  VocabCard cardDue(String id, String setId, DateTime dueDate) {
    final base = VocabCard.create(
      id: id,
      setId: setId,
      front: 'f-$id',
      back: 'b-$id',
      createdAt: DateTime(2026, 1, 1),
    );
    return base.copyWith(
      reviewState: base.reviewState.copyWith(dueDate: dueDate),
    );
  }

  group('dueCards', () {
    test(
      'returns only cards due today-or-earlier, ordered by due date',
      () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await repo.saveSet(VocabSet(id: 's1', title: 'A', createdAt: today));
        await repo.saveSet(VocabSet(id: 's2', title: 'B', createdAt: today));
        // Two due (one overdue, one today) across two sets, one not due.
        await repo.saveCard(
          cardDue('c1', 's1', today.subtract(const Duration(days: 2))),
        );
        await repo.saveCard(
          cardDue('c2', 's1', today.add(const Duration(days: 3))),
        );
        await repo.saveCard(cardDue('c3', 's2', today));

        final due = await container.read(dueCardsProvider(null).future);

        expect(due.map((c) => c.id), ['c1', 'c3']); // overdue before today
      },
    );

    test('scopes to one set when setId given', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await repo.saveSet(VocabSet(id: 's1', title: 'A', createdAt: today));
      await repo.saveCard(cardDue('c1', 's1', today));
      await repo.saveCard(cardDue('c2', 's2', today));

      final due = await container.read(dueCardsProvider('s1').future);

      expect(due.map((c) => c.id), ['c1']);
    });
  });

  group('reviewSession', () {
    test(
      'walks the due queue: each grade persists the next state and advances',
      () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await repo.saveSet(VocabSet(id: 's1', title: 'A', createdAt: today));
        await repo.saveCard(cardDue('c1', 's1', today));
        await repo.saveCard(cardDue('c2', 's1', today));

        final keepAlive = container.listen(
          reviewSessionProvider('s1'),
          (_, __) {},
        );
        addTearDown(keepAlive.close);

        final initial = await container.read(
          reviewSessionProvider('s1').future,
        );
        expect(initial.total, 2);
        expect(initial.index, 0);
        expect(initial.isDone, isFalse);

        final notifier = container.read(reviewSessionProvider('s1').notifier);
        await notifier.grade(ReviewGrade.good);
        expect(
          container.read(reviewSessionProvider('s1')).requireValue.index,
          1,
        );

        await notifier.grade(ReviewGrade.good);
        final done = container.read(reviewSessionProvider('s1')).requireValue;
        expect(done.isDone, isTrue);

        // Both cards persisted a first successful review (SM-2: reps 1, due tomorrow).
        final persisted = await repo.getCards('s1');
        expect(persisted.every((c) => c.reviewState.repetitions == 1), isTrue);
        expect(
          persisted.every((c) => c.reviewState.dueDate.isAfter(today)),
          isTrue,
        );
      },
    );

    test('grade after the queue is exhausted is a no-op', () async {
      final today = DateTime.now();
      await repo.saveSet(VocabSet(id: 's1', title: 'A', createdAt: today));

      final keepAlive = container.listen(
        reviewSessionProvider('s1'),
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      final initial = await container.read(reviewSessionProvider('s1').future);
      expect(initial.total, 0);
      expect(initial.isDone, isTrue);

      await container
          .read(reviewSessionProvider('s1').notifier)
          .grade(ReviewGrade.good);
      expect(container.read(reviewSessionProvider('s1')).requireValue.index, 0);
    });

    test(
      're-entrancy guard: two grades in one tick process the card once',
      () async {
        final today = DateTime(2026, 7, 1);
        await repo.saveSet(VocabSet(id: 's1', title: 'A', createdAt: today));
        await repo.saveCard(cardDue('c1', 's1', today));
        await repo.saveCard(
          cardDue('c2', 's1', today.add(const Duration(minutes: 1))),
        );

        final counting = _CountingVocabRepository(repo);
        final c = ProviderContainer(
          overrides: [vocabRepositoryProvider.overrideWithValue(counting)],
        );
        addTearDown(c.dispose);
        final keepAlive = c.listen(reviewSessionProvider('s1'), (_, __) {});
        addTearDown(keepAlive.close);
        await c.read(reviewSessionProvider('s1').future);
        final notifier = c.read(reviewSessionProvider('s1').notifier);

        // Fire two different grades in the same tick; the second must be dropped.
        final first = notifier.grade(ReviewGrade.again);
        final second = notifier.grade(ReviewGrade.easy);
        await Future.wait([first, second]);

        // Exactly one persist (card 1), index advanced by exactly one, and card 1
        // carries the FIRST grade (again → lapse: repetitions 0), not easy (1).
        expect(counting.saveCardCalls, 1);
        expect(c.read(reviewSessionProvider('s1')).requireValue.index, 1);
        final persisted = (await repo.getCards(
          's1',
        )).firstWhere((x) => x.id == 'c1');
        expect(persisted.reviewState.repetitions, 0);
      },
    );
  });

  group('VocabLibrary write → read invalidation (alive listener)', () {
    test('createSet surfaces the new set in the live vocabSets list', () async {
      final keepAlive = container.listen(vocabSetsProvider, (_, __) {});
      addTearDown(keepAlive.close);
      expect(await container.read(vocabSetsProvider.future), isEmpty);

      await container.read(vocabLibraryProvider.notifier).createSet('영어');

      final sets = await container.read(vocabSetsProvider.future);
      expect(sets.map((s) => s.title), ['영어']);
    });

    test('addCard makes the card appear in the live due queue', () async {
      final set = await container
          .read(vocabLibraryProvider.notifier)
          .createSet('A');
      final keepAlive = container.listen(dueCardsProvider(set.id), (_, __) {});
      addTearDown(keepAlive.close);
      expect(await container.read(dueCardsProvider(set.id).future), isEmpty);

      await container
          .read(vocabLibraryProvider.notifier)
          .addCard(set.id, front: 'apple', back: '사과');

      final due = await container.read(dueCardsProvider(set.id).future);
      expect(due.map((c) => c.front), ['apple']); // brand-new card is due now
    });

    test('deleteSet clears the live set list and cascades its cards', () async {
      final set = await container
          .read(vocabLibraryProvider.notifier)
          .createSet('A');
      await container
          .read(vocabLibraryProvider.notifier)
          .addCard(set.id, front: 'x', back: 'y');
      final setsAlive = container.listen(vocabSetsProvider, (_, __) {});
      final cardsAlive = container.listen(
        vocabCardsProvider(set.id),
        (_, __) {},
      );
      addTearDown(setsAlive.close);
      addTearDown(cardsAlive.close);
      expect((await container.read(vocabSetsProvider.future)).length, 1);
      expect(
        (await container.read(vocabCardsProvider(set.id).future)).length,
        1,
      );

      await container.read(vocabLibraryProvider.notifier).deleteSet(set.id);

      expect(await container.read(vocabSetsProvider.future), isEmpty);
      expect(await container.read(vocabCardsProvider(set.id).future), isEmpty);
    });

    test('editCard can clear an optional field to null', () async {
      final set = await container
          .read(vocabLibraryProvider.notifier)
          .createSet('A');
      await container
          .read(vocabLibraryProvider.notifier)
          .addCard(set.id, front: 'x', back: 'y', example: 'has example');
      final card =
          (await container.read(vocabCardsProvider(set.id).future)).single;
      expect(card.example, 'has example');

      await container
          .read(vocabLibraryProvider.notifier)
          .editCard(card, front: 'x', back: 'y', example: '   ');

      final edited =
          (await container.read(vocabCardsProvider(set.id).future)).single;
      expect(edited.example, isNull);
    });
  });
}

/// Delegates to [_inner] but counts [saveCard] calls, to assert the review
/// session's re-entrancy guard persists a card exactly once per grade.
class _CountingVocabRepository implements VocabRepository {
  _CountingVocabRepository(this._inner);

  final VocabRepository _inner;
  int saveCardCalls = 0;

  @override
  Future<void> saveCard(VocabCard card) {
    saveCardCalls++;
    return _inner.saveCard(card);
  }

  @override
  Future<List<VocabSet>> getSets() => _inner.getSets();

  @override
  Future<void> saveSet(VocabSet set) => _inner.saveSet(set);

  @override
  Future<void> deleteSet(String setId) => _inner.deleteSet(setId);

  @override
  Future<List<VocabCard>> getCards(String setId) => _inner.getCards(setId);

  @override
  Future<void> deleteCard(String setId, String cardId) =>
      _inner.deleteCard(setId, cardId);
}
