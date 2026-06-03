import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';

/// Regression (#bug6): a vacation must not start in the past. hasValidRange
/// now rejects a past start date (date-only comparison).
void main() {
  group('VacationFormState.hasValidRange', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('valid when start is today and end is later', () {
      final state = VacationFormState(
        startDate: today,
        endDate: today.add(const Duration(days: 3)),
      );
      expect(state.hasValidRange, isTrue);
    });

    test('invalid when start date is in the past', () {
      final state = VacationFormState(
        startDate: today.subtract(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 3)),
      );
      expect(state.hasValidRange, isFalse);
    });

    test('invalid when end is before start', () {
      final state = VacationFormState(
        startDate: today.add(const Duration(days: 5)),
        endDate: today.add(const Duration(days: 2)),
      );
      expect(state.hasValidRange, isFalse);
    });

    test('invalid when either date is null', () {
      expect(const VacationFormState().hasValidRange, isFalse);
      expect(
        VacationFormState(startDate: today).hasValidRange,
        isFalse,
      );
    });
  });
}
