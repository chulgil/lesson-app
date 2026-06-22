import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';

/// Regression: `lesson.date` must serialize as a calendar date (`yyyy-MM-dd`),
/// NOT a full ISO datetime.
///
/// The backend `LessonCreate.date` is a Pydantic `date`, which 422-rejects a
/// datetime string carrying a non-midnight time. Adding a lesson for a new
/// student (default `_selectedDate = DateTime.now()`, untouched date picker,
/// student without `primarySlot`) previously sent `"...T10:30:45.000"` →
/// FastAPI 422 → rethrow → "저장 실패".
void main() {
  Lesson lessonWithDate(DateTime date) => Lesson(
    id: 'lesson_1',
    studentId: 'student_1',
    studentName: '김민수',
    instrument: '바이올린',
    date: date,
    startTime: '14:00',
    createdAt: DateTime(2026, 3, 1),
  );

  group('Lesson.date JSON 직렬화 (BE LessonCreate.date 계약)', () {
    test('시각이 붙은 날짜도 날짜 전용(yyyy-MM-dd)으로 직렬화 — 422 방지', () {
      final json = lessonWithDate(DateTime(2026, 6, 22, 10, 30, 45)).toJson();
      expect(json['date'], '2026-06-22');
      expect((json['date'] as String).contains('T'), isFalse);
    });

    test('자정 날짜도 동일하게 yyyy-MM-dd', () {
      final json = lessonWithDate(DateTime(2026, 6, 22)).toJson();
      expect(json['date'], '2026-06-22');
    });

    test('한 자리 월/일도 0 패딩 (yyyy-MM-dd 고정폭)', () {
      final json = lessonWithDate(DateTime(2026, 1, 5, 9, 0)).toJson();
      expect(json['date'], '2026-01-05');
    });

    test('round-trip: 직렬화 후 역직렬화 시 날짜(연·월·일) 보존', () {
      final original = lessonWithDate(DateTime(2026, 6, 22, 10, 30));
      final restored = Lesson.fromJson(original.toJson());
      expect(restored.date.year, 2026);
      expect(restored.date.month, 6);
      expect(restored.date.day, 22);
    });
  });
}
