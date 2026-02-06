import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_role.dart';

export '../../domain/entities/user_role.dart';

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
    case UserRole.parent:
      return 'parent_1';
  }
});

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
