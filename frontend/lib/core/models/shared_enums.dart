import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ============================================================================
// Shared Enums - Used across multiple domains
// ============================================================================

/// Age groups for UI differentiation
/// Used by: Student, PracticeItem
enum AgeGroup {
  child, // 어린이 (12세 이하)
  student, // 학생 (13-18세)
  adult; // 성인 (19세 이상)

  String get label {
    switch (this) {
      case AgeGroup.child:
        return '어린이';
      case AgeGroup.student:
        return '학생';
      case AgeGroup.adult:
        return '성인';
    }
  }

  String get description {
    switch (this) {
      case AgeGroup.child:
        return '초등학생 이하';
      case AgeGroup.student:
        return '중고등학생';
      case AgeGroup.adult:
        return '대학생 이상';
    }
  }

  /// Calculate age group from birth date
  static AgeGroup fromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    if (age <= 12) return AgeGroup.child;
    if (age <= 18) return AgeGroup.student;
    return AgeGroup.adult;
  }

  /// Age threshold
  int get maxAge {
    switch (this) {
      case AgeGroup.child:
        return 12;
      case AgeGroup.student:
        return 18;
      case AgeGroup.adult:
        return 999;
    }
  }
}

/// Practice level for integrated indicator
/// Used by: Student, Invite
enum PracticeLevel {
  newStudent, // Just connected (no practice data yet)
  excellent, // 5+ days in last 7 days
  average, // 3-4 days in last 7 days
  poor, // 1-2 days in last 7 days
  onBreak; // On break status

  String get label {
    switch (this) {
      case PracticeLevel.newStudent:
        return '신규';
      case PracticeLevel.excellent:
        return '우수';
      case PracticeLevel.average:
        return '보통';
      case PracticeLevel.poor:
        return '부족';
      case PracticeLevel.onBreak:
        return '기록없음';
    }
  }

  Color get color {
    switch (this) {
      case PracticeLevel.newStudent:
        return AppColors.paperAccent;
      case PracticeLevel.excellent:
        return AppColors.paperOk;
      case PracticeLevel.average:
        return AppColors.paperAccent;
      case PracticeLevel.poor:
        return AppColors.paperAccent;
      case PracticeLevel.onBreak:
        return AppColors.inkTertiary;
    }
  }

  /// Minimum practice days required for this level
  int get minDays {
    switch (this) {
      case PracticeLevel.excellent:
        return 5;
      case PracticeLevel.average:
        return 3;
      case PracticeLevel.poor:
        return 1;
      case PracticeLevel.newStudent:
      case PracticeLevel.onBreak:
        return 0;
    }
  }
}
