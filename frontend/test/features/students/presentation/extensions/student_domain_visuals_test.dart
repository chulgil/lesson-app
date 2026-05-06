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
      expect(StudentStatus.active.label, '정규');
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
      expect(PracticeStatus.paused.label, '휴강');

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

      expect(academy.icon, '■');
      expect(private.icon, '●');
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
      expect(group.icon, '■');
      expect(group.count, 0);
      expect(uncategorized.title, '미분류');
      expect(uncategorized.icon, '○');
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

      expect(LocationType.online.icon, '💻');
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
  });
}
