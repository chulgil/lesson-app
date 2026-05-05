import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_facade.dart';

final studentHomeCurrentStudentIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserIdProvider);
});

final studentHomeSessionActionsProvider = Provider<StudentHomeSessionActions>((
  ref,
) {
  return StudentHomeSessionActions(ref);
});

class StudentHomeSessionActions {
  final Ref _ref;

  const StudentHomeSessionActions(this._ref);

  void setStudentRole() {
    _ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
  }
}
