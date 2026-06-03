import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';

/// Regression (#bug4/#bug5): VacationPeriod.isActiveOn must use date-only
/// comparison and respect cancellation.
VacationPeriod _period({
  required DateTime startDate,
  required DateTime endDate,
  DateTime? cancelledAt,
}) => VacationPeriod(
  id: 'v1',
  teacherId: 't1',
  startDate: startDate,
  endDate: endDate,
  cancelledAt: cancelledAt,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('VacationPeriod.isActiveOn', () {
    final ref = DateTime(2026, 6, 4, 14, 30); // afternoon reference

    test('active when end date is in the future', () {
      final p = _period(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 10),
      );
      expect(p.isActiveOn(ref), isTrue);
    });

    test('active when end date is today (midnight) despite afternoon ref', () {
      // Off-by-one guard: endDate at 00:00 today vs ref at 14:30.
      final p = _period(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 4),
      );
      expect(p.isActiveOn(ref), isTrue);
    });

    test('inactive when end date already passed', () {
      final p = _period(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 6, 3),
      );
      expect(p.isActiveOn(ref), isFalse);
    });

    test('inactive when cancelled even if end date is future', () {
      final p = _period(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 10),
        cancelledAt: DateTime(2026, 6, 2),
      );
      expect(p.isActiveOn(ref), isFalse);
    });
  });
}
