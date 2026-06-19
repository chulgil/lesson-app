import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';

/// Unit tests for the multi-segment vacation domain helpers (#768 ②).
void main() {
  VacationSegment seg(int startDay, int endDay) => VacationSegment(
    startDate: DateTime(2026, 7, startDay),
    endDate: DateTime(2026, 7, endDay),
  );

  group('vacationSegmentsOverlap', () {
    test('비겹침 인접 구간 → false', () {
      expect(vacationSegmentsOverlap([seg(15, 17), seg(18, 20)]), isFalse);
    });

    test('겹치는 구간 → true', () {
      expect(vacationSegmentsOverlap([seg(15, 20), seg(18, 22)]), isTrue);
    });

    test('경계일 공유 → true (inclusive)', () {
      expect(vacationSegmentsOverlap([seg(15, 18), seg(18, 20)]), isTrue);
    });

    test('단일 구간 → false', () {
      expect(vacationSegmentsOverlap([seg(15, 17)]), isFalse);
    });

    test('빈 리스트 → false', () {
      expect(vacationSegmentsOverlap(const []), isFalse);
    });

    test('입력 순서 무관', () {
      expect(vacationSegmentsOverlap([seg(20, 22), seg(15, 17)]), isFalse);
      expect(vacationSegmentsOverlap([seg(20, 22), seg(21, 25)]), isTrue);
    });
  });

  group('VacationSegment.days', () {
    test('양끝 포함 일수', () {
      expect(seg(15, 17).days, 3);
      expect(seg(15, 15).days, 1);
    });
  });
}
