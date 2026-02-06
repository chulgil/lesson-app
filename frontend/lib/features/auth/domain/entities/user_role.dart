/// User role enum for distinguishing teacher/student/parent views
enum UserRole {
  teacher,
  student,
  parent;

  String get label {
    switch (this) {
      case UserRole.teacher:
        return '선생님';
      case UserRole.student:
        return '학생';
      case UserRole.parent:
        return '학부모';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.teacher:
        return '👩‍🏫';
      case UserRole.student:
        return '🎻';
      case UserRole.parent:
        return '👨‍👩‍👧';
    }
  }

  String get homeRoute {
    switch (this) {
      case UserRole.teacher:
        return '/home';
      case UserRole.student:
        return '/student-home';
      case UserRole.parent:
        return '/parent-home';
    }
  }
}

/// Mock student data for testing (when in student role)
class MockStudentInfo {
  final String id;
  final String name;

  const MockStudentInfo({required this.id, required this.name});
}
