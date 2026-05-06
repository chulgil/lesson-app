import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/makeup_lesson.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/makeup_lesson_visuals.dart';

void main() {
  group('MakeupStatusVisualX', () {
    test('maps status labels in presentation', () {
      expect(MakeupStatus.pending.label, '예약 대기');
      expect(MakeupStatus.scheduled.label, '예약됨');
      expect(MakeupStatus.completed.label, '완료');
      expect(MakeupStatus.expired.label, '만료됨');
      expect(MakeupStatus.waived.label, '면제');
    });
  });

  group('MakeupReasonVisualX', () {
    test('maps reason labels in presentation', () {
      expect(MakeupReason.studentCancellation.label, '학생 취소');
      expect(MakeupReason.teacherCancellation.label, '선생님 취소');
      expect(MakeupReason.noShowReschedule.label, '노쇼 보강');
      expect(MakeupReason.other.label, '기타');
    });
  });
}
