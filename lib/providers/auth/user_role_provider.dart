import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User role enum for distinguishing teacher/student views
enum UserRole {
  teacher,
  student;

  String get label {
    switch (this) {
      case UserRole.teacher:
        return '선생님';
      case UserRole.student:
        return '학생';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.teacher:
        return '👩‍🏫';
      case UserRole.student:
        return '🎻';
    }
  }

  String get homeRoute {
    switch (this) {
      case UserRole.teacher:
        return '/home';
      case UserRole.student:
        return '/student-home';
    }
  }
}

/// Current user role state provider
/// Used to switch between teacher and student views for testing
final currentUserRoleProvider = StateProvider<UserRole>((ref) {
  return UserRole.teacher; // Default to teacher
});

/// Current mock user ID based on role
final currentUserIdProvider = Provider<String>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  switch (role) {
    case UserRole.teacher:
      return 'teacher_1';
    case UserRole.student:
      return 'student_1';
  }
});

/// Mock student data for testing (when in student role)
class MockStudentInfo {
  final String id;
  final String name;

  const MockStudentInfo({required this.id, required this.name});
}

/// Available mock students for testing
final mockStudentsProvider = Provider<List<MockStudentInfo>>((ref) {
  return const [
    MockStudentInfo(id: 'student_1', name: '김서연'),
    MockStudentInfo(id: 'student_2', name: '이도현'),
    MockStudentInfo(id: 'student_3', name: '박지민'),
  ];
});

/// Currently selected mock student (for student role testing)
final selectedMockStudentProvider = StateProvider<MockStudentInfo>((ref) {
  final students = ref.read(mockStudentsProvider);
  return students.first;
});
