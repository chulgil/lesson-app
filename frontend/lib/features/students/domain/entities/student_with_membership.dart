import 'package:flutter/material.dart';

import 'class_membership.dart';
import 'student.dart';

/// Pairs a Student with their ClassMembership in a specific class.
/// Membership data takes precedence over Student entity data.
class StudentWithMembership {
  final Student student;
  final ClassMembership? membership; // null for uncategorized students

  const StudentWithMembership({
    required this.student,
    this.membership,
  });

  String get name => student.name;
  String get studentId => student.id;
  String get initial => student.initial;
  Color get profileColor => student.profileColor;
  PracticeStatus get practiceStatus => student.practiceStatus;

  // Prefer membership data over student data
  String get instrument => membership?.instrument ?? student.instrument;

  String? get lessonSchedule {
    if (membership?.lessonDay != null && membership?.lessonTime != null) {
      return '${membership!.lessonDay} ${membership!.lessonTime}';
    }
    return student.lessonSchedule;
  }

  /// Whether student is connected via the app.
  bool get isAppConnected => student.isAppConnected;
}
