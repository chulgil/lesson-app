import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/class_membership.dart';
import '../../domain/entities/grouped_students.dart';
import '../../domain/entities/lesson_class.dart';
import '../../domain/entities/lesson_location.dart';
import '../../domain/entities/lesson_slot.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_with_membership.dart';

Color _colorForKey(String key) {
  switch (key) {
    case 'paperAccent':
      return AppColors.paperAccent;
    case 'paperOk':
      return AppColors.paperOk;
    case 'inkTertiary':
      return AppColors.inkTertiary;
    case 'practiceNormal':
      return AppColors.practiceNormal;
    case 'practicePaused':
      return AppColors.practicePaused;
    case 'ink':
      return AppColors.ink;
    case 'profileRed':
      return AppColors.profileRed;
    case 'profileBlue':
      return AppColors.profileBlue;
    case 'profileTeal':
      return AppColors.profileTeal;
    case 'profilePurple':
      return AppColors.profilePurple;
    case 'profileOrange':
      return AppColors.profileOrange;
    default:
      return AppColors.paperAccent;
  }
}

extension StudentStatusVisuals on StudentStatus {
  String get label {
    switch (this) {
      case StudentStatus.trial:
        return AppStrings.studentStatusTrial;
      case StudentStatus.active:
        return AppStrings.studentStatusActive;
      case StudentStatus.paused:
        return AppStrings.studentStatusPaused;
      case StudentStatus.inactive:
        return AppStrings.studentStatusInactive;
    }
  }

  Color get color {
    switch (this) {
      case StudentStatus.trial:
        return AppColors.paperAccent;
      case StudentStatus.active:
        return AppColors.paperOk;
      case StudentStatus.paused:
        return AppColors.inkTertiary;
      case StudentStatus.inactive:
        return AppColors.paperAccent;
    }
  }
}

extension StudentLevelVisuals on StudentLevel {
  String get label {
    switch (this) {
      case StudentLevel.beginner:
        return AppStrings.studentLevelBeginner;
      case StudentLevel.elementary:
        return AppStrings.studentLevelElementary;
      case StudentLevel.intermediate:
        return AppStrings.studentLevelIntermediate;
      case StudentLevel.advanced:
        return AppStrings.studentLevelAdvanced;
    }
  }
}

extension PracticeStatusVisuals on PracticeStatus {
  String get label {
    switch (this) {
      case PracticeStatus.good:
        return AppStrings.studentPracticeStatusGood;
      case PracticeStatus.normal:
        return AppStrings.studentPracticeStatusNormal;
      case PracticeStatus.poor:
        return AppStrings.studentPracticeStatusPoor;
      case PracticeStatus.paused:
        return AppStrings.studentPracticeStatusPaused;
    }
  }

  Color get color {
    switch (this) {
      case PracticeStatus.good:
        return AppColors.paperOk;
      case PracticeStatus.normal:
        return AppColors.practiceNormal;
      case PracticeStatus.poor:
        return AppColors.paperAccent;
      case PracticeStatus.paused:
        return AppColors.practicePaused;
    }
  }
}

extension MembershipStatusVisuals on MembershipStatus {
  String get label {
    switch (this) {
      case MembershipStatus.trial:
        return '체험중';
      case MembershipStatus.active:
        return '수강중';
      case MembershipStatus.paused:
        return '휴강';
      case MembershipStatus.terminated:
        return '종료';
    }
  }
}

extension ClassMembershipVisuals on ClassMembership {
  String get statusLabel => status.label;

  String? get scheduleDisplay => lessonSlots.isNotEmpty
      ? lessonSlots.map((slot) => slot.shortLabel).join(', ')
      : null;
}

extension LessonClassVisuals on LessonClass {
  IconData get icon => type.icon;

  String get displayLabel =>
      type == LessonClassType.academy ? name : AppStrings.individualLesson;
}

extension LessonClassTypeVisuals on LessonClassType {
  IconData get icon =>
      this == LessonClassType.academy ? Icons.business : Icons.person;
}

extension StudentGroupVisuals on StudentGroup {
  String get title => lessonClass?.name ?? '미분류';
  IconData get icon => lessonClass?.icon ?? Icons.circle_outlined;
}

extension LocationTypeVisuals on LocationType {
  IconData get icon {
    switch (this) {
      case LocationType.academyRoom:
        return Icons.school;
      case LocationType.teacherStudio:
        return Icons.home;
      case LocationType.studentHome:
        return Icons.directions_car;
      case LocationType.externalPlace:
        return Icons.place;
      case LocationType.online:
        return Icons.computer;
    }
  }

  String get label {
    switch (this) {
      case LocationType.academyRoom:
        return '학원 레슨실';
      case LocationType.teacherStudio:
        return '선생님 스튜디오';
      case LocationType.studentHome:
        return '학생 집 방문';
      case LocationType.externalPlace:
        return '외부 장소';
      case LocationType.online:
        return AppStrings.locationOnlineLabel;
    }
  }
}

extension LessonLocationVisuals on LessonLocation {
  IconData get icon => type.icon;
  String get typeLabel => type.label;

  String get displayAddress {
    if (type == LocationType.online) {
      return onlinePlatform ?? AppStrings.locationOnlineLabel;
    }
    if (address == null) return '';
    return addressDetail != null ? '$address $addressDetail' : address!;
  }
}

const _lessonSlotDayLabels = ['월', '화', '수', '목', '금', '토', '일'];

extension LessonSlotVisuals on LessonSlot {
  /// Short day label: "화"
  String get dayLabel => _lessonSlotDayLabels[dayOfWeek.clamp(0, 6)];

  /// Short display: "화 14:00"
  String get shortLabel => '$dayLabel $startTime';

  String get displayLabel => '$dayLabel요일 $startTime~$endTime';
}

extension StudentVisuals on Student {
  Color get profileColor => _colorForKey(profileColorKey);

  /// Comma-joined weekly lesson schedule (e.g., "화 14:00, 목 16:00").
  String? get lessonSchedule {
    if (lessonSlots.isEmpty) return null;
    return lessonSlots.map((s) => s.shortLabel).join(', ');
  }
}

extension StudentWithMembershipVisuals on StudentWithMembership {
  Color get profileColor => _colorForKey(profileColorKey);

  /// Comma-joined weekly schedule — membership takes precedence over student.
  String? get lessonSchedule {
    if (membership != null && membership!.lessonSlots.isNotEmpty) {
      return membership!.scheduleDisplay;
    }
    return student.lessonSchedule;
  }
}
