import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/domain/entities/bulk_closure.dart';
import 'package:lessonaza/features/schedule/presentation/screens/makeup_conflict.dart';

AffectedLesson _lesson(String id, {int durationMinutes = 60}) {
  final start = DateTime(2026, 6, 1, 10);
  return AffectedLesson(
    lessonId: id,
    studentId: 's_$id',
    studentName: '학생$id',
    originalStartAt: start,
    originalEndAt: start.add(Duration(minutes: durationMinutes)),
  );
}

void main() {
  group('detectMakeupConflicts', () {
    final lessons = [_lesson('a'), _lesson('b'), _lesson('c')];

    test('동일 시각 두 보강은 양쪽 모두 충돌', () {
      final at = DateTime(2026, 6, 8, 15);
      final conflicts = detectMakeupConflicts(lessons, {'a': at, 'b': at});
      expect(conflicts, {'a', 'b'});
    });

    test('윈도우가 교차하면 충돌 (60분 레슨, 30분 간격)', () {
      final conflicts = detectMakeupConflicts(lessons, {
        'a': DateTime(2026, 6, 8, 15, 0),
        'b': DateTime(2026, 6, 8, 15, 30),
      });
      expect(conflicts, {'a', 'b'});
    });

    test('인접(끝=다음 시작)은 충돌 아님', () {
      final conflicts = detectMakeupConflicts(lessons, {
        'a': DateTime(2026, 6, 8, 15, 0), // 15:00~16:00
        'b': DateTime(2026, 6, 8, 16, 0), // 16:00~17:00
      });
      expect(conflicts, isEmpty);
    });

    test('서로 다른 시간은 충돌 아님', () {
      final conflicts = detectMakeupConflicts(lessons, {
        'a': DateTime(2026, 6, 8, 15, 0),
        'b': DateTime(2026, 6, 9, 15, 0),
      });
      expect(conflicts, isEmpty);
    });

    test('null draft 는 무시', () {
      final at = DateTime(2026, 6, 8, 15);
      final conflicts = detectMakeupConflicts(lessons, {'a': at, 'b': null});
      expect(conflicts, isEmpty);
    });

    test('겹치는 한 쌍만 충돌 (a,b 겹침 / c 별도)', () {
      final at = DateTime(2026, 6, 8, 15);
      final conflicts = detectMakeupConflicts(lessons, {
        'a': at,
        'b': at,
        'c': DateTime(2026, 6, 10, 9),
      });
      expect(conflicts, {'a', 'b'});
    });
  });
}
