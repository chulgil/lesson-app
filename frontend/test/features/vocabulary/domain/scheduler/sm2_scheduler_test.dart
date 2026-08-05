import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/card_review_state.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/review_grade.dart';
import 'package:lessonaza/features/vocabulary/domain/scheduler/sm2_scheduler.dart';

/// #1124 — classic SuperMemo-2 scheduler (Anki's historical algorithm). Pure and
/// deterministic: reviewedAt is injected, so every expectation is exact.
void main() {
  const scheduler = Sm2Scheduler();
  final t0 = DateTime(2026, 1, 1);

  CardReviewState initial() => CardReviewState.initial(t0);

  group('Sm2Scheduler — first reviews', () {
    test('good on a new card: reps 1, interval 1 day, ease unchanged (2.5)', () {
      final s = scheduler.review(initial(), ReviewGrade.good, t0);
      expect(s.repetitions, 1);
      expect(s.intervalDays, 1);
      expect(s.easeFactor, closeTo(2.5, 1e-9)); // good (q=4) delta = 0
      expect(s.dueDate, t0.add(const Duration(days: 1)));
      expect(s.lastReviewedAt, t0);
    });

    test('good x2 → interval 6 days (SM-2 fixed second interval)', () {
      var s = scheduler.review(initial(), ReviewGrade.good, t0);
      s = scheduler.review(s, ReviewGrade.good, s.dueDate);
      expect(s.repetitions, 2);
      expect(s.intervalDays, 6);
    });
  });

  group('Sm2Scheduler — interval growth (round(prev * EF), EF=2.5)', () {
    test('good x5 → intervals 1, 6, 15, 38, 95', () {
      final expected = [1, 6, 15, 38, 95];
      var s = initial();
      var when = t0;
      for (var i = 0; i < expected.length; i++) {
        s = scheduler.review(s, ReviewGrade.good, when);
        expect(s.intervalDays, expected[i], reason: 'review #${i + 1}');
        expect(s.easeFactor, closeTo(2.5, 1e-9));
        when = s.dueDate;
      }
    });
  });

  group('Sm2Scheduler — ease factor updates', () {
    test('easy raises ease by 0.10, hard lowers by 0.14', () {
      final easy = scheduler.review(initial(), ReviewGrade.easy, t0);
      expect(easy.easeFactor, closeTo(2.6, 1e-9));

      final hard = scheduler.review(initial(), ReviewGrade.hard, t0);
      expect(hard.easeFactor, closeTo(2.36, 1e-9));
    });

    test('ease factor never drops below the 1.3 floor', () {
      var s = initial();
      for (var i = 0; i < 8; i++) {
        s = scheduler.review(s, ReviewGrade.again, s.dueDate);
        expect(s.easeFactor, greaterThanOrEqualTo(1.3));
      }
      expect(s.easeFactor, closeTo(1.3, 1e-9));
    });

    test('mature interval uses the UPDATED ease (Hard shortens, Easy lengthens)', () {
      // Mature a card to rep 3 / interval 15 / ease 2.5 via three Goods.
      var mature = initial();
      var when = t0;
      for (var i = 0; i < 3; i++) {
        mature = scheduler.review(mature, ReviewGrade.good, when);
        when = mature.dueDate;
      }
      expect(mature.repetitions, 3);
      expect(mature.intervalDays, 15);

      // Distinctive design choice: interval computed from EF' (post-update), so
      // Hard (EF 2.36) → round(15*2.36)=35, Easy (EF 2.6) → round(15*2.6)=39.
      // The old-EF reference ordering would give 38 for both — this pins ours.
      final hard = scheduler.review(mature, ReviewGrade.hard, when);
      expect(hard.intervalDays, 35);
      final easy = scheduler.review(mature, ReviewGrade.easy, when);
      expect(easy.intervalDays, 39);
    });
  });

  group('Sm2Scheduler — lapse (again)', () {
    test('again resets repetitions to 0 and interval to 1 day, penalizes ease', () {
      // Mature the card first (reps 3, interval 15, ease 2.5).
      var s = initial();
      var when = t0;
      for (var i = 0; i < 3; i++) {
        s = scheduler.review(s, ReviewGrade.good, when);
        when = s.dueDate;
      }
      expect(s.repetitions, 3);

      final lapsed = scheduler.review(s, ReviewGrade.again, when);
      expect(lapsed.repetitions, 0);
      expect(lapsed.intervalDays, 1);
      expect(lapsed.easeFactor, closeTo(2.18, 1e-9)); // 2.5 - 0.32
      expect(lapsed.dueDate, when.add(const Duration(days: 1)));
    });

    test('after a lapse the 1/6 interval sequence restarts', () {
      var s = scheduler.review(initial(), ReviewGrade.again, t0);
      s = scheduler.review(s, ReviewGrade.good, s.dueDate);
      expect(s.repetitions, 1);
      expect(s.intervalDays, 1);
      s = scheduler.review(s, ReviewGrade.good, s.dueDate);
      expect(s.intervalDays, 6);
    });
  });

  test('dueDate is a calendar day at local midnight (time-of-day stripped)', () {
    // Review at 09:30 with a Good (interval 1) → due the NEXT calendar day at
    // 00:00, not next-day 09:30. Calendar arithmetic keeps day-bucketing DST-safe.
    final reviewedAt = DateTime(2026, 3, 10, 9, 30);
    final s = scheduler.review(CardReviewState.initial(reviewedAt),
        ReviewGrade.good, reviewedAt);
    expect(s.dueDate, DateTime(2026, 3, 11));
    expect(s.dueDate.hour, 0);
    expect(s.dueDate.minute, 0);
  });

  test('deterministic: identical inputs yield identical output', () {
    final a = scheduler.review(initial(), ReviewGrade.good, t0);
    final b = scheduler.review(initial(), ReviewGrade.good, t0);
    expect(a, b);
  });
}
