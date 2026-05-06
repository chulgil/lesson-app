import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, ProviderListenable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../domain/entities/user_role.dart';
import 'auth_provider.dart';

export '../../domain/entities/user_role.dart';

part 'user_role_provider.g.dart';

/// Current user role state provider.
///
/// In mock mode: notifier state (for debug role switching).
/// In remote mode: derived from AuthNotifier state.
@Riverpod(keepAlive: true)
UserRole currentUserRole(CurrentUserRoleRef ref) {
  return ref.watch(currentUserRoleControllerProvider);
}

extension CurrentUserRoleProviderNotifierCompat on Provider<UserRole> {
  ProviderListenable<CurrentUserRoleStateHandle> get notifier {
    return currentUserRoleStateHandleProvider;
  }
}

@Riverpod(keepAlive: true)
class CurrentUserRoleController extends _$CurrentUserRoleController {
  @override
  UserRole build() {
    if (!ref.watch(mockDataModeProvider)) {
      final authState = ref.watch(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        return authState.role;
      }
    }
    return UserRole.teacher; // Default to teacher
  }

  UserRole get current => state;

  void setRole(UserRole role) {
    state = role;
  }
}

@Riverpod(keepAlive: true)
CurrentUserRoleStateHandle currentUserRoleStateHandle(
  CurrentUserRoleStateHandleRef ref,
) {
  return CurrentUserRoleStateHandle(
    ref.watch(currentUserRoleControllerProvider.notifier),
  );
}

class CurrentUserRoleStateHandle {
  final CurrentUserRoleController _controller;

  const CurrentUserRoleStateHandle(this._controller);

  UserRole get state => _controller.current;

  set state(UserRole role) => _controller.setRole(role);
}

/// Current user ID based on role.
///
/// In mock mode: returns mock IDs.
/// In remote mode: returns actual user ID from auth state.
@Riverpod(keepAlive: true)
String currentUserId(CurrentUserIdRef ref) {
  if (!ref.watch(mockDataModeProvider)) {
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
}

/// Available mock students for testing
@Riverpod(keepAlive: true)
List<MockStudentInfo> mockStudents(MockStudentsRef ref) {
  return const [
    MockStudentInfo(id: 'student_1', name: '김서연'),
    MockStudentInfo(id: 'student_2', name: '이도현'),
    MockStudentInfo(id: 'student_3', name: '박지민'),
  ];
}

/// Currently selected mock student (for student role testing)
@Riverpod(keepAlive: true)
class SelectedMockStudent extends _$SelectedMockStudent {
  @override
  MockStudentInfo build() {
    final students = ref.read(mockStudentsProvider);
    return students.first;
  }

  void selectStudent(MockStudentInfo student) {
    state = student;
  }
}
