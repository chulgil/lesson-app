import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/schedule/domain/services/preview_lesson_generator.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_slot.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  ClassMembership createMembership({
    String studentId = 'student_1',
    List<LessonSlot> lessonSlots = const [],
    int lessonDuration = 60,
    String instrument = '바이올린',
  }) {
    return ClassMembership(
      id: 'cm_1',
      lessonClassId: 'class_1',
      studentId: studentId,
      instrument: instrument,
      status: MembershipStatus.active,
      monthlyFee: 200000,
      lessonSlots: lessonSlots,
      lessonDuration: lessonDuration,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Subscription createSubscription({
    String studentId = 'student_1',
    required DateTime endDate,
  }) {
    return Subscription(
      id: 'sub_1',
      studentId: studentId,
      membershipId: 'cm_1',
      type: SubscriptionType.monthly,
      totalLessons: 4,
      usedLessons: 0,
      startDate: DateTime(2026, 3, 1),
      endDate: endDate,
      amount: 200000,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  // Week of 2026-04-06 (Mon) to 2026-04-12 (Sun)
  // 2026-04-07 = Tuesday (dayOfWeek 1)
  // 2026-04-09 = Thursday (dayOfWeek 3)
  final weekStart = DateTime(2026, 4, 6); // Monday

  // ═══════════════════════════════════════════════════════════════════════════
  // generateForWeek tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('PreviewLessonGenerator.generateForWeek', () {
    test('수강권 범위 내 → 빈 리스트', () {
      final membership = createMembership(
        lessonSlots: [
          const LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
        ],
      );
      final subscription = createSubscription(
        endDate: DateTime(2026, 4, 30), // 4월 말까지 유효
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [subscription],
        existingLessons: [],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews, isEmpty);
    });

    test('수강권 범위 밖 + fixed slot → 가상 레슨 생성', () {
      final membership = createMembership(
        lessonSlots: [
          const LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
        ],
      );
      final subscription = createSubscription(
        endDate: DateTime(2026, 3, 30), // 3월 말 만료 → 4월은 범위 밖
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [subscription],
        existingLessons: [],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews.length, 1);
      expect(previews.first.isPreview, isTrue);
      expect(previews.first.studentId, 'student_1');
      expect(previews.first.instrument, '바이올린');
      expect(previews.first.startTime, '14:00');
      expect(previews.first.date, DateTime(2026, 4, 7)); // Tuesday
    });

    test('주 2회 학생 → 2개 가상 레슨', () {
      final membership = createMembership(
        lessonSlots: [
          const LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
          const LessonSlot(dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
        ],
      );
      final subscription = createSubscription(
        endDate: DateTime(2026, 3, 30),
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [subscription],
        existingLessons: [],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews.length, 2);
      expect(previews[0].date, DateTime(2026, 4, 7)); // Tuesday
      expect(previews[1].date, DateTime(2026, 4, 9)); // Thursday
    });

    test('flexible 학생 (lessonSlots 비어있음) → 빈 리스트', () {
      final membership = createMembership(lessonSlots: []);
      final subscription = createSubscription(
        endDate: DateTime(2026, 3, 30),
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [subscription],
        existingLessons: [],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews, isEmpty);
    });

    test('실제 Lesson이 이미 존재하는 슬롯 → 중복 생성 안 함', () {
      final membership = createMembership(
        lessonSlots: [
          const LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
        ],
      );
      final subscription = createSubscription(
        endDate: DateTime(2026, 3, 30),
      );
      final existingLesson = Lesson(
        id: 'lesson_existing',
        studentId: 'student_1',
        studentName: '김민수',
        instrument: '바이올린',
        date: DateTime(2026, 4, 7), // Tuesday — same as slot
        startTime: '14:00',
        duration: 60,
        createdAt: DateTime(2026, 3, 1),
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [subscription],
        existingLessons: [existingLesson],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews, isEmpty);
    });

    test('수강권 없는 학생 → 빈 리스트', () {
      final membership = createMembership(
        lessonSlots: [
          const LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
        ],
      );

      final previews = PreviewLessonGenerator.generateForWeek(
        weekStart: weekStart,
        memberships: [membership],
        subscriptions: [], // no subscriptions
        existingLessons: [],
        studentNames: {'student_1': '김민수'},
      );

      expect(previews, isEmpty);
    });
  });
}
