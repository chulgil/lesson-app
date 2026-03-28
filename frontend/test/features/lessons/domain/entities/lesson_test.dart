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
}
