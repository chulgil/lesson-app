import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/extensions/lesson_visuals.dart';

void main() {
  group('LessonStatusVisualX', () {
    test('maps status labels', () {
      expect(LessonStatus.scheduled.label, '예정');
      expect(LessonStatus.completed.label, '완료');
      expect(LessonStatus.cancelled.label, '취소');
      expect(LessonStatus.cancelledByStudentAdvance.label, '사전 취소');
      expect(LessonStatus.cancelledByStudentLate.label, '당일 취소');
      expect(LessonStatus.cancelledByTeacher.label, '선생님 취소');
      expect(LessonStatus.cancelledMutual.label, '합의 취소');
      expect(LessonStatus.noShow.label, '결석');
      expect(LessonStatus.studentAbsent.label, '학생 불참');
      expect(LessonStatus.reschedulePending.label, '변경 대기');
    });
  });

  group('LessonPieceVisualX', () {
    test('builds display name from piece parts', () {
      const piece = LessonPiece(
        id: 'piece_1',
        name: 'Sonata',
        opus: 'Op. 27',
        movement: 'II',
      );

      expect(piece.displayName, 'Sonata - Op. 27 - II');
    });
  });
}
