import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';

MakeupCredit _credit({
  DateTime? createdAt,
  DateTime? expiresAt,
  DateTime? usedAt,
}) {
  final now = DateTime(2026, 8, 1);
  return MakeupCredit(
    id: 'c1',
    studentId: 's1',
    teacherId: 't1',
    reason: MakeupCreditReason.teacherVacation,
    createdAt: createdAt ?? now,
    expiresAt: expiresAt ?? now.add(const Duration(days: 30)),
    usedAt: usedAt,
  );
}

void main() {
  final now = DateTime(2026, 8, 10);

  group('MakeupCredit', () {
    test('available when not used and not expired', () {
      final c = _credit(expiresAt: DateTime(2026, 8, 20));
      expect(c.isUsed, isFalse);
      expect(c.isExpired(now), isFalse);
      expect(c.isAvailable(now), isTrue);
    });

    test('expired when past expiry and unused', () {
      final c = _credit(expiresAt: DateTime(2026, 8, 5));
      expect(c.isExpired(now), isTrue);
      expect(c.isAvailable(now), isFalse);
    });

    test('used credit is never expired nor available', () {
      final c = _credit(
        expiresAt: DateTime(2026, 8, 5),
        usedAt: DateTime(2026, 8, 4),
      );
      expect(c.isUsed, isTrue);
      expect(c.isExpired(now), isFalse);
      expect(c.isAvailable(now), isFalse);
    });

    test('daysUntilExpiry computes calendar day delta', () {
      final c = _credit(expiresAt: DateTime(2026, 8, 25));
      expect(c.daysUntilExpiry(now), 15);
    });
  });

  group('MakeupCreditBalance', () {
    test('fromCredits keeps only spendable credits sorted by expiry', () {
      final credits = [
        _credit(expiresAt: DateTime(2026, 8, 25)), // available, later
        _credit(expiresAt: DateTime(2026, 8, 5)), // expired
        _credit(expiresAt: DateTime(2026, 8, 15)), // available, earlier
        _credit(
          expiresAt: DateTime(2026, 8, 30),
          usedAt: DateTime(2026, 8, 9),
        ), // used
      ];
      final balance = MakeupCreditBalance.fromCredits(credits, now);

      expect(balance.availableCount, 2);
      expect(balance.hasAny, isTrue);
      expect(balance.earliestExpiry, DateTime(2026, 8, 15));
    });

    test('empty balance reports no expiry', () {
      const balance = MakeupCreditBalance();
      expect(balance.hasAny, isFalse);
      expect(balance.earliestExpiry, isNull);
      expect(balance.availableCount, 0);
    });
  });
}
