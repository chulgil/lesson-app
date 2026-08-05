import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/card_review_state.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/scheduler/due_policy.dart';

VocabCard _cardDue(DateTime dueDate) => VocabCard(
  id: 'c',
  setId: 's',
  front: 'f',
  back: 'b',
  createdAt: DateTime(2026, 1, 1),
  reviewState: CardReviewState(
    easeFactor: 2.5,
    repetitions: 0,
    intervalDays: 0,
    dueDate: dueDate,
  ),
);

void main() {
  // "now" is mid-afternoon to prove the boundary is calendar-day, not time-of-day.
  final now = DateTime(2026, 7, 3, 14, 0);

  group('isCardDue — calendar-day bucketing', () {
    test('due when the due date is an earlier calendar day', () {
      expect(isCardDue(_cardDue(DateTime(2026, 7, 2)), now), isTrue);
    });

    test('due when the due date is today at local midnight', () {
      expect(isCardDue(_cardDue(DateTime(2026, 7, 3)), now), isTrue);
    });

    test('due for any time later today (not gated on time-of-day)', () {
      expect(isCardDue(_cardDue(DateTime(2026, 7, 3, 23, 59)), now), isTrue);
    });

    test('not due when the due date is tomorrow', () {
      expect(isCardDue(_cardDue(DateTime(2026, 7, 4)), now), isFalse);
    });
  });
}
