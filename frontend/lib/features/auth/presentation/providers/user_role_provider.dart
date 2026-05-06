import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/config/environment.dart';
import '../../domain/entities/user_role.dart';
import 'auth_provider.dart';

export '../../domain/entities/user_role.dart';

/// Current user role state provider.
///
/// In mock mode: manual StateProvider (for debug role switching).
/// In remote mode: derived from AuthNotifier state.
final currentUserRoleProvider = StateProvider<UserRole>((ref) {
  if (!EnvironmentConfig.useMockData) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      return authState.role;
    }
  }
  return UserRole.teacher; // Default to teacher
});

/// Current user ID based on role.
///
/// In mock mode: returns mock IDs.
/// In remote mode: returns actual user ID from auth state.
final currentUserIdProvider = Provider<String>((ref) {
  if (!EnvironmentConfig.useMockData) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      return authState.userId;
    }
  }
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
final selectedMockStudentProvider =
    NotifierProvider<SelectedMockStudentNotifier, MockStudentInfo>(
      SelectedMockStudentNotifier.new,
    );

class SelectedMockStudentNotifier extends Notifier<MockStudentInfo> {
  @override
  MockStudentInfo build() {
    final students = ref.read(mockStudentsProvider);
    return students.first;
  }

  void selectStudent(MockStudentInfo student) {
    state = student;
  }
}
