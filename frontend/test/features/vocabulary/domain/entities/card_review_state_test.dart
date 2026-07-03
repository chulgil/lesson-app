import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/card_review_state.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/review_grade.dart';

/// #1124 — CardReviewState value semantics + JSON round-trip (local persistence).
void main() {
  final t0 = DateTime(2026, 1, 1, 9, 30);

  test('initial: due immediately, ease 2.5, no reviews yet', () {
    final s = CardReviewState.initial(t0);
    expect(s.easeFactor, 2.5);
    expect(s.repetitions, 0);
    expect(s.intervalDays, 0);
    expect(s.dueDate, t0);
    expect(s.lastReviewedAt, isNull);
  });

  test('JSON round-trip preserves every field (incl. null lastReviewedAt)', () {
    final s = CardReviewState.initial(t0);
    expect(CardReviewState.fromJson(s.toJson()), s);
  });

  test('JSON round-trip preserves a reviewed state', () {
    final s = CardReviewState(
      easeFactor: 2.36,
      repetitions: 4,
      intervalDays: 38,
      dueDate: DateTime(2026, 2, 8),
      lastReviewedAt: DateTime(2026, 1, 1),
    );
    expect(CardReviewState.fromJson(s.toJson()), s);
  });

  test('copyWith overrides only the given fields', () {
    final s = CardReviewState.initial(t0);
    final u = s.copyWith(repetitions: 2, intervalDays: 6);
    expect(u.repetitions, 2);
    expect(u.intervalDays, 6);
    expect(u.easeFactor, s.easeFactor);
    expect(u.dueDate, s.dueDate);
  });

  test('ReviewGrade quality mapping + passed flag', () {
    expect(ReviewGrade.again.quality, 2);
    expect(ReviewGrade.hard.quality, 3);
    expect(ReviewGrade.good.quality, 4);
    expect(ReviewGrade.easy.quality, 5);
    expect(ReviewGrade.again.passed, isFalse);
    expect(ReviewGrade.hard.passed, isTrue);
  });
}
