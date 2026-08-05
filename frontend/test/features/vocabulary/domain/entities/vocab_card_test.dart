import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/card_review_state.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';

void main() {
  final createdAt = DateTime(2026, 7, 3, 9, 30);

  group('VocabCard', () {
    test('create() seeds an immediately-due initial review state', () {
      final card = VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: 'apple',
        back: '사과',
        createdAt: createdAt,
      );

      // A brand-new card is due at creation (SM-2 initial state).
      expect(card.reviewState.dueDate, createdAt);
      expect(card.reviewState.repetitions, 0);
      expect(card.reviewState.easeFactor, 2.5);
      expect(card.example, isNull);
      expect(card.memo, isNull);
    });

    test(
      'toJson/fromJson round-trip preserves fields incl. embedded review state',
      () {
        final reviewed = CardReviewState(
          easeFactor: 2.36,
          repetitions: 3,
          intervalDays: 35,
          dueDate: DateTime(2026, 8, 7),
          lastReviewedAt: DateTime(2026, 7, 3),
        );
        final card = VocabCard(
          id: 'c1',
          setId: 's1',
          front: 'apple',
          back: '사과',
          example: 'I ate an apple.',
          memo: '과일',
          createdAt: createdAt,
          reviewState: reviewed,
        );

        final restored = VocabCard.fromJson(card.toJson());

        expect(restored, card);
        expect(restored.example, 'I ate an apple.');
        expect(restored.memo, '과일');
        expect(restored.reviewState, reviewed);
      },
    );

    test('null example/memo round-trip as null', () {
      final card = VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: 'x',
        back: 'y',
        createdAt: createdAt,
      );

      final restored = VocabCard.fromJson(card.toJson());

      expect(restored.example, isNull);
      expect(restored.memo, isNull);
      expect(restored, card);
    });

    test('copyWith swaps only the review state (used after grading)', () {
      final card = VocabCard.create(
        id: 'c1',
        setId: 's1',
        front: 'x',
        back: 'y',
        createdAt: createdAt,
      );
      final next = CardReviewState(
        easeFactor: 2.6,
        repetitions: 1,
        intervalDays: 1,
        dueDate: DateTime(2026, 7, 4),
        lastReviewedAt: createdAt,
      );

      final graded = card.copyWith(reviewState: next);

      expect(graded.reviewState, next);
      expect(graded.front, 'x');
      expect(graded.id, 'c1');
      expect(graded, isNot(card));
    });
  });
}
