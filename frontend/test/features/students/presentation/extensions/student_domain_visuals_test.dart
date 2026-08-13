import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/grouped_students.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_location.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_slot.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/entities/student_with_membership.dart';
import 'package:lessonaza/features/students/presentation/extensions/student_domain_visuals.dart';

void main() {
  group('StudentStatusVisuals', () {
    test('maps labels and colors for presentation', () {
      expect(StudentStatus.trial.label, '체험');
      expect(StudentStatus.active.label, '수강중');
      expect(StudentStatus.paused.label, '휴강');
      expect(StudentStatus.inactive.label, '종료');

      expect(StudentStatus.trial.color, AppColors.paperAccent);
      expect(StudentStatus.active.color, AppColors.paperOk);
    });
  });

  group('StudentLevelVisuals', () {
    test('maps labels for presentation', () {
      expect(StudentLevel.beginner.label, '입문');
      expect(StudentLevel.elementary.label, '초급');
      expect(StudentLevel.intermediate.label, '중급');
      expect(StudentLevel.advanced.label, '고급');
    });
  });

  group('PracticeStatusVisuals', () {
    test('maps labels and colors for presentation', () {
      expect(PracticeStatus.good.label, '우수');
      expect(PracticeStatus.normal.label, '보통');
      expect(PracticeStatus.poor.label, '부족');
      expect(PracticeStatus.paused.label, '기록없음');

      expect(PracticeStatus.good.color, AppColors.paperOk);
      expect(PracticeStatus.normal.color, AppColors.practiceNormal);
    });
  });

  group('MembershipStatusVisuals', () {
    test('maps labels for presentation', () {
      expect(MembershipStatus.trial.label, '체험중');
      expect(MembershipStatus.active.label, '수강중');
      expect(MembershipStatus.paused.label, '휴강');
      expect(MembershipStatus.terminated.label, '종료');
    });
  });

  group('LessonClassVisuals', () {
    test('maps class type icons and display labels for presentation', () {
      final academy = LessonClass(
        id: 'class-1',
        teacherId: 'teacher-1',
        name: 'ABC Music',
        type: LessonClassType.academy,
        paymentType: PaymentType.organization,
        createdAt: DateTime(2026),
      );
      final private = LessonClass(
        id: 'class-2',
        teacherId: 'teacher-1',
        name: 'Private Studio',
        type: LessonClassType.private,
        paymentType: PaymentType.parent,
        createdAt: DateTime(2026),
      );

      expect(academy.icon, Icons.business);
      expect(private.icon, Icons.person);
      expect(academy.displayLabel, 'ABC Music');
      expect(private.displayLabel, '개인레슨');
    });
  });

  group('StudentGroupVisuals', () {
    test('maps section title and icon for presentation', () {
      final group = StudentGroup(
        lessonClass: LessonClass(
          id: 'class-1',
          teacherId: 'teacher-1',
          name: 'ABC Music',
          type: LessonClassType.academy,
          paymentType: PaymentType.organization,
          createdAt: DateTime(2026),
        ),
        students: const <StudentWithMembership>[],
      );
      const uncategorized = StudentGroup(students: <StudentWithMembership>[]);

      expect(group.title, 'ABC Music');
      expect(group.icon, Icons.business);
      expect(group.count, 0);
      expect(uncategorized.title, '미분류');
      expect(uncategorized.icon, Icons.circle_outlined);
    });
  });

  group('LessonLocationVisuals', () {
    test('maps type labels and display addresses for presentation', () {
      expect(LocationType.academyRoom.label, '학원 레슨실');
      expect(LocationType.teacherStudio.label, '선생님 스튜디오');
      expect(LocationType.studentHome.label, '학생 집 방문');
      expect(LocationType.externalPlace.label, '외부 장소');
      expect(LocationType.online.label, '온라인');

      final online = LessonLocation(
        id: 'location-1',
        name: 'Zoom',
        type: LocationType.online,
        onlinePlatform: 'Zoom',
        createdAt: DateTime(2026),
      );
      final physical = LessonLocation(
        id: 'location-2',
        name: 'Room 1',
        type: LocationType.academyRoom,
        address: '서울시 강남구',
        addressDetail: '2층',
        createdAt: DateTime(2026),
      );

      expect(LocationType.online.icon, Icons.computer);
      expect(online.displayAddress, 'Zoom');
      expect(physical.displayAddress, '서울시 강남구 2층');
    });
  });

  group('LessonSlotVisuals', () {
    test('maps day and time labels for presentation', () {
      const slot = LessonSlot(
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
      );

      expect(slot.dayLabel, '화');
      expect(slot.displayLabel, '화요일 14:00~15:00');
      expect(slot.shortLabel, '화 14:00');
    });

    test('dayLabel — 0=월 ~ 6=일', () {
      const labels = ['월', '화', '수', '목', '금', '토', '일'];
      for (var day = 0; day < labels.length; day++) {
        final slot = LessonSlot(
          dayOfWeek: day,
          startTime: '10:00',
          endTime: '11:00',
        );
        expect(slot.dayLabel, labels[day]);
      }
    });
  });

  group('StudentVisuals.lessonSchedule', () {
    Student student({List<LessonSlot> lessonSlots = const []}) => Student(
      id: 'student-1',
      name: '민지',
      instrument: '피아노',
      level: StudentLevel.beginner,
      status: StudentStatus.active,
      practiceStatus: PracticeStatus.normal,
      lessonSlots: lessonSlots,
      profileColorKey: 'ink',
      monthlyFee: 0,
      createdAt: DateTime(2026),
    );

    test('빈 슬롯이면 null', () {
      expect(student().lessonSchedule, isNull);
    });

    test('여러 슬롯은 쉼표로 join', () {
      final withSlots = student(
        lessonSlots: const [
          LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
          LessonSlot(dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
        ],
      );
      expect(withSlots.lessonSchedule, '화 14:00, 목 16:00');
    });
  });

  group('ClassMembershipVisuals.scheduleDisplay', () {
    ClassMembership membership({List<LessonSlot> lessonSlots = const []}) =>
        ClassMembership(
          id: 'membership-1',
          lessonClassId: 'class-1',
          studentId: 'student-1',
          instrument: '피아노',
          status: MembershipStatus.active,
          monthlyFee: 0,
          lessonsPerWeek: lessonSlots.length,
          lessonSlots: lessonSlots,
          lessonDuration: 60,
          createdAt: DateTime(2026),
        );

    test('빈 슬롯이면 null', () {
      expect(membership().scheduleDisplay, isNull);
    });

    test('여러 슬롯은 쉼표로 join', () {
      final withSlots = membership(
        lessonSlots: const [
          LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
          LessonSlot(dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
        ],
      );
      expect(withSlots.scheduleDisplay, '화 14:00, 목 16:00');
    });
  });

  group('StudentWithMembershipVisuals.lessonSchedule', () {
    test('membership 이 있고 슬롯이 있으면 membership 우선', () {
      final swm = StudentWithMembership(
        student: Student(
          id: 'student-1',
          name: '민지',
          instrument: '피아노',
          level: StudentLevel.beginner,
          status: StudentStatus.active,
          practiceStatus: PracticeStatus.normal,
          lessonSlots: const [
            LessonSlot(dayOfWeek: 5, startTime: '10:00', endTime: '11:00'),
          ],
          profileColorKey: 'ink',
          monthlyFee: 0,
          createdAt: DateTime(2026),
        ),
        membership: ClassMembership(
          id: 'membership-1',
          lessonClassId: 'class-1',
          studentId: 'student-1',
          instrument: '피아노',
          status: MembershipStatus.active,
          monthlyFee: 0,
          lessonsPerWeek: 1,
          lessonSlots: const [
            LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
          ],
          lessonDuration: 60,
          createdAt: DateTime(2026),
        ),
      );

      expect(swm.lessonSchedule, '화 14:00');
    });

    test('membership 슬롯이 없으면 student 슬롯으로 폴백', () {
      final swm = StudentWithMembership(
        student: Student(
          id: 'student-1',
          name: '민지',
          instrument: '피아노',
          level: StudentLevel.beginner,
          status: StudentStatus.active,
          practiceStatus: PracticeStatus.normal,
          lessonSlots: const [
            LessonSlot(dayOfWeek: 5, startTime: '10:00', endTime: '11:00'),
          ],
          profileColorKey: 'ink',
          monthlyFee: 0,
          createdAt: DateTime(2026),
        ),
      );

      expect(swm.lessonSchedule, '토 10:00');
    });
  });
}
