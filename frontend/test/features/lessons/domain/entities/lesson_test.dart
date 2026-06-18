import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helper
  // ═══════════════════════════════════════════════════════════════════════════

  Lesson createLesson({
    String? subscriptionId,
    LessonStatus status = LessonStatus.scheduled,
    bool isPreview = false,
  }) {
    return Lesson(
      id: 'lesson_1',
      studentId: 'student_1',
      studentName: '김민수',
      instrument: '바이올린',
      date: DateTime(2026, 4, 1),
      startTime: '14:00',
      duration: 60,
      status: status,
      subscriptionId: subscriptionId,
      isPreview: isPreview,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // subscriptionId field
  // ═══════════════════════════════════════════════════════════════════════════

  group('subscriptionId', () {
    test('기본값 null — 수강권 없는 레슨 (체험 등)', () {
      final lesson = createLesson();
      expect(lesson.subscriptionId, isNull);
    });

    test('값 설정 — 수강권에 연결된 레슨', () {
      final lesson = createLesson(subscriptionId: 'sub_001');
      expect(lesson.subscriptionId, 'sub_001');
    });

    test('copyWith로 subscriptionId 설정', () {
      final lesson = createLesson();
      final updated = lesson.copyWith(subscriptionId: 'sub_002');
      expect(updated.subscriptionId, 'sub_002');
      expect(lesson.subscriptionId, isNull); // immutability
    });

    test('copyWith로 subscriptionId 유지 (다른 필드 변경)', () {
      final lesson = createLesson(subscriptionId: 'sub_001');
      final updated = lesson.copyWith(duration: 90);
      expect(updated.subscriptionId, 'sub_001');
      expect(updated.duration, 90);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // hasSubscription getter
  // ═══════════════════════════════════════════════════════════════════════════

  group('hasSubscription', () {
    test('subscriptionId 있으면 true', () {
      final lesson = createLesson(subscriptionId: 'sub_001');
      expect(lesson.hasSubscription, isTrue);
    });

    test('subscriptionId null이면 false', () {
      final lesson = createLesson();
      expect(lesson.hasSubscription, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // isPreview field
  // ═══════════════════════════════════════════════════════════════════════════

  group('isPreview', () {
    test('기본값 false', () {
      final lesson = createLesson();
      expect(lesson.isPreview, isFalse);
    });

    test('true 설정', () {
      final lesson = createLesson(isPreview: true);
      expect(lesson.isPreview, isTrue);
    });

    test('copyWith로 isPreview 설정', () {
      final lesson = createLesson();
      final updated = lesson.copyWith(isPreview: true);
      expect(updated.isPreview, isTrue);
      expect(lesson.isPreview, isFalse); // immutability
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // awaitsTeacherFeedback — #796 피드백 프롬프트는 출석 확인 후에만
  // ═══════════════════════════════════════════════════════════════════════════

  group('awaitsTeacherFeedback', () {
    test('출석 확인 완료(completed) + 수강권 + 피드백 없음 → true', () {
      final lesson = createLesson(
        subscriptionId: 'sub_001',
        status: LessonStatus.completed,
      );
      expect(lesson.awaitsTeacherFeedback, isTrue);
    });

    test('피드백 이미 작성됨 → false', () {
      final lesson = createLesson(
        subscriptionId: 'sub_001',
        status: LessonStatus.completed,
      ).copyWith(feedback: '잘했어요');
      expect(lesson.awaitsTeacherFeedback, isFalse);
    });

    test('과거 미확인 레슨(scheduled, 종료 시간 지남) → false (#796 핵심)', () {
      // date 2026-04-01 은 과거 → displayStatus 는 completed 로 투영되지만,
      // 실제 status 는 scheduled(출석 미확인). 프롬프트가 떠선 안 된다.
      final lesson = createLesson(
        subscriptionId: 'sub_001',
        status: LessonStatus.scheduled,
      );
      expect(lesson.displayStatus, LessonStatus.completed); // 투영 확인
      expect(lesson.isUnconfirmed, isTrue); // 출석 미확인 확인
      expect(lesson.awaitsTeacherFeedback, isFalse); // 그래도 프롬프트 없음
    });

    test('수강권 없는 수동 레슨(completed) → false', () {
      final lesson = createLesson(status: LessonStatus.completed);
      expect(lesson.awaitsTeacherFeedback, isFalse);
    });

    test('휴강(cancelledByTeacher) + 수강권 → false', () {
      final lesson = createLesson(
        subscriptionId: 'sub_001',
        status: LessonStatus.cancelledByTeacher,
      );
      expect(lesson.awaitsTeacherFeedback, isFalse);
    });

    test('학생 결석(studentAbsent) + 수강권 → false', () {
      final lesson = createLesson(
        subscriptionId: 'sub_001',
        status: LessonStatus.studentAbsent,
      );
      expect(lesson.awaitsTeacherFeedback, isFalse);
    });
  });
}
