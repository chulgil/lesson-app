import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_lesson_progress_item.dart';

void main() {
  test('sorts action required before waiting before completed', () {
    final now = DateTime(2026, 5, 4, 12);
    final items = [
      StudentLessonProgressItem(
        id: 'completed',
        kind: StudentLessonProgressKind.subscriptionReady,
        priority: StudentLessonProgressPriority.completed,
        title: '수강권이 준비됐어요',
        subtitle: '다음 레슨 일정에 맞춰 시작합니다',
        statusLabel: '완료',
        createdAt: now,
      ),
      StudentLessonProgressItem(
        id: 'waiting',
        kind: StudentLessonProgressKind.request,
        priority: StudentLessonProgressPriority.waiting,
        title: '레슨 신청을 보냈어요',
        subtitle: '선생님 답변을 기다리고 있어요',
        statusLabel: '대기',
        createdAt: now,
      ),
      StudentLessonProgressItem(
        id: 'action',
        kind: StudentLessonProgressKind.scheduleConfirmation,
        priority: StudentLessonProgressPriority.actionRequired,
        title: '수강권이 준비됐어요',
        subtitle: '첫 레슨 시간을 확인해주세요',
        statusLabel: '확인 필요',
        createdAt: now,
      ),
    ];

    final sorted = StudentLessonProgressItem.sorted(items);

    expect(sorted.map((item) => item.id), ['action', 'waiting', 'completed']);
  });
}
