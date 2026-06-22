import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';

part 'student_home_session_provider.g.dart';

@riverpod
StudentHomeSessionActions studentHomeSessionActions(
  StudentHomeSessionActionsRef ref,
) {
  return StudentHomeSessionActions(ref);
}

class StudentHomeSessionActions {
  final StudentHomeSessionActionsRef _ref;

  const StudentHomeSessionActions(this._ref);

  void setStudentRole() {
    _ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
  }
}
