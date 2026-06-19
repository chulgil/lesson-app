import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';

/// Draft range + effective-segment derivation (#768 ② / regression #bug6).
/// A vacation draft must not start in the past, and `canSubmit` derives from
/// committed segments plus a valid, non-overlapping draft.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  group('VacationFormState.hasValidDraft', () {
    test('valid when start is today and end is later', () {
      final state = VacationFormState(
        draftStart: today,
        draftEnd: today.add(const Duration(days: 3)),
      );
      expect(state.hasValidDraft, isTrue);
    });

    test('invalid when start date is in the past', () {
      final state = VacationFormState(
        draftStart: today.subtract(const Duration(days: 1)),
        draftEnd: today.add(const Duration(days: 3)),
      );
      expect(state.hasValidDraft, isFalse);
    });

    test('invalid when end is before start', () {
      final state = VacationFormState(
        draftStart: today.add(const Duration(days: 5)),
        draftEnd: today.add(const Duration(days: 2)),
      );
      expect(state.hasValidDraft, isFalse);
    });

    test('invalid when either date is null', () {
      expect(const VacationFormState().hasValidDraft, isFalse);
      expect(VacationFormState(draftStart: today).hasValidDraft, isFalse);
    });
  });

  group('VacationFormState.effectiveSegments / canSubmit', () {
    VacationSegment seg(int from, int to) => VacationSegment(
      startDate: today.add(Duration(days: from)),
      endDate: today.add(Duration(days: to)),
    );

    test('a valid non-overlapping draft is included automatically', () {
      final state = VacationFormState(
        draftStart: today.add(const Duration(days: 10)),
        draftEnd: today.add(const Duration(days: 12)),
      );
      expect(state.effectiveSegments, hasLength(1));
      expect(state.canSubmit, isTrue);
    });

    test('an overlapping draft is excluded from effective segments', () {
      final state = VacationFormState(
        segments: [seg(1, 5)],
        draftStart: today.add(const Duration(days: 3)),
        draftEnd: today.add(const Duration(days: 7)),
      );
      expect(state.draftOverlaps, isTrue);
      // Only the committed segment counts; the overlapping draft is dropped.
      expect(state.effectiveSegments, hasLength(1));
      expect(state.canSubmit, isTrue);
    });

    test('committed segment + non-overlapping draft = 2 effective', () {
      final state = VacationFormState(
        segments: [seg(1, 5)],
        draftStart: today.add(const Duration(days: 8)),
        draftEnd: today.add(const Duration(days: 10)),
      );
      expect(state.draftOverlaps, isFalse);
      expect(state.effectiveSegments, hasLength(2));
    });

    test('empty state cannot submit', () {
      expect(const VacationFormState().canSubmit, isFalse);
    });
  });
}
